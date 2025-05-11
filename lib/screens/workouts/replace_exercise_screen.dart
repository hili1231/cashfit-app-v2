import 'package:cashfit/models/app_user.dart' show AppUser;
import 'package:cashfit/screens/nav_screen.dart';
import 'package:cashfit/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/exercise.dart';
import '../../models/workout_program.dart';
import '../../providers/user_provider.dart';
import 'workout_detail_screen.dart';

class ReplaceExerciseScreen extends StatefulWidget {
  final String exerciseId;
  final int? dayNumber;
  final WorkoutProgram workout;

  const ReplaceExerciseScreen({
    super.key,
    required this.exerciseId,
    required this.dayNumber,
    required this.workout,
  });

  static List<Exercise>? _cachedAllExercises;
  static final Map<String, List<Exercise>> _cachedRecommendedExercises = {};

  @override
  State<ReplaceExerciseScreen> createState() => _ReplaceExerciseScreenState();
}

class _ReplaceExerciseScreenState extends State<ReplaceExerciseScreen> {
  List<Exercise> _recommendedExercises = [];
  List<Exercise> _allExercises = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isBrowsingAll = false;

  @override
  void initState() {
    super.initState();
    if (ReplaceExerciseScreen._cachedAllExercises != null &&
        ReplaceExerciseScreen._cachedRecommendedExercises.containsKey(
          widget.exerciseId,
        )) {
      _allExercises = ReplaceExerciseScreen._cachedAllExercises!;
      _recommendedExercises =
          ReplaceExerciseScreen._cachedRecommendedExercises[widget.exerciseId]!;
      _isLoading = false;
    } else {
      _listenToExercises();
    }
  }

  void _listenToExercises() {
    setState(() => _isLoading = true);
    try {
      FirebaseFirestore.instance.collection('exercises').snapshots().listen(
        (snapshot) {
          final allExercises = snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
              .toList();

          final currentExercise = allExercises.firstWhere(
            (exercise) => exercise.id == widget.exerciseId,
            orElse: () => Exercise(
              id: '',
              name: 'Unknown Exercise',
              category: '',
              muscleGroups: [],
              difficulty: '',
              specificEquipment: '',
              injuryRisks: [],
              instructions: '',
            ),
          );

          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final recommended = _rankExercises(
              allExercises,
              currentExercise,
              userProvider.currentUser,
            );

            setState(() {
              _allExercises = allExercises;
              _recommendedExercises = recommended.take(5).toList();
              _isLoading = false;
            });
            ReplaceExerciseScreen._cachedAllExercises = allExercises;
            ReplaceExerciseScreen._cachedRecommendedExercises[widget.exerciseId] =
                recommended.take(5).toList();
          }
        },
        onError: (error) {
          debugPrint('Error listening to exercises: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load exercises: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.onError),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Listen to exercises error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load exercises: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Exercise> _rankExercises(
    List<Exercise> exercises,
    Exercise current,
    AppUser? user,
  ) {
    final scoredExercises = exercises.map((exercise) {
      double score = 0.0;

      if (exercise.category == current.category) score += 0.4;
      final muscleOverlap = exercise.muscleGroups
          .toSet()
          .intersection(current.muscleGroups.toSet())
          .length /
          exercise.muscleGroups
              .toSet()
              .union(current.muscleGroups.toSet())
              .length;
      score += 0.3 * muscleOverlap;
      if (exercise.difficulty == current.difficulty ||
          (user != null && exercise.difficulty == user.experienceLevel)) {
        score += 0.2;
      }
      if (exercise.specificEquipment == current.specificEquipment) {
        score += 0.1;
      }

      if (user != null &&
          exercise.injuryRisks.any((risk) => user.medicalConditions.contains(risk))) {
        score = 0.0;
      }

      return {'exercise': exercise, 'score': score};
    }).toList();

    scoredExercises.sort((a, b) {
      final scoreA = a['score'] as double? ?? 0.0;
      final scoreB = b['score'] as double? ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return scoredExercises
        .where((item) => (item['score'] as double? ?? 0.0) > 0)
        .map((item) => item['exercise'] as Exercise)
        .toList();
  }

  Future<Map<String, dynamic>> _replaceExercise(
    String? newExerciseId,
    bool applyToAllDays,
  ) async {
    if (_isLoading) {
      debugPrint('ReplaceExercise: Skipped due to ongoing operation');
      return {'success': false, 'programId': widget.workout.id};
    }

    setState(() => _isLoading = true);
    try {
      debugPrint(
        'Starting replaceExercise with newExerciseId: $newExerciseId, original exerciseId: ${widget.exerciseId}, applyToAllDays: $applyToAllDays',
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final firebaseAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (!userProvider.isLoggedIn ||
          userProvider.firebaseUser == null ||
          firebaseAuthUser == null) {
        debugPrint(
          'ReplaceExercise: Authentication invalid, isLoggedIn: ${userProvider.isLoggedIn}, '
          'userProvider.firebaseUser: ${userProvider.firebaseUser?.uid}, '
          'FirebaseAuth.currentUser: ${firebaseAuthUser?.uid}',
        );
        throw Exception('Please log in to make changes');
      }
      final currentUid = firebaseAuthUser.uid;
      debugPrint('Current user UID: $currentUid');

      // Validate input exercise IDs
      if (widget.exerciseId == '1' || widget.exerciseId.isEmpty) {
        throw Exception('Invalid original exercise ID: ${widget.exerciseId}');
      }
      if (newExerciseId != null &&
          (newExerciseId == '1' || newExerciseId.isEmpty)) {
        throw Exception('Invalid new exercise ID: $newExerciseId');
      }

      // Validate newExerciseId exists in exercises collection (if not null)
      if (newExerciseId != null) {
        debugPrint('Validating new exercise ID: $newExerciseId');
        final newExerciseDoc =
            await FirebaseFirestore.instance
                .collection('exercises')
                .doc(newExerciseId)
                .get();
        if (!newExerciseDoc.exists) {
          throw Exception('New exercise not found: $newExerciseId');
        }
      }

      // Validate removal if newExerciseId is null
      if (newExerciseId == null) {
        final confirmed = await _confirmRemoval();
        if (!confirmed || !mounted) {
          debugPrint('ReplaceExercise: Removal cancelled or widget unmounted');
          return {'success': false, 'programId': widget.workout.id};
        }
      }

      // Fetch and validate workout program
      debugPrint('Validating workout program ID: ${widget.workout.id}');
      final programRef = FirebaseFirestore.instance
          .collection('workoutPrograms')
          .doc(widget.workout.id);
      final programDoc = await programRef.get();
      if (!programDoc.exists) {
        throw Exception('Workout program not found: ${widget.workout.id}');
      }

      final programData = programDoc.data()!;
      debugPrint(
        'Program data fetched: ${programData.keys}, userId: ${programData['userId']}, raw: ${programData['userId'].runtimeType}',
      );
      final rawDays = programData['days'] ?? {};
      if (rawDays is! Map) {
        throw Exception(
          'Invalid days format: Expected Map, got ${rawDays.runtimeType}',
        );
      }

      // Check permissions before write
      final programUserId = programData['userId'] as String?;
      debugPrint(
        'Checking permissions: programUserId=$programUserId, currentUid=$currentUid',
      );
      if (programUserId != null && programUserId != currentUid) {
        debugPrint(
          'Permission denied: program userId ($programUserId) does not match current user ($currentUid)',
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'You do not have permission to modify this program',
        );
      }

      // Safely convert days to expected type
      final days = <String, List<Map<String, dynamic>>>{};
      rawDays.forEach((key, value) {
        if (key is String && value is List) {
          final validExercises = <Map<String, dynamic>>[];
          for (var exercise in value) {
            if (exercise is Map) {
              validExercises.add(Map<String, dynamic>.from(exercise));
            } else {
              debugPrint('Skipping invalid exercise entry in $key: $exercise');
            }
          }
          if (validExercises.isNotEmpty) {
            days[key] = validExercises;
          } else {
            debugPrint('Skipping empty or invalid exercises for day: $key');
          }
        } else {
          debugPrint('Skipping invalid day entry: key=$key, value=$value');
        }
      });

      if (days.isEmpty) {
        throw Exception('No valid days defined in workout program');
      }

      debugPrint('Processed days: ${days.keys}');

      // Update days based on applyToAllDays
      debugPrint(
        'Processing days for replacement, dayNumber: ${widget.dayNumber}, applyToAllDays: $applyToAllDays',
      );
      if (applyToAllDays || widget.dayNumber == null) {
        days.forEach((day, exercises) {
          debugPrint('Updating day $day with ${exercises.length} exercises');
          days[day] =
              exercises
                  .map((exercise) {
                    if (exercise['exerciseId'] == widget.exerciseId) {
                      return newExerciseId == null
                          ? null
                          : {...exercise, 'exerciseId': newExerciseId};
                    }
                    return exercise;
                  })
                  .where((exercise) => exercise != null)
                  .cast<Map<String, dynamic>>()
                  .toList();
          debugPrint('Updated day $day to ${days[day]?.length} exercises');
        });
      } else {
        final dayKey = 'Day ${widget.dayNumber}';
        if (!days.containsKey(dayKey)) {
          throw Exception('Invalid day number: $dayKey not found');
        }
        final dayExercises = days[dayKey] ?? [];
        if (dayExercises.isEmpty) {
          throw Exception('No exercises found for $dayKey');
        }
        debugPrint(
          'Updating day $dayKey with ${dayExercises.length} exercises',
        );
        days[dayKey] =
            dayExercises
                .map((exercise) {
                  if (exercise['exerciseId'] == widget.exerciseId) {
                    return newExerciseId == null
                        ? null
                        : {...exercise, 'exerciseId': newExerciseId};
                  }
                  return exercise;
                })
                .where((exercise) => exercise != null)
                .cast<Map<String, dynamic>>()
                .toList();
        debugPrint('Updated day $dayKey to ${days[dayKey]?.length} exercises');
      }

      // Write updated program with fallback
      debugPrint('Writing updated program to Firestore');
      String finalProgramId = widget.workout.id;
      bool writeSuccess = false;
      try {
        if (programUserId == null) {
          debugPrint('Attempting to update existing program: $finalProgramId');
          await programRef.update({'days': days});
          debugPrint('Updated existing program: $finalProgramId');
          writeSuccess = true;
        } else {
          debugPrint('Updating owned program: $finalProgramId');
          await programRef.update({'days': days});
          debugPrint('Updated existing program: $finalProgramId');
          writeSuccess = true;
        }
      } catch (e) {
        debugPrint('Initial Firestore write error: $e');
        if (e is FirebaseException &&
            e.code == 'permission-denied' &&
            programUserId == null) {
          debugPrint(
            'Falling back to create new program due to permissions error',
          );
          final newProgramRef =
              FirebaseFirestore.instance.collection('workoutPrograms').doc();
          try {
            await newProgramRef.set({
              ...programData,
              'userId': currentUid,
              'days': days,
            });
            finalProgramId = newProgramRef.id;
            debugPrint('Created new program as fallback: $finalProgramId');
            writeSuccess = true;
          } catch (fallbackError) {
            debugPrint('Fallback Firestore write error: $fallbackError');
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Failed to create new program: $fallbackError',
            );
          }
        } else {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Failed to write program: $e',
          );
        }
      }

      // Check if the program is already active and update accordingly
      if (writeSuccess) {
        debugPrint('Checking if program is active: $finalProgramId');
        final activeProgramRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('activeWorkoutPrograms')
            .doc(finalProgramId);
        final activeDoc = await activeProgramRef.get();

        if (!activeDoc.exists) {
          // If not active, set as active
          debugPrint(
            'Program is not active, setting as active: $finalProgramId',
          );
          try {
            await activeProgramRef.set({
              'workoutProgramId': finalProgramId,
              'startDate': DateTime.now().toIso8601String(),
              'currentDay': 1,
            });
            debugPrint('Set active program: $finalProgramId');
          } catch (e) {
            debugPrint('Active program write error: $e');
            // Non-critical error, log but don't fail
          }
        } else {
          // If already active, update the active workout's days to reflect the replacement
          debugPrint(
            'Program is already active, updating active workout: $finalProgramId',
          );
          final activeData = activeDoc.data();
          if (activeData != null) {
            try {
              await activeProgramRef.update({'days': days});
              debugPrint(
                'Updated active program with new days: $finalProgramId',
              );
            } catch (e) {
              debugPrint('Error updating active program days: $e');
              // Non-critical error, log but don't fail
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newExerciseId == null
                  ? 'Exercise removed successfully'
                  : 'Exercise replaced successfully',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Navigate to WorkoutDetailScreen with updated program
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          // Clear the detail stack to prevent ReplaceExerciseScreen from reappearing on back
          navState.replaceWithScreen(
            WorkoutDetailScreen(
              workout: WorkoutProgram(
                id: finalProgramId,
                title: widget.workout.title,
                image: widget.workout.image,
                days: days,
                level: widget.workout.level,
                description: widget.workout.description,
                userId: userProvider.firebaseUser?.uid,
                preferredWorkoutTimes: widget.workout.preferredWorkoutTimes,
              ),
            ),
          );

          debugPrint('Navigated to WorkoutDetailScreen after replace/remove');
        }
      }

      return {'success': true, 'programId': finalProgramId, 'days': days};
    } catch (e) {
      debugPrint('ReplaceExercise error: $e');
      String errorMessage;
      if (e is FirebaseException && e.code == 'permission-denied') {
        errorMessage =
            'Unable to save changes due to permissions. A new program has been created for you, or please try logging in again.';
      } else {
        errorMessage = 'Failed to update workout program: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return {'success': false, 'programId': widget.workout.id};
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _confirmRemoval() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Remove Exercise?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Are you sure you want to remove this exercise?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                style: Theme.of(context).filledButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error,
                  ),
                ),
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
    );
    return confirmed;
  }

  Future<Map<String, dynamic>> _confirmApplyToAll() async {
    bool applyToAll = false;
    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Replace Exercise Scope',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dayNumber == null
                            ? 'Do you want to replace this exercise across all days?'
                            : 'Do you want to replace this exercise for Day ${widget.dayNumber} only or across all days?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.dayNumber != null)
                        RadioListTile<bool>(
                          title: Text(
                            'This day only (Day ${widget.dayNumber})',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          value: false,
                          groupValue: applyToAll,
                          onChanged:
                              (value) =>
                                  setDialogState(() => applyToAll = value!),
                          activeColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      RadioListTile<bool>(
                        title: Text(
                          'All days',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: true,
                        groupValue: applyToAll,
                        onChanged:
                            (value) =>
                                setDialogState(() => applyToAll = value!),
                        activeColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                style: Theme.of(context).filledButtonTheme.style,
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Replace',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
    return {'confirmed': confirmed, 'applyToAll': applyToAll};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    debugPrint(
      'UserProvider state: isLoggedIn=${userProvider.isLoggedIn}, uid=${userProvider.firebaseUser?.uid}',
    );
    final filteredExercises =
        _allExercises.where((exercise) {
          if (_searchQuery.isEmpty) return true;
          return exercise.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
                : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPLACE EXERCISE',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: colorScheme.error,
                                  size: 28,
                                ),
                                tooltip: 'Remove Exercise',
                                padding: const EdgeInsets.all(8),
                                onPressed:
                                    () => _replaceExercise(
                                      null,
                                      widget.dayNumber != null,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                tooltip: 'Browse All Exercises',
                                padding: const EdgeInsets.all(8),
                                onPressed:
                                    () => setState(
                                      () => _isBrowsingAll = !_isBrowsingAll,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isBrowsingAll
                                ? 'All Exercises'
                                : 'Recommended Replacements',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isBrowsingAll) ...[
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Search exercises',
                                labelStyle: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged:
                                  (value) =>
                                      setState(() => _searchQuery = value),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ...(_isBrowsingAll
                                  ? filteredExercises
                                  : _recommendedExercises)
                              .map(
                                (exercise) => AppTheme.animatedCard(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (exercise.id.isNotEmpty &&
                                          exercise.id != '1') {
                                        debugPrint(
                                          'Tapped exercise: ${exercise.id}, name: ${exercise.name}',
                                        );
                                        final result =
                                            await _confirmApplyToAll();
                                        if (result['confirmed']) {
                                          final replaceResult =
                                              await _replaceExercise(
                                                exercise.id,
                                                result['applyToAll'],
                                              );
                                          if (replaceResult['success'] &&
                                              mounted) {
                                            // Navigation handled in _replaceExercise
                                          }
                                        }
                                      } else {
                                        debugPrint(
                                          'Invalid exercise ID: ${exercise.id}',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Cannot replace with invalid exercise',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onError,
                                              ),
                                            ),
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    },
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child:
                                                  exercise.image != null
                                                      ? Image.network(
                                                        exercise.image!,
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              width: 100,
                                                              height: 100,
                                                              color:
                                                                  colorScheme
                                                                      .surfaceContainer,
                                                              child: Icon(
                                                                Icons
                                                                    .fitness_center,
                                                                color:
                                                                    colorScheme
                                                                        .onSurfaceVariant,
                                                              ),
                                                            ),
                                                      )
                                                      : Container(
                                                        width: 100,
                                                        height: 100,
                                                        color:
                                                            colorScheme
                                                                .surfaceContainer,
                                                        child: Icon(
                                                          Icons.fitness_center,
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                      ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exercise.name,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color:
                                                              colorScheme
                                                                  .onSurface,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    exercise.muscleGroups.join(
                                                      ', ',
                                                    ),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Difficulty: ${exercise.difficulty ?? 'N/A'}',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Equipment: ${exercise.specificEquipment ?? 'None'}',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
