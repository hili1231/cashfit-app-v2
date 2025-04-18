import 'package:cashfit/models/active_workout_program.dart';
import 'package:cashfit/models/workout_program.dart';
import 'package:cashfit/providers/user_provider.dart';
import 'package:cashfit/screens/nav_screen.dart';
import 'package:cashfit/screens/workouts/workout_day_detail_screen.dart';
import 'package:cashfit/theme.dart';
import 'package:cashfit/widgets/workout_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'workout_detail_screen.dart';

// Define the RemovedWorkoutProgram class for deactivated workouts
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
  static List<ActiveWorkoutProgram>? _cachedActivePrograms;
  static List<WorkoutProgram>? _cachedActiveWorkouts;

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<List<WorkoutProgram>> _fetchFuture;
  List<ActiveWorkoutProgram> _activeWorkoutPrograms = [];
  List<WorkoutProgram> _activeWorkouts = [];
  final Map<String, bool> _deactivatedWorkouts = {};

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

    if (WorkoutsScreen._cachedActivePrograms != null &&
        WorkoutsScreen._cachedActiveWorkouts != null) {
      _activeWorkoutPrograms = WorkoutsScreen._cachedActivePrograms!;
      _activeWorkouts = WorkoutsScreen._cachedActiveWorkouts!;
    } else {
      _fetchActiveWorkouts();
    }
  }

  Future<List<WorkoutProgram>> _fetchAllWorkouts() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<WorkoutProgram> allWorkouts = [];

    final snapshot =
        await FirebaseFirestore.instance.collection('workoutPrograms').get();

    allWorkouts =
        snapshot.docs
            .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
            .toList();

    if (userProvider.isLoggedIn && userProvider.firebaseUser != null) {
      final uid = userProvider.firebaseUser!.uid;

      // Parallel fetch: prepare all futures
      final futures =
          allWorkouts.map((workout) {
            return FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('removedWorkoutPrograms')
                .doc(workout.id)
                .get()
                .then((doc) => MapEntry(workout.id, doc.exists));
          }).toList();

      final results = await Future.wait(futures);

      for (var result in results) {
        _deactivatedWorkouts[result.key] = result.value;
      }
    }

    return allWorkouts;
  }

  Future<void> _fetchActiveWorkouts() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      if (mounted) {
        setState(() {
          _activeWorkoutPrograms = [];
          _activeWorkouts = [];
        });
      }
      WorkoutsScreen._cachedActivePrograms = [];
      WorkoutsScreen._cachedActiveWorkouts = [];
      return;
    }

    try {
      setState(() {});

      final activeSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .collection('activeWorkoutPrograms')
              .get();
      final programs = <ActiveWorkoutProgram>[];
      final workouts = <WorkoutProgram>[];
      for (var doc in activeSnapshot.docs) {
        final activeProgram = ActiveWorkoutProgram.fromMap(doc.data());
        final programSnapshot =
            await FirebaseFirestore.instance
                .collection('workoutPrograms')
                .doc(activeProgram.workoutProgramId)
                .get();
        if (programSnapshot.exists) {
          programs.add(activeProgram);
          workouts.add(
            WorkoutProgram.fromMap(programSnapshot.data()!, programSnapshot.id),
          );
          _deactivatedWorkouts[activeProgram.workoutProgramId] = false;
        }
      }
      if (mounted) {
        setState(() {
          _activeWorkoutPrograms = programs;
          _activeWorkouts = workouts;
        });
      }
      WorkoutsScreen._cachedActivePrograms = programs;
      WorkoutsScreen._cachedActiveWorkouts = workouts;
    } catch (e) {
      debugPrint('Error fetching active workouts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load active programs: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setActiveWorkout(String workoutProgramId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) return;

    try {
      final activeProgramRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeWorkoutPrograms')
          .doc(workoutProgramId);

      // Optimistically update the local state
      final newProgram = ActiveWorkoutProgram(
        workoutProgramId: workoutProgramId,
        startDate: DateTime.now(),
        currentDay: 1,
      );

      final programSnapshot =
          await FirebaseFirestore.instance
              .collection('workoutPrograms')
              .doc(workoutProgramId)
              .get();

      if (programSnapshot.exists) {
        final workout = WorkoutProgram.fromMap(
          programSnapshot.data()!,
          programSnapshot.id,
        );

        setState(() {
          _activeWorkoutPrograms.add(newProgram);
          _activeWorkouts.add(workout);
          _deactivatedWorkouts[workoutProgramId] = false;
          WorkoutsScreen._cachedActivePrograms = _activeWorkoutPrograms;
          WorkoutsScreen._cachedActiveWorkouts = _activeWorkouts;
        });

        await activeProgramRef.set({
          'workoutProgramId': workoutProgramId,
          'startDate': DateTime.now().toIso8601String(),
          'currentDay': 1,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.firebaseUser!.uid)
            .collection('removedWorkoutPrograms')
            .doc(workoutProgramId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Workout added to active programs',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error setting active workout: $e');
      if (mounted) {
        setState(() {
          // Revert the optimistic update if the Firestore operation fails
          _activeWorkoutPrograms.removeWhere(
            (program) => program.workoutProgramId == workoutProgramId,
          );
          _activeWorkouts.removeWhere(
            (workout) => workout.id == workoutProgramId,
          );
          WorkoutsScreen._cachedActivePrograms = _activeWorkoutPrograms;
          WorkoutsScreen._cachedActiveWorkouts = _activeWorkouts;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to set active workout: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      await _fetchActiveWorkouts();
    }
  }

  Future<void> _removeActiveWorkout(String workoutProgramId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) return;

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

    if (!confirmed) return;

    try {
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

      setState(() {
        final index = _activeWorkoutPrograms.indexWhere(
          (program) => program.workoutProgramId == workoutProgramId,
        );
        if (index != -1) {
          _activeWorkoutPrograms.removeAt(index);
          _activeWorkouts.removeAt(index);
        }
        _deactivatedWorkouts[workoutProgramId] = true;
        WorkoutsScreen._cachedActivePrograms = _activeWorkoutPrograms;
        WorkoutsScreen._cachedActiveWorkouts = _activeWorkouts;
      });

      await removedProgramRef.set(
        RemovedWorkoutProgram(
          workoutProgramId: workoutProgramId,
          removedDate: DateTime.now(),
          uid: userProvider.firebaseUser!.uid,
        ).toMap(),
      );

      await activeProgramRef.delete();

      if (mounted) {
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
        setState(() {
          _deactivatedWorkouts[workoutProgramId] = false;
        });
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
      await _fetchActiveWorkouts();
    }
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
        body: FutureBuilder<List<WorkoutProgram>>(
          future: _fetchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
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
                      if (userProvider.isLoggedIn)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Your Active Programs",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
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
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  userProvider.isLoggedIn &&
                                          userProvider.firebaseUser != null
                                      ? FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userProvider.firebaseUser!.uid)
                                          .collection('activeWorkoutPrograms')
                                          .snapshots()
                                      : Stream.empty(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${snapshot.error}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  );
                                }
                                if (!userProvider.isLoggedIn ||
                                    userProvider.firebaseUser == null ||
                                    !snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "No active programs",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  );
                                }

                                return FutureBuilder<
                                  List<Map<String, dynamic>>
                                >(
                                  future: _processActiveWorkouts(
                                    snapshot.data!.docs,
                                  ),
                                  builder: (context, futureSnapshot) {
                                    if (futureSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (futureSnapshot.hasError) {
                                      return Center(
                                        child: Text(
                                          'Error: ${futureSnapshot.error}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      );
                                    }
                                    if (!futureSnapshot.hasData ||
                                        futureSnapshot.data!.isEmpty) {
                                      return Center(
                                        child: Text(
                                          "No active programs",
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      );
                                    }

                                    final activeData = futureSnapshot.data!;
                                    _activeWorkoutPrograms =
                                        activeData
                                            .map(
                                              (data) =>
                                                  data['program']
                                                      as ActiveWorkoutProgram,
                                            )
                                            .toList();
                                    _activeWorkouts =
                                        activeData
                                            .map(
                                              (data) =>
                                                  data['workout']
                                                      as WorkoutProgram,
                                            )
                                            .toList();
                                    WorkoutsScreen._cachedActivePrograms =
                                        _activeWorkoutPrograms;
                                    WorkoutsScreen._cachedActiveWorkouts =
                                        _activeWorkouts;

                                    return SizedBox(
                                      height: 200,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: _activeWorkouts.length,
                                        separatorBuilder:
                                            (_, __) =>
                                                const SizedBox(width: 14),
                                        itemBuilder: (context, index) {
                                          final workout =
                                              _activeWorkouts[index];
                                          final program =
                                              _activeWorkoutPrograms[index];
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
                                                          colorScheme.primary,
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
                                                          colorScheme.primary,
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
                                                          colorScheme.primary,
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
                          "Beginner",
                          beginnerWorkouts,
                        ),
                      if (intermediateWorkouts.isNotEmpty)
                        _buildWorkoutCategorySection(
                          theme,
                          colorScheme,
                          "Intermediate",
                          intermediateWorkouts,
                        ),
                      if (advancedWorkouts.isNotEmpty)
                        _buildWorkoutCategorySection(
                          theme,
                          colorScheme,
                          "Advanced",
                          advancedWorkouts,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _processActiveWorkouts(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final programs = <ActiveWorkoutProgram>[];
    final workouts = <WorkoutProgram>[];
    for (var doc in docs) {
      final activeProgram = ActiveWorkoutProgram.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      final programSnapshot =
          await FirebaseFirestore.instance
              .collection('workoutPrograms')
              .doc(activeProgram.workoutProgramId)
              .get();
      if (programSnapshot.exists) {
        programs.add(activeProgram);
        workouts.add(
          WorkoutProgram.fromMap(programSnapshot.data()!, programSnapshot.id),
        );
        _deactivatedWorkouts[activeProgram.workoutProgramId] = false;
      }
    }
    return List.generate(
      programs.length,
      (index) => {'program': programs[index], 'workout': workouts[index]},
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
              final isActive = _activeWorkouts.any((w) => w.id == workout.id);

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

// New screen to display deactivated workouts
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
                      'Deactivated Workouts',
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
                        navState?.setDetailScreen(null);
                        navState?.onItemTapped(
                          1,
                        ); // Navigate back to WorkoutsScreen
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userProvider.firebaseUser!.uid)
                            .collection('removedWorkoutPrograms')
                            .get(),
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
                            future:
                                FirebaseFirestore.instance
                                    .collection('workoutPrograms')
                                    .doc(removedProgram.workoutProgramId)
                                    .get(),
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
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userProvider.firebaseUser!.uid)
                                        .collection('activeWorkoutPrograms')
                                        .doc(workout.id)
                                        .set({
                                          'workoutProgramId': workout.id,
                                          'startDate':
                                              DateTime.now().toIso8601String(),
                                          'currentDay': 1,
                                          'uid': userProvider.firebaseUser!.uid,
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
                                          backgroundColor: colorScheme.primary,
                                        ),
                                      );
                                      final navState =
                                          context
                                              .findAncestorStateOfType<
                                                NavScreenState
                                              >();
                                      navState?.setDetailScreen(null);
                                      navState?.onItemTapped(
                                        1,
                                      ); // Navigate back to WorkoutsScreen
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
