import 'package:cashfit/models/active_workout_program.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../providers/user_provider.dart';
import 'dart:developer' as developer;

class WorkoutGenerator {
  /// Calculate the daily step target based on user activity level and goals.
  static int _calculateDailyStepTarget(AppUser user) {
    int baseSteps;
    switch (user.activityLevel) {
      case "Sedentary":
        baseSteps = 5000;
        break;
      case "Lightly Active":
        baseSteps = 7500;
        break;
      case "Moderately Active":
        baseSteps = 10000;
        break;
      case "Very Active":
        baseSteps = 12500;
        break;
      default:
        baseSteps = 5000;
    }

    if (user.workoutGoal.contains("Lose Fat")) baseSteps += 2000;
    if (user.workoutGoal == "Improve Endurance") baseSteps += 3000;
    if (user.intensity == "High") {
      baseSteps += 1000;
    } else if (user.intensity == "Moderate") {
      baseSteps += 500;
    }

    return baseSteps;
  }

  /// Get compatible exercise categories based on the user's training style.
  static List<String> _getCompatibleCategories(String? trainingStyle) {
    switch (trainingStyle) {
      case "Gym":
        return ["Gym", "dumbbells"];
      case "Home":
        return ["dumbbells", "Bodyweight"];
      case "Bodyweight":
        return ["Bodyweight"];
      case "CrossFit":
        return ["Gym", "Bodyweight"];
      default:
        return ["Gym", "dumbbells", "Bodyweight"];
    }
  }

  /// Check if an exercise's difficulty is suitable for the user's experience level.
  static bool _isDifficultySuitable(
    String? exerciseDifficulty,
    String userExperienceLevel,
  ) {
    final difficulty =
        exerciseDifficulty?.isEmpty ?? true ? "Beginner" : exerciseDifficulty!;
    const difficultyOrder = ["Beginner", "Intermediate", "Advanced"];
    return difficultyOrder.indexOf(difficulty) <=
        difficultyOrder.indexOf(userExperienceLevel);
  }

  /// Create a placeholder exercise in Firestore if a special exercise is missing.
  static Future<String> _createPlaceholderExercise(String intendedName) async {
    final placeholderExercise = Exercise(
      id: const Uuid().v4(),
      name: intendedName,
      instructions: 'Placeholder exercise - please update with proper details.',
      muscleGroups: ['Full Body'],
      injuryRisks: [],
      category: 'Bodyweight',
      isTimed: false,
      difficulty: 'Beginner',
    );
    await FirebaseFirestore.instance
        .collection('exercises')
        .doc(placeholderExercise.id)
        .set(placeholderExercise.toMap());
    developer.log(
      "Created placeholder exercise: ${placeholderExercise.id} for $intendedName",
    );
    return placeholderExercise.id;
  }

  /// Fetch or create special exercises (rest, warm-up, cool-down) from Firestore.
  static Future<Map<String, String>> _initializeSpecialExercises() async {
    try {
      final specialExercisesQuery =
          await FirebaseFirestore.instance
              .collection('exercises')
              .where(
                'name',
                whereIn: [
                  'rest_sets_0_reps_0',
                  'Dynamic Stretching',
                  'Static Stretching',
                ],
              )
              .get();

      final specialExercises =
          specialExercisesQuery.docs
              .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
              .toList();

      String restExerciseId =
          specialExercises.any((e) => e.name == 'rest_sets_0_reps_0')
              ? specialExercises
                  .firstWhere((e) => e.name == 'rest_sets_0_reps_0')
                  .id
              : await _createPlaceholderExercise('rest_sets_0_reps_0');

      String warmUpExerciseId =
          specialExercises.any((e) => e.name == 'Dynamic Stretching')
              ? specialExercises
                  .firstWhere((e) => e.name == 'Dynamic Stretching')
                  .id
              : await _createPlaceholderExercise('Dynamic Stretching');

      String coolDownExerciseId =
          specialExercises.any((e) => e.name == 'Static Stretching')
              ? specialExercises
                  .firstWhere((e) => e.name == 'Static Stretching')
                  .id
              : await _createPlaceholderExercise('Static Stretching');

      return {
        'rest': restExerciseId,
        'warmUp': warmUpExerciseId,
        'coolDown': coolDownExerciseId,
      };
    } catch (e) {
      throw Exception("Failed to initialize special exercises: $e");
    }
  }

  /// Determine the number of exercises based on workout duration.
  static int getNumExercises(double duration) {
    if (duration <= 30) {
      return 6;
    } else if (duration <= 45) {
      return 9;
    } else if (duration <= 60) {
      return 12;
    } else {
      return (duration / 5).floor(); // Approximately 1 exercise per 5 minutes
    }
  }

  /// Determine rest duration (in seconds) based on workout goal.
  static int getRestSeconds(String workoutGoal) {
    switch (workoutGoal) {
      case "Build Muscle":
        return 60;
      case "Lose Fat":
        return 30;
      case "Improve Endurance":
        return 15;
      default:
        return 60;
    }
  }

  /// Determine reps based on workout goal and phase.
  static String getReps(String workoutGoal, int phase) {
    int baseReps;
    switch (workoutGoal) {
      case "Build Muscle":
        baseReps = 8 + phase * 2; // 8, 10, 12
        break;
      case "Lose Fat":
        baseReps = 12 + phase * 2; // 12, 14, 16
        break;
      case "Improve Endurance":
        baseReps = 15 + phase * 2; // 15, 17, 19
        break;
      default:
        baseReps = 8 + phase * 2;
        break;
    }
    return baseReps.toString();
  }

  /// Select exercises targeting specific muscle groups.
  static List<Exercise> selectExercises(
    List<Exercise> available,
    List<String> targetMuscleGroups,
    int numExercises,
  ) {
    List<Exercise> selected = [];
    Set<String> covered = {};
    List<Exercise> candidates = List.from(available)..shuffle();

    // First pass: Prioritize exercises covering new muscle groups
    while (selected.length < numExercises && candidates.isNotEmpty) {
      Exercise? bestExercise;
      int maxNewCovered = -1;
      for (var exercise in candidates) {
        var newCovered =
            exercise.muscleGroups
                .where(
                  (mg) =>
                      targetMuscleGroups.contains(mg) && !covered.contains(mg),
                )
                .toSet();
        if (newCovered.length > maxNewCovered) {
          maxNewCovered = newCovered.length;
          bestExercise = exercise;
        }
      }
      if (bestExercise != null && maxNewCovered > 0) {
        selected.add(bestExercise);
        covered.addAll(
          bestExercise.muscleGroups.where(targetMuscleGroups.contains),
        );
        candidates.remove(bestExercise);
      } else {
        break;
      }
    }

    // Second pass: Fill remaining slots with isolation exercises
    while (selected.length < numExercises && candidates.isNotEmpty) {
      for (var mg in targetMuscleGroups) {
        if (selected.length >= numExercises) break;
        var isolationExercises =
            candidates
                .where(
                  (e) =>
                      e.muscleGroups.contains(mg) && e.muscleGroups.length == 1,
                )
                .toList();
        if (isolationExercises.isNotEmpty) {
          var exercise = isolationExercises.first;
          selected.add(exercise);
          candidates.remove(exercise);
        }
      }
    }

    return selected;
  }

  /// Generate a personalized workout program for the user.
  static Future<WorkoutProgram> generateWorkoutProgram({
    required BuildContext context,
    required int totalDays,
    required int workoutFrequency,
    required List<String> availableDays,
    required List<String> preferredWorkoutTimes,
    Function(double)? onProgress, required AppUser user,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Validate user data
      if (user.workoutDuration <= 0 ||
          workoutFrequency <= 0 ||
          totalDays <= 0) {
        throw Exception(
          "Invalid input: workout duration, frequency, and total days must be positive.",
        );
      }

      // Calculate daily step target and update user data
      int dailyStepTarget = _calculateDailyStepTarget(user);
      List<Map<String, dynamic>> stepTargetHistory = [];
      for (int i = 1; i <= totalDays; i++) {
        DateTime date = DateTime.now().add(Duration(days: i - 1));
        String formattedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        stepTargetHistory.add({'date': formattedDate, 'achieved': false});
      }

      await userProvider.updateUserFields({
        'dailyStepTarget': dailyStepTarget,
        'stepTargetHistory': stepTargetHistory,
      });

      // Determine training days
      List<String> trainingDays =
          availableDays.isNotEmpty
              ? availableDays.take(workoutFrequency).toList()
              : [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
              ].take(workoutFrequency).toList();

      // Initialize special exercises (rest, warm-up, cool-down)
      final specialExercises = await _initializeSpecialExercises();
      final restExerciseId = specialExercises['rest']!;
      final warmUpExerciseId = specialExercises['warmUp']!;
      final coolDownExerciseId = specialExercises['coolDown']!;

      // Fetch available exercises from Firestore
      Query<Map<String, dynamic>> exerciseQuery = FirebaseFirestore.instance
          .collection('exercises');
      final compatibleCategories =
          _getCompatibleCategories(user.trainingStyle)
              .where((cat) => !['Rest', 'Warm-Up', 'Cool-Down'].contains(cat))
              .toList();
      if (compatibleCategories.isNotEmpty) {
        exerciseQuery = exerciseQuery.where(
          'category',
          whereIn: compatibleCategories,
        );
      }
      if (user.workoutFocus.isNotEmpty) {
        exerciseQuery = exerciseQuery.where(
          'muscleGroups',
          arrayContainsAny: user.workoutFocus,
        );
      }
      final exerciseSnapshot = await exerciseQuery.get();
      List<Exercise> allExercises =
          exerciseSnapshot.docs
              .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
              .toList();

      // Filter exercises based on difficulty and injury risks
      List<Exercise> availableExercises =
          allExercises.where((exercise) {
            bool difficultyMatch = _isDifficultySuitable(
              exercise.difficulty,
              user.experienceLevel,
            );
            bool injuryMatch =
                user.injuryHistory.isEmpty ||
                !exercise.injuryRisks.any(
                  (risk) => user.injuryHistory.contains(risk),
                );
            return difficultyMatch && injuryMatch;
          }).toList();

      if (availableExercises.isEmpty) {
        throw Exception("No exercises available for the given criteria.");
      }

      // Calculate workout parameters
      int numExercises = getNumExercises(user.workoutDuration);
      int restSeconds = getRestSeconds(user.workoutGoal);

      // Define workout splits
      List<String> splitTypes = ['Push', 'Pull', 'Legs'];
      Map<String, List<String>> splitMuscleGroups = {
        'Push': ['Chest', 'Shoulders', 'Triceps'],
        'Pull': ['Back', 'Biceps'],
        'Legs': ['Legs', 'Glutes', 'Calves'],
        'Full Body': ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'],
      };

      // Generate workout program
      Map<String, List<Map<String, dynamic>>> programDays = {};
      int currentDay = 1;
      int phaseLength = (totalDays / 3).floor();
      int splitIndex = 0;

      while (currentDay <= totalDays) {
        DateTime date = DateTime.now().add(Duration(days: currentDay - 1));
        String dayOfWeek =
            [
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday",
              "Saturday",
              "Sunday",
            ][date.weekday - 1];
        String dayKey = 'Day $currentDay';
        List<Map<String, dynamic>> dailyExercises = [];

        if (trainingDays.contains(dayOfWeek)) {
          int phase = (currentDay / phaseLength).floor().clamp(0, 2);
          int baseSets = 3 + phase;
          String reps = getReps(user.workoutGoal, phase);

          String splitType;
          List<String> targetMuscleGroups;
          if (user.experienceLevel == "Beginner" && phase == 0) {
            splitType = 'Full Body';
            targetMuscleGroups = splitMuscleGroups['Full Body']!;
          } else {
            splitType = splitTypes[splitIndex % splitTypes.length];
            targetMuscleGroups = splitMuscleGroups[splitType]!;
            splitIndex++;
          }

          // Add warm-up
          dailyExercises.add({
            'exerciseId': warmUpExerciseId,
            'sets': 1,
            'reps': '5-10',
            'restSeconds': 0,
          });

          // Select exercises for the day
          List<Exercise> selectedExercises = selectExercises(
            availableExercises,
            targetMuscleGroups,
            numExercises,
          );

          for (int i = 0; i < selectedExercises.length; i++) {
            var exercise = selectedExercises[i];
            Map<String, dynamic> config = {
              'exerciseId': exercise.id,
              'sets': baseSets,
              'reps': reps,
              'restSeconds': restSeconds,
            };

            // Add superset logic for shorter workouts
            if (numExercises <= 6 &&
                i % 2 == 0 &&
                i + 1 < selectedExercises.length) {
              var nextExercise = selectedExercises[i + 1];
              if (exercise.muscleGroups
                  .toSet()
                  .intersection(nextExercise.muscleGroups.toSet())
                  .isEmpty) {
                config['supersetWith'] = nextExercise.id;
                Map<String, dynamic> nextConfig = {
                  'exerciseId': nextExercise.id,
                  'sets': baseSets,
                  'reps': reps,
                  'restSeconds': restSeconds,
                  'supersetWith': exercise.id,
                };
                dailyExercises.add(config);
                dailyExercises.add(nextConfig);
                i++;
                continue;
              }
            }
            dailyExercises.add(config);
          }

          // Add cool-down
          dailyExercises.add({
            'exerciseId': coolDownExerciseId,
            'sets': 1,
            'reps': '5-10',
            'restSeconds': 0,
          });
        } else {
          // Rest day
          dailyExercises.add({
            'exerciseId': restExerciseId,
            'sets': 0,
            'reps': '0',
            'restSeconds': 0,
          });
        }

        programDays[dayKey] = dailyExercises;
        currentDay++;
        if (onProgress != null) onProgress(currentDay / totalDays);
      }

      // Create and save the WorkoutProgram
      final workoutProgram = WorkoutProgram(
        id: const Uuid().v4(),
        title: "${user.experienceLevel} ${user.workoutGoal} Program",
        image: '',
        days: programDays,
        level: user.experienceLevel,
        description: "A $totalDays-day program tailored for your goals.",
        userId: user.id,
        preferredWorkoutTimes: preferredWorkoutTimes, // Store for scheduling
      );

      await FirebaseFirestore.instance
          .collection('workoutPrograms')
          .doc(workoutProgram.id)
          .set(workoutProgram.toMap());

      // Update user's active workout programs via UserProvider
      ActiveWorkoutProgram newActiveWorkoutProgram = ActiveWorkoutProgram(
        workoutProgramId: workoutProgram.id,
        startDate: DateTime.now(),
        currentDay: 1,
        isCompleted: false,
        completedDays: const [],
      );

      List<ActiveWorkoutProgram> updatedWorkoutPrograms = [
        ...user.activeWorkoutPrograms,
        newActiveWorkoutProgram,
      ];
      await userProvider.updateUserFields({
        'activeWorkoutPrograms':
            updatedWorkoutPrograms.map((program) => program.toMap()).toList(),
      });

      return workoutProgram;
    } catch (e) {
      throw Exception("Failed to generate workout program: $e");
    }
  }
}
