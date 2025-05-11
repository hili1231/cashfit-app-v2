import 'package:cashfit/models/active_workout_program.dart';
import 'package:cashfit/models/workout_program.dart';
import 'package:cashfit/providers/user_provider.dart';
import 'package:cashfit/screens/nav_screen.dart';
import 'package:cashfit/screens/personalize/workout_diet_builder_screen.dart';
import 'package:cashfit/screens/workouts/workout_day_detail_screen.dart';
import 'package:cashfit/services/cache_service.dart';
import 'package:cashfit/theme.dart';
import 'package:cashfit/widgets/workout_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'workout_detail_screen.dart';

class RemovedWorkoutProgram {
  final String workoutProgramId;
  final DateTime removedDate;
  final String uid;

  RemovedWorkoutProgram({
    required this.workoutProgramId,
    required this.removedDate,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutProgramId': workoutProgramId,
      'removedDate': removedDate.toIso8601String(),
      'uid': uid,
    };
  }

  static RemovedWorkoutProgram fromMap(Map<String, dynamic> map) {
    return RemovedWorkoutProgram(
      workoutProgramId: map['workoutProgramId'] ?? '',
      removedDate: DateTime.parse(map['removedDate']),
      uid: map['uid'] ?? '',
    );
  }
}

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  static List<WorkoutProgram>? _cachedWorkouts;

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final Logger _logger = Logger();
  late Future<List<WorkoutProgram>> _fetchFuture;
  final Map<String, bool> _deactivatedWorkouts = {};
  final bool _isLoadingActiveWorkouts = false;

  @override
  void initState() {
    super.initState();
    if (WorkoutsScreen._cachedWorkouts != null) {
      _fetchFuture = Future.value(WorkoutsScreen._cachedWorkouts);
    } else {
      _fetchFuture = _fetchAllWorkouts().then((value) {
        WorkoutsScreen._cachedWorkouts = value;
        return value;
      });
    }
  }

  Future<List<WorkoutProgram>> _fetchAllWorkouts() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<WorkoutProgram> allWorkouts = [];

    try {
      debugPrint('Fetching all workout programs using CacheService');
      // Use the cache service to retrieve workout programs
      allWorkouts = await CacheService().getWorkoutPrograms();

      if (userProvider.isLoggedIn && userProvider.firebaseUser != null) {
        final uid = userProvider.firebaseUser!.uid;
        debugPrint('Fetching deactivation status for user: $uid');

        const batchSize = 10;
        for (var i = 0; i < allWorkouts.length; i += batchSize) {
          final batchIds =
              allWorkouts
                  .sublist(
                    i,
                    i + batchSize > allWorkouts.length
                        ? allWorkouts.length
                        : i + batchSize,
                  )
                  .map((workout) => workout.id)
                  .toList();
          final batchSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('removedWorkoutPrograms')
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();
          for (var doc in batchSnapshot.docs) {
            _deactivatedWorkouts[doc.id] = true;
          }
        }

        for (var workout in allWorkouts) {
          _deactivatedWorkouts.putIfAbsent(workout.id, () => false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching workout programs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load workouts: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    return allWorkouts;
  }

  Future<void> _setActiveWorkout(String workoutProgramId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      debugPrint('User not logged in or firebaseUser is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please log in to add workouts to your active programs',
            ),
          ),
        );
        if (navState != null) {
          navState.navigateToLogin();
        }
      }
      return;
    }

    try {
      debugPrint('Activating workout program: $workoutProgramId');
      final activeProgramRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeWorkoutPrograms')
          .doc(workoutProgramId);

      debugPrint('Fetching workout program data for: $workoutProgramId');
      final programSnapshot =
          await FirebaseFirestore.instance
              .collection('workoutPrograms')
              .doc(workoutProgramId)
              .get();

      if (!programSnapshot.exists) {
        debugPrint('Workout program does not exist: $workoutProgramId');
        throw Exception('Workout program not found');
      }

      debugPrint('Writing active workout program to Firestore');
      await activeProgramRef.set({
        'workoutProgramId': workoutProgramId,
        'startDate': DateTime.now().toIso8601String(),
        'currentDay': 1,
        'completedDays': [],
      });

      debugPrint('Removing workout program from removedWorkoutPrograms');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('removedWorkoutPrograms')
          .doc(workoutProgramId)
          .delete();

      // Invalidate the cache to force a refresh
      await CacheService().invalidateUserWorkoutsCache(
        userProvider.firebaseUser!.uid,
      );

      // Optimized approach - only fetch and update active programs
      final activePrograms =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .collection('activeWorkoutPrograms')
              .get();

      final mappedPrograms =
          activePrograms.docs
              .map((doc) => ActiveWorkoutProgram.fromMap(doc.data()))
              .toList();

      // Update just the active workouts instead of refreshing all user data
      await userProvider.updateActiveWorkoutPrograms(mappedPrograms);

      if (mounted) {
        debugPrint('Showing success snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout added to active programs',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting active workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add active workout: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeActiveWorkout(String workoutProgramId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      debugPrint('User not logged in or firebaseUser is null');
      return;
    }

    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Remove Active Workout?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );

    if (!confirmed) {
      debugPrint('Removal cancelled');
      return;
    }

    try {
      debugPrint('Removing active workout program: $workoutProgramId');
      final activeProgramRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeWorkoutPrograms')
          .doc(workoutProgramId);

      final removedProgramRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('removedWorkoutPrograms')
          .doc(workoutProgramId);

      debugPrint('Setting removed workout program in Firestore');
      await removedProgramRef.set(
        RemovedWorkoutProgram(
          workoutProgramId: workoutProgramId,
          removedDate: DateTime.now(),
          uid: userProvider.firebaseUser!.uid,
        ).toMap(),
      );
      debugPrint('Deleting active workout program from Firestore');
      await activeProgramRef.delete();

      // Invalidate the cache to force a refresh
      await CacheService().invalidateUserWorkoutsCache(
        userProvider.firebaseUser!.uid,
      );

      // Optimized approach - only fetch and update active programs
      final activePrograms =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .collection('activeWorkoutPrograms')
              .get();

      final mappedPrograms =
          activePrograms.docs
              .map((doc) => ActiveWorkoutProgram.fromMap(doc.data()))
              .toList();

      // Update just the active workouts instead of refreshing all user data
      await userProvider.updateActiveWorkoutPrograms(mappedPrograms);

      if (mounted) {
        debugPrint('Showing success snackbar for removal');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout removed from active programs',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing active workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove active workout: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<Map<String, WorkoutProgram>> _fetchWorkoutPrograms(
    List<String> programIds,
  ) async {
    final Map<String, WorkoutProgram> workoutMap = {};
    if (programIds.isEmpty) {
      _logger.w('No program IDs provided to fetch');
      return workoutMap;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      _logger.w('User not logged in, cannot fetch workout programs');
      return workoutMap;
    }

    // Use CacheService to get active workouts for the user
    final activeWorkoutPrograms =
        userProvider.currentUser?.activeWorkoutPrograms ?? [];

    if (activeWorkoutPrograms.isEmpty) {
      _logger.w('No active workout programs in currentUser object');
      return workoutMap;
    }
    try {
      _logger.d(
        'Using CacheService to fetch active workouts for user: ${userProvider.firebaseUser!.uid}',
      );
      _logger.d('Active workout IDs: ${programIds.join(', ')}');
      _logger.i(
        'Fetching active workouts for user: ${userProvider.firebaseUser!.uid}',
      );
      _logger.d('Active workout IDs from params: ${programIds.join(', ')}');
      _logger.d(
        'Active workout IDs from user object: ${activeWorkoutPrograms.map((wp) => wp.workoutProgramId).join(', ')}',
      );

      // Force refresh to ensure we get the latest data
      final cachedWorkouts = await CacheService().getUserActiveWorkouts(
        userProvider.firebaseUser!.uid,
        activeWorkoutPrograms,
        forceRefresh: true, // Force refresh to get updated data
      );

      _logger.i(
        'Retrieved ${cachedWorkouts.length} workout programs from cache',
      );

      // We still need to apply the deactivation status
      for (final entry in cachedWorkouts.entries) {
        // Skip workouts that have a userId (user-specific workouts)
        if (entry.value.userId != null && entry.value.userId!.isNotEmpty) {
          continue;
        }
        workoutMap[entry.key] = entry.value;
        _deactivatedWorkouts[entry.key] = false;
      }
    } catch (e) {
      _logger.e('Error fetching workout programs from cache: $e');
      // Fallback to direct Firestore query if cache fails
      if (programIds.isNotEmpty) {
        const batchSize = 10;
        for (var i = 0; i < programIds.length; i += batchSize) {
          final batchIds = programIds.sublist(
            i,
            i + batchSize > programIds.length
                ? programIds.length
                : i + batchSize,
          );

          try {
            final programSnapshot =
                await FirebaseFirestore.instance
                    .collection('workoutPrograms')
                    .where(FieldPath.documentId, whereIn: batchIds)
                    .get();

            final batchWorkouts =
                programSnapshot.docs
                    .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
                    .toList();

            for (var workout in batchWorkouts) {
              workoutMap[workout.id] = workout;
              _deactivatedWorkouts[workout.id] = false;
            }
          } catch (e) {
            _logger.e('Error fetching workout batch: $e');
          }
        }
      }
    }

    return workoutMap;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            FutureBuilder<List<WorkoutProgram>>(
              future: _fetchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading workout programs...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No workouts found",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final allWorkouts = snapshot.data!;
                final beginnerWorkouts = <WorkoutProgram>[];
                final intermediateWorkouts = <WorkoutProgram>[];
                final advancedWorkouts = <WorkoutProgram>[];

                for (var wp in allWorkouts) {
                  // Skip workouts that have a userId (user-specific workouts)
                  if (wp.userId != null && wp.userId!.isNotEmpty) {
                    continue;
                  }
                  
                  final level = wp.level.trim().toLowerCase();
                  if (level == "beginner") {
                    beginnerWorkouts.add(wp);
                  } else if (level == "intermediate") {
                    intermediateWorkouts.add(wp);
                  } else if (level == "advanced") {
                    advancedWorkouts.add(wp);
                  }
                }

                return SingleChildScrollView(
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
                            "WORKOUTS",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (userProvider.isLoggedIn &&
                              userProvider.firebaseUser != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ACTIVE WORKOUTS",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_sweep,
                                            color: colorScheme.primary,
                                          ),
                                          tooltip: 'View Deactivated Workouts',
                                          onPressed: () {
                                            final navState =
                                                context
                                                    .findAncestorStateOfType<
                                                      NavScreenState
                                                    >();
                                            navState?.setDetailScreen(
                                              const DeactivatedWorkoutsScreen(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Builder(
                                  builder: (context) {
                                    final activePrograms =
                                        userProvider
                                            .currentUser
                                            ?.activeWorkoutPrograms ??
                                        [];

                                    _logger.i(
                                      'User has ${activePrograms.length} active workout programs',
                                    );
                                    
                                    if (activePrograms.isEmpty) {
                                      return SizedBox(
                                        height: 200,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          children: [
                                            SizedBox(
                                              width: 180,
                                              child: Card(
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                color: colorScheme.surface,
                                                child: InkWell(
                                                  onTap: () {
                                                    final navState = context.findAncestorStateOfType<NavScreenState>();
                                                    navState?.setDetailScreen(
                                                      const WorkoutDietBuilderScreen(),
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_circle_outline,
                                                        size: 48,
                                                        color: colorScheme.primary,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Build More Plans',
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          color: colorScheme.primary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return FutureBuilder<Map<String, WorkoutProgram>>(
                                      future: _fetchWorkoutPrograms(
                                        activePrograms.map((p) => p.workoutProgramId).toList(),
                                      ),
                                      builder: (context, workoutSnapshot) {
                                        if (workoutSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (workoutSnapshot.hasError) {
                                          _logger.e(
                                            'Error fetching active workout programs: ${workoutSnapshot.error}',
                                          );
                                          return Center(
                                            child: Text(
                                              'Error: ${workoutSnapshot.error}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                          );
                                        }
                                        if (!workoutSnapshot.hasData ||
                                            workoutSnapshot.data!.isEmpty) {
                                          _logger.w(
                                            'No active workout programs found in cache',
                                          );
                                          return Center(
                                            child: Text(
                                              "No active programs found",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                          );
                                        }
                                        final workoutMap =
                                            workoutSnapshot.data!;

                                        _logger.i(
                                          'Retrieved ${workoutMap.length} workout programs from cache',
                                        );
                                        _logger.d(
                                          'Workout IDs in map: ${workoutMap.keys.join(", ")}',
                                        );

                                        final activeData =
                                            activePrograms
                                                .where((program) {
                                                  final hasWorkout = workoutMap
                                                      .containsKey(
                                                        program
                                                            .workoutProgramId,
                                                      );
                                                  if (!hasWorkout) {
                                                    _logger.w(
                                                      'Active workout ${program.workoutProgramId} not found in cache',
                                                    );
                                                  }
                                                  return hasWorkout;
                                                })
                                                .map(
                                                  (program) => {
                                                    'program': program,
                                                    'workout':
                                                        workoutMap[program
                                                            .workoutProgramId]!,
                                                  },
                                                )
                                                .toList();

                                        if (activeData.isEmpty) {
                                          return Center(
                                            child: Text(
                                              "No active programs found",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                          );
                                        }
                                        
                                        return SizedBox(
                                          height: 200,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            physics: const BouncingScrollPhysics(),
                                            itemCount: activeData.length + 1,
                                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                                            itemBuilder: (context, index) {
                                              if (index == activeData.length) {
                                                return SizedBox(
                                                  width: 180,
                                                  child: Card(
                                                    elevation: 4,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    color: colorScheme.surface,
                                                    child: InkWell(
                                                      onTap: () {
                                                        final navState = context.findAncestorStateOfType<NavScreenState>();
                                                        navState?.setDetailScreen(
                                                          const WorkoutDietBuilderScreen(),
                                                        );
                                                      },
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.add_circle_outline,
                                                            size: 48,
                                                            color: colorScheme.primary,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Build More Plans',
                                                            style: theme.textTheme.titleMedium?.copyWith(
                                                              color: colorScheme.primary,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              final workout =
                                                  activeData[index]['workout']
                                                      as WorkoutProgram;
                                              final program =
                                                  activeData[index]['program']
                                                      as ActiveWorkoutProgram;
                                              return GestureDetector(
                                                onTap: () {
                                                  final navState =
                                                      context
                                                          .findAncestorStateOfType<
                                                            NavScreenState
                                                          >();
                                                  navState?.setDetailScreen(
                                                    WorkoutDetailScreen(
                                                      workout: workout,
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: WorkoutCard(
                                                        workout: workout,
                                                        currentDay:
                                                            program.currentDay,
                                                        onDayButtonPressed: () {
                                                          final navState =
                                                              context
                                                                  .findAncestorStateOfType<
                                                                    NavScreenState
                                                                  >();
                                                          navState?.setDetailScreen(
                                                            DayDetailScreen(
                                                              dayNumber:
                                                                  program
                                                                      .currentDay,
                                                              dayExercises:
                                                                  workout
                                                                      .days['Day ${program.currentDay}'] ??
                                                                  [],
                                                              workout: workout,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Active',
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color:
                                                                    colorScheme
                                                                        .onPrimary,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.close,
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            'Remove Active Workout',
                                                        onPressed:
                                                            () =>
                                                                _removeActiveWorkout(
                                                                  workout.id,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          if (beginnerWorkouts.isNotEmpty)
                            _buildWorkoutCategorySection(
                              theme,
                              colorScheme,
                              "BEGINNER",
                              beginnerWorkouts,
                            ),
                          if (intermediateWorkouts.isNotEmpty)
                            _buildWorkoutCategorySection(
                              theme,
                              colorScheme,
                              "INTERMEDIATE",
                              intermediateWorkouts,
                            ),
                          if (advancedWorkouts.isNotEmpty)
                            _buildWorkoutCategorySection(
                              theme,
                              colorScheme,
                              "ADVANCED",
                              advancedWorkouts,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isLoadingActiveWorkouts)
              Positioned(
                bottom: 16,
                right: 16,
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCategorySection(
    ThemeData theme,
    ColorScheme colorScheme,
    String level,
    List<WorkoutProgram> workouts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final isActive = _deactivatedWorkouts[workout.id] == false;

              return GestureDetector(
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  navState?.setDetailScreen(
                    WorkoutDetailScreen(workout: workout),
                  );
                },
                child: Stack(
                  children: [
                    WorkoutCard(workout: workout),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.play_circle,
                          color: colorScheme.primary,
                        ),
                        onPressed:
                            isActive
                                ? null
                                : () => _setActiveWorkout(workout.id),
                        tooltip: 'Set as Active',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class DeactivatedWorkoutsScreen extends StatelessWidget {
  const DeactivatedWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: AppTheme.backgroundGradient(colorScheme),
          child: const Center(
            child: Text('Please log in to view deactivated workouts.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DEACTIVATED WORKOUTS',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () {
                        final navState =
                            context.findAncestorStateOfType<NavScreenState>();
                        navState?.clearDetailAndGoTo(
                          1,
                        ); // Navigate to Workouts tab
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: Future.microtask(
                      () => FirebaseFirestore.instance
                          .collection('users')
                          .doc(userProvider.firebaseUser!.uid)
                          .collection('removedWorkoutPrograms')
                          .get(GetOptions(source: Source.cache)),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No deactivated workouts found.'),
                        );
                      }

                      final deactivatedDocs = snapshot.data!.docs;
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: deactivatedDocs.length,
                        itemBuilder: (context, index) {
                          final removedProgram = RemovedWorkoutProgram.fromMap(
                            deactivatedDocs[index].data()
                                as Map<String, dynamic>,
                          );
                          return FutureBuilder<DocumentSnapshot>(
                            future: Future.microtask(
                              () => FirebaseFirestore.instance
                                  .collection('workoutPrograms')
                                  .doc(removedProgram.workoutProgramId)
                                  .get(GetOptions(source: Source.cache)),
                            ),
                            builder: (context, workoutSnapshot) {
                              if (workoutSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Loading...'),
                                );
                              }
                              if (workoutSnapshot.hasError) {
                                return ListTile(
                                  title: Text(
                                    'Error: ${workoutSnapshot.error}',
                                  ),
                                );
                              }
                              if (!workoutSnapshot.hasData ||
                                  !workoutSnapshot.data!.exists) {
                                return const ListTile(
                                  title: Text('Workout not found'),
                                );
                              }

                              final workout = WorkoutProgram.fromMap(
                                workoutSnapshot.data!.data()
                                    as Map<String, dynamic>,
                                workoutSnapshot.data!.id,
                              );

                              return ListTile(
                                title: Text(
                                  workout.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Removed on: ${removedProgram.removedDate.toString().split(' ')[0]}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                  ),
                                  onPressed: () async {
                                    try {
                                      debugPrint(
                                        'Reactivating workout: ${workout.id}',
                                      );
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userProvider.firebaseUser!.uid)
                                          .collection('activeWorkoutPrograms')
                                          .doc(workout.id)
                                          .set({
                                            'workoutProgramId': workout.id,
                                            'startDate':
                                                DateTime.now()
                                                    .toIso8601String(),
                                            'currentDay': 1,
                                            'completedDays': [],
                                          });

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userProvider.firebaseUser!.uid)
                                          .collection('removedWorkoutPrograms')
                                          .doc(workout.id)
                                          .delete();

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Workout reactivated',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                            backgroundColor:
                                                colorScheme.primary,
                                          ),
                                        );
                                        final navState =
                                            context
                                                .findAncestorStateOfType<
                                                  NavScreenState
                                                >();
                                        navState?.clearDetailAndGoTo(
                                          1,
                                        ); // Navigate to Workouts tab
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        'Error reactivating workout: $e',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to reactivate workout: $e',
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
                                    }
                                  },
                                  child: const Text('Reactivate'),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
