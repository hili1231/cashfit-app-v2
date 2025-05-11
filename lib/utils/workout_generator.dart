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
  /// Calculate the daily step target with personalization and progression.
  static Map<String, int> _calculateDailyStepTarget(
    AppUser user,
    int totalDays,
  ) {
    double weight = double.tryParse(user.weight) ?? 70.0; // kg
    double height = double.tryParse(user.height) ?? 170.0; // cm

    // Convert units if necessary
    if (user.height.contains("in")) height *= 2.54; // Convert inches to cm
    if (user.weight.contains("lbs")) weight *= 0.453592; // Convert lbs to kg

    // Base step calculation: Adjusted for weight, height, and activity level
    double activityFactor;
    switch (user.activityLevel.toLowerCase()) {
      case "sedentary":
        activityFactor = 1.0;
        break;
      case "lightly active":
        activityFactor = 1.2;
        break;
      case "moderately active":
        activityFactor = 1.4;
        break;
      case "very active":
        activityFactor = 1.6;
        break;
      default:
        activityFactor = 1.0;
    }

    // Base steps: (weight * 50 + height * 30) * activityFactor
    int baseSteps = ((weight * 50 + height * 30) * activityFactor).round();

    // Adjust for workout frequency (scale 1-7 days)
    double frequencyAdjustment = user.workoutFrequency / 7.0;
    baseSteps += (baseSteps * frequencyAdjustment * 0.2).round();

    // Adjust for intensity
    double intensityAdjustment;
    switch (user.intensity?.toLowerCase()) {
      case "low":
        intensityAdjustment = 0.05;
        break;
      case "moderate":
        intensityAdjustment = 0.1;
        break;
      case "high":
        intensityAdjustment = 0.15;
        break;
      default:
        intensityAdjustment = 0.0;
    }
    baseSteps += (baseSteps * intensityAdjustment).round();

    // Adjust for workout goal
    if (user.workoutGoal.contains("Lose Fat")) baseSteps += 1500;
    if (user.workoutGoal == "Improve Endurance") baseSteps += 2000;

    // Workout vs. Rest Days
    int workoutDaySteps = baseSteps + 1000; // Extra steps on workout days
    int restDaySteps = baseSteps;

    // Progression: Increase steps by 5% per phase
    int phaseLength = (totalDays / 3).floor();
    Map<String, int> stepTargets = {};
    for (int day = 1; day <= totalDays; day++) {
      int phase = ((day - 1) / phaseLength).floor().clamp(0, 2);
      double progressionFactor = 1.0 + (phase * 0.05); // 5% increase per phase
      stepTargets['Day $day'] =
          (day % 7 < user.workoutFrequency ? workoutDaySteps : restDaySteps) *
          progressionFactor.round();
    }

    return stepTargets;
  }

  /// Get compatible exercise categories based on the user's training style.
  static List<String> _getCompatibleCategories(String? trainingStyle) {
    switch (trainingStyle?.toLowerCase()) {
      case "gym":
        return ["gym", "dumbbells"];
      case "home":
        return ["dumbbells", "bodyweight"];
      case "bodyweight":
        return ["bodyweight"];
      case "crossfit":
        return ["gym", "bodyweight"];
      default:
        return ["gym", "dumbbells", "bodyweight"];
    }
  }

  /// Check if an exercise's difficulty is suitable for the user's experience level.
  /// Beginners can now perform intermediate exercises.
  static bool _isDifficultySuitable(
    String? exerciseDifficulty,
    String userExperienceLevel,
  ) {
    final difficulty =
        (exerciseDifficulty?.isEmpty ?? true)
            ? "beginner"
            : exerciseDifficulty!.toLowerCase();
    final userLevel =
        userExperienceLevel.isEmpty
            ? "beginner"
            : userExperienceLevel.toLowerCase();
    const difficultyOrder = ["beginner", "intermediate", "advanced"];
    int exerciseIndex = difficultyOrder.indexOf(difficulty);
    int userIndex = difficultyOrder.indexOf(userLevel);

    if (exerciseIndex == -1) {
      debugPrint('Invalid exercise difficulty: $difficulty');
      return false;
    }
    if (userIndex == -1) {
      debugPrint('Invalid user experience level: $userLevel');
      return false;
    }

    // Beginners can perform intermediate exercises
    return exerciseIndex <= userIndex + (userLevel == "beginner" ? 1 : 0);
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

  /// Determine rest duration (in seconds) based on workout goal, phase, and experience level.
  static int getRestSeconds(
    String workoutGoal,
    int phase,
    String experienceLevel,
  ) {
    int baseRest;
    switch (workoutGoal) {
      case "Build Muscle":
        baseRest = 60;
        break;
      case "Lose Fat":
        baseRest = 30;
        break;
      case "Improve Endurance":
        baseRest = 15;
        break;
      default:
        baseRest = 60;
    }

    // Adjust rest based on experience level
    double experienceAdjustment;
    switch (experienceLevel.toLowerCase()) {
      case "beginner":
        experienceAdjustment = 1.2; // Longer rest for beginners
        break;
      case "intermediate":
        experienceAdjustment = 1.0;
        break;
      case "advanced":
        experienceAdjustment = 0.8; // Shorter rest for advanced
        break;
      default:
        experienceAdjustment = 1.0;
    }

    // Decrease rest as phases progress (e.g., -5 seconds per phase)
    int adjustedRest = (baseRest * experienceAdjustment - (phase * 5)).round();
    return adjustedRest.clamp(10, 90);
  }

  /// Determine reps based on workout goal, phase, and rep scheme.
  static String getReps(String workoutGoal, int phase, int dayIndex) {
    int baseReps;
    // Vary rep scheme every 3 days (e.g., strength, hypertrophy, endurance)
    String scheme = ["strength", "hypertrophy", "endurance"][dayIndex % 3];

    switch (workoutGoal) {
      case "Build Muscle":
        if (scheme == "strength") {
          baseReps = 6 + phase; // 6, 7, 8
        } else if (scheme == "hypertrophy") {
          baseReps = 8 + phase * 2; // 8, 10, 12
        } else {
          baseReps = 12 + phase * 2; // 12, 14, 16
        }
        break;
      case "Lose Fat":
        if (scheme == "strength") {
          baseReps = 8 + phase; // 8, 9, 10
        } else if (scheme == "hypertrophy") {
          baseReps = 10 + phase * 2; // 10, 12, 14
        } else {
          baseReps = 15 + phase * 2; // 15, 17, 19
        }
        break;
      case "Improve Endurance":
        if (scheme == "strength") {
          baseReps = 10 + phase; // 10, 11, 12
        } else if (scheme == "hypertrophy") {
          baseReps = 12 + phase * 2; // 12, 14, 16
        } else {
          baseReps = 20 + phase * 2; // 20, 22, 24
        }
        break;
      default:
        baseReps = 8 + phase * 2;
        break;
    }
    return baseReps.toString();
  }

  /// Determine sets based on workout goal, phase, and experience level.
  static int getSets(String workoutGoal, int phase, String experienceLevel) {
    int baseSets;
    switch (workoutGoal) {
      case "Build Muscle":
        baseSets = 3 + phase; // 3, 4, 5
        break;
      case "Lose Fat":
        baseSets = 3 + phase; // 3, 4, 5
        break;
      case "Improve Endurance":
        baseSets = 2 + phase; // 2, 3, 4
        break;
      default:
        baseSets = 3 + phase;
        break;
    }

    // Adjust sets based on experience level
    switch (experienceLevel.toLowerCase()) {
      case "beginner":
        baseSets = baseSets - 1; // Fewer sets for beginners
        break;
      case "advanced":
        baseSets = baseSets + 1; // More sets for advanced
        break;
      default:
        break;
    }

    return baseSets.clamp(2, 6);
  }

  /// Select exercises targeting specific muscle groups with variety and balance.
  /// Ensure exercises are meaningful and tailored to user goals.
  static List<Exercise> selectExercises(
    List<Exercise> available,
    List<String> targetMuscleGroups,
    int numExercises,
    List<String> usedExerciseIds,
    Map<String, int> muscleGroupUsage,
  ) {
    List<Exercise> selected = [];
    Set<String> covered = {};
    List<Exercise> candidates =
        available.where((e) => !usedExerciseIds.contains(e.id)).toList();

    if (candidates.isEmpty) {
      // Reset used exercises if we've cycled through all options
      candidates = List.from(available);
      usedExerciseIds.clear();
    }

    // Prioritize exercises that cover underused muscle groups
    List<Exercise> prioritizedCandidates = [];
    for (var exercise in candidates) {
      // Calculate a score based on how underused the muscle groups are
      exercise.muscleGroups
          .where((mg) => targetMuscleGroups.contains(mg))
          .fold(0, (currentSum, mg) => currentSum + (muscleGroupUsage[mg] ?? 0));
      prioritizedCandidates.add(exercise);
    }

    // Sort candidates by score (lower usage = higher priority)
    prioritizedCandidates.sort((a, b) {
      int scoreA = a.muscleGroups
          .where((mg) => targetMuscleGroups.contains(mg))
          .fold(0, (currentSum, mg) => currentSum + (muscleGroupUsage[mg] ?? 0));
      int scoreB = b.muscleGroups
          .where((mg) => targetMuscleGroups.contains(mg))
          .fold(0, (currentSum, mg) => currentSum + (muscleGroupUsage[mg] ?? 0));
      return scoreA.compareTo(scoreB);
    });

    // First pass: Prioritize exercises covering new or underused muscle groups
    while (selected.length < numExercises && prioritizedCandidates.isNotEmpty) {
      Exercise bestExercise = prioritizedCandidates.first;
      selected.add(bestExercise);
      covered.addAll(
        bestExercise.muscleGroups.where(targetMuscleGroups.contains),
      );
      // Update muscle group usage
      for (var mg in bestExercise.muscleGroups) {
        if (targetMuscleGroups.contains(mg)) {
          muscleGroupUsage[mg] = (muscleGroupUsage[mg] ?? 0) + 1;
        }
      }
      prioritizedCandidates.remove(bestExercise);
      usedExerciseIds.add(bestExercise.id);
    }

    // Second pass: Fill remaining slots with isolation exercises
    candidates =
        available.where((e) => !usedExerciseIds.contains(e.id)).toList();
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
          usedExerciseIds.add(exercise.id);
          for (var mg in exercise.muscleGroups) {
            if (targetMuscleGroups.contains(mg)) {
              muscleGroupUsage[mg] = (muscleGroupUsage[mg] ?? 0) + 1;
            }
          }
        }
      }
    }

    return selected;
  }

  static Future<WorkoutProgram> generateWorkoutProgram({
    required BuildContext context,
    required int totalDays,
    required int workoutFrequency,
    required List<String> availableDays,
    required List<String> preferredWorkoutTimes,
    Function(double)? onProgress,
    required AppUser user,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Log user data for debugging
      debugPrint(
        'User data: trainingStyle=${user.trainingStyle}, experienceLevel=${user.experienceLevel}, workoutFocus=${user.workoutFocus}, injuryHistory=${user.injuryHistory}',
      );

      // Validate user data
      if (user.workoutDuration <= 0 ||
          workoutFrequency <= 0 ||
          totalDays <= 0) {
        throw Exception(
          "Invalid input: workout duration, frequency, and total days must be positive.",
        );
      }

      // Calculate daily step targets and update user data
      Map<String, int> dailyStepTargets = _calculateDailyStepTarget(
        user,
        totalDays,
      );
      List<Map<String, dynamic>> stepTargetHistory = [];
      for (int day = 1; day <= totalDays; day++) {
        DateTime date = DateTime.now().add(Duration(days: day - 1));
        String formattedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        stepTargetHistory.add({
          'date': formattedDate,
          'achieved': false,
          'target': dailyStepTargets['Day $day'],
        });
      }

      await userProvider.updateUserFields({
        'dailyStepTarget': dailyStepTargets['Day 1'],
        'stepTargetHistory': stepTargetHistory,
      });

      // Adjust training days based on workoutFrequency
      List<String> trainingDays = availableDays.isNotEmpty
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
      if (user.workoutFocus.isNotEmpty) {
        debugPrint('Filtering by workout focus: ${user.workoutFocus}');
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
      debugPrint('Total exercises fetched: ${allExercises.length}');
      if (allExercises.isNotEmpty) {
        debugPrint('Sample exercise: ${allExercises.first.toMap()}');
      }

      // Filter exercises based on category, difficulty, and injury risks
      final compatibleCategories = _getCompatibleCategories(user.trainingStyle);
      debugPrint('Compatible categories: $compatibleCategories');
      List<Exercise> availableExercises =
          allExercises.where((exercise) {
            bool categoryMatch = compatibleCategories.any(
              (cat) =>
                  (exercise.category).toLowerCase() ==
                  cat.toLowerCase(),
            );
            bool difficultyMatch = _isDifficultySuitable(
              exercise.difficulty,
              user.experienceLevel,
            );
            bool injuryMatch =
                user.injuryHistory.isEmpty ||
                !exercise.injuryRisks.any(
                  (risk) => user.injuryHistory.contains(risk),
                );
            debugPrint(
              'Exercise: ${exercise.name}, Category Match: $categoryMatch, Difficulty Match: $difficultyMatch, Injury Match: $injuryMatch',
            );
            return categoryMatch && difficultyMatch && injuryMatch;
          }).toList();

      if (availableExercises.isEmpty) {
        debugPrint(
          'User criteria: trainingStyle=${user.trainingStyle}, experienceLevel=${user.experienceLevel}, workoutFocus=${user.workoutFocus}, injuryHistory=${user.injuryHistory}',
        );
        throw Exception("No exercises available for the given criteria.");
      }

      // Calculate the number of exercises based on workoutDuration
      int numExercises = (user.workoutDuration / 10).round(); // 1 exercise per 10 minutes
      if (numExercises < 1) numExercises = 1; // Ensure at least 1 exercise per session

      // Define workout splits
      List<String> splitTypes = ['Push', 'Pull', 'Legs'];
      Map<String, List<String>> splitMuscleGroups = {
        'Push': ['Chest', 'Shoulders', 'Triceps'],
        'Pull': ['Back', 'Biceps'],
        'Legs': ['Legs', 'Glutes', 'Calves'],
        'Full Body': ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'],
      };

      // Track used exercises and muscle group usage for balance
      List<String> usedExerciseIds = [];
      Map<String, int> muscleGroupUsage = {
        'Chest': 0,
        'Shoulders': 0,
        'Triceps': 0,
        'Back': 0,
        'Biceps': 0,
        'Legs': 0,
        'Glutes': 0,
        'Calves': 0,
        'Core': 0,
        'Arms': 0,
      };

      // Generate workout program
      Map<String, List<Map<String, dynamic>>> programDays = {};
      int currentDay = 1;
      int phaseLength = (totalDays / 3).floor();
      int splitIndex = 0;
      int trainingDayCount = 0;

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
          trainingDayCount++;
          int phase = (currentDay / phaseLength).floor().clamp(0, 2);
          int sets = getSets(user.workoutGoal, phase, user.experienceLevel);
          String reps = getReps(user.workoutGoal, phase, trainingDayCount);
          int restSeconds = getRestSeconds(
            user.workoutGoal,
            phase,
            user.experienceLevel,
          );

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

          // Select exercises for the day with variety and balance
          List<Exercise> selectedExercises = selectExercises(
            availableExercises,
            targetMuscleGroups,
            numExercises,
            usedExerciseIds,
            muscleGroupUsage,
          );

          for (int i = 0; i < selectedExercises.length; i++) {
            var exercise = selectedExercises[i];
            Map<String, dynamic> config = {
              'exerciseId': exercise.id,
              'sets': sets,
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
                  'sets': sets,
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
        preferredWorkoutTimes: preferredWorkoutTimes,
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
