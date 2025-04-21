import 'package:cashfit/auth/login_screen.dart';
import 'package:cashfit/providers/user_provider.dart';
import 'package:cashfit/screens/workouts/replace_workout_context_provider.dart';
import 'package:cashfit/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';
import 'exercise_detail_screen.dart';
import 'workout_day_detail_screen.dart';
import '../nav_screen.dart';
import 'replace_exercise_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutProgram workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  Future<Map<String, dynamic>> _fetchAllData(
    String userId,
    List<MapEntry<String, List<Map<String, dynamic>>>> sortedDays,
  ) async {
    final stepGoalFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((doc) {
          return doc.exists
              ? (doc.data()!['dailyStepTarget'] as int? ?? 10000)
              : 10000;
        });

    final exerciseFutures =
        sortedDays.map((entry) async {
          final dayExercises = entry.value;
          if (dayExercises.isEmpty) return <Exercise>[];
          final exerciseIds =
              dayExercises.map((e) => e['exerciseId'] as String).toList();
          final snapshot =
              await FirebaseFirestore.instance
                  .collection('exercises')
                  .where(FieldPath.documentId, whereIn: exerciseIds)
                  .get();
          return snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
              .toList();
        }).toList();

    // Fetch completed days for this workout
    final completedDaysFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('activeWorkoutPrograms')
        .doc(workout.id)
        .get()
        .then((doc) {
          if (doc.exists && doc.data()!.containsKey('completedDays')) {
            return List<int>.from(doc['completedDays'] as List<dynamic>);
          }
          return <int>[];
        });

    final results = await Future.wait([
      stepGoalFuture,
      completedDaysFuture,
      ...exerciseFutures,
    ]);
    final stepGoal = results[0] as int;
    final completedDays = results[1] as List<int>;
    final exercisesByDay = results
        .sublist(2)
        .asMap()
        .map(
          (index, exercises) =>
              MapEntry(sortedDays[index].key, exercises as List<Exercise>),
        );

    return {
      'stepGoal': stepGoal,
      'completedDays': completedDays,
      'exercisesByDay': exercisesByDay,
    };
  }

  void _handleReplace(BuildContext context, String exerciseId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();
    final replaceContext = Provider.of<ReplaceContextProvider>(
      context,
      listen: false,
    );

    if (!userProvider.isLoggedIn) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Login Required',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: Text(
                'Please log in to replace exercises.',
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
                  style: Theme.of(context).filledButtonTheme.style,
                  onPressed: () {
                    replaceContext.setContext(
                      exerciseId: exerciseId,
                      dayNumber: null,
                      originatingScreen: OriginatingScreen.workoutDetail,
                      workoutProgramId: workout.id,
                    );
                    Navigator.pop(context);
                    navState?.setDetailScreen(const LoginScreen());
                  },
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
      );
    } else {
      replaceContext.setContext(
        exerciseId: exerciseId,
        dayNumber: null,
        originatingScreen: OriginatingScreen.workoutDetail,
        workoutProgramId: workout.id,
      );
      navState?.setDetailScreen(
        ReplaceExerciseScreen(
          exerciseId: exerciseId,
          dayNumber: null,
          workout: workout,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.firebaseUser?.uid ?? 'currentUserId';

    final sortedDays =
        workout.days.entries.toList()..sort((a, b) {
          final aNum = int.parse(a.key.replaceAll('Day ', ''));
          final bNum = int.parse(b.key.replaceAll('Day ', ''));
          return aNum.compareTo(bNum);
        });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchAllData(userId, sortedDays),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading data",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final data = snapshot.data!;
              final stepGoal = data['stepGoal'] as int;
              final completedDays = data['completedDays'] as List<int>;
              final exercisesByDay =
                  data['exercisesByDay'] as Map<String, List<Exercise>>;

              // Sort days: uncompleted days first, completed days at the bottom
              final uncompletedDays =
                  <MapEntry<String, List<Map<String, dynamic>>>>[];
              final completedDaysList =
                  <MapEntry<String, List<Map<String, dynamic>>>>[];
              for (var dayEntry in sortedDays) {
                final dayNumber = int.parse(
                  dayEntry.key.replaceAll('Day ', ''),
                );
                if (completedDays.contains(dayNumber)) {
                  completedDaysList.add(dayEntry);
                } else {
                  uncompletedDays.add(dayEntry);
                }
              }
              final reorderedDays = [...uncompletedDays, ...completedDaysList];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            workout.image,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildPlaceholderImage(
                                  colorScheme: colorScheme,
                                  height: 220,
                                ),
                            loadingBuilder:
                                (context, child, loadingProgress) =>
                                    loadingProgress == null
                                        ? child
                                        : _buildPlaceholderImage(
                                          colorScheme: colorScheme,
                                          height: 220,
                                        ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        workout.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...reorderedDays.map((entry) {
                        final day = entry.key;
                        final dayExercises = entry.value;
                        final exercises = exercisesByDay[day] ?? [];
                        final dayNumber = int.parse(day.replaceAll('Day ', ''));
                        final isCompleted = completedDays.contains(dayNumber);
                        return _buildDaySection(
                          context,
                          theme,
                          colorScheme,
                          day,
                          dayExercises,
                          exercises,
                          stepGoal,
                          isCompleted,
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String day,
    List<Map<String, dynamic>> dayExercises,
    List<Exercise> exercises,
    int stepGoal,
    bool isCompleted,
  ) {
    final dayNumber = int.parse(day.replaceAll('Day ', ''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        day,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color:
                              isCompleted
                                  ? colorScheme.onSurface.withAlpha(
                                    (255 * 0.6).round(),
                                  )
                                  : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      final navState =
                          context.findAncestorStateOfType<NavScreenState>();
                      navState?.setDetailScreen(
                        DayDetailScreen(
                          dayNumber: dayNumber,
                          dayExercises: dayExercises,
                          workout: workout,
                        ),
                      );
                    },
                    child: Text(
                      "VIEW DAY",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStepGoalCard(
                theme,
                colorScheme,
                dayNumber,
                stepGoal,
                isCompleted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child:
              dayExercises.isEmpty
                  ? Center(
                    child: Text(
                      "No exercises available",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                  : exercises.isEmpty &&
                      dayExercises.every(
                        (e) => e['exerciseId'].toString().contains('rest'),
                      )
                  ? _buildRestDayMessage(theme, colorScheme)
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dayExercises.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final config = dayExercises[index];
                      final exercise = exercises.firstWhere(
                        (e) => e.id == config['exerciseId'],
                        orElse:
                            () => Exercise(
                              id: config['exerciseId'],
                              name: "Unknown Exercise",
                              instructions: "",
                              muscleGroups: [],
                              injuryRisks: [],
                              category: "",
                            ),
                      );
                      return _buildExerciseCard(
                        context,
                        theme,
                        colorScheme,
                        exercise,
                        config,
                        dayNumber,
                        isCompleted,
                      );
                    },
                  ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepGoalCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int dayNumber,
    int stepGoal,
    bool isCompleted,
  ) {
    return Card(
      elevation: 1,
      color:
          isCompleted
              ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
              : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_walk,
              color:
                  isCompleted
                      ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                      : colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Steps: $stepGoal",
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isCompleted
                        ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                        : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayMessage(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.self_improvement,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            "Rest Day: Recharge and Conquer Tomorrow!",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Exercise exercise,
    Map<String, dynamic> config,
    int dayNumber,
    bool isCompleted,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        navState?.setDetailScreen(
          ExerciseDetailScreen(
            exercise: exercise,
            workout: workout,
            dayNumber: null,
          ),
        );
      },
      child: Card(
        color:
            isCompleted
                ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                : colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Stack(
          children: [
            SizedBox(
              width: 180,
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      exercise.image ?? '',
                      width: 180,
                      height: 110,
                      fit: BoxFit.cover,
                      color: isCompleted ? Colors.grey : null,
                      colorBlendMode: isCompleted ? BlendMode.saturation : null,
                      errorBuilder:
                          (_, __, ___) => _buildPlaceholderImage(
                            colorScheme: colorScheme,
                            height: 110,
                          ),
                      loadingBuilder:
                          (context, child, loadingProgress) =>
                              loadingProgress == null
                                  ? child
                                  : _buildPlaceholderImage(
                                    colorScheme: colorScheme,
                                    height: 110,
                                  ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  isCompleted
                                      ? colorScheme.onSurface.withAlpha(
                                        (255 * 0.6).round(),
                                      )
                                      : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (exercise.name.toLowerCase() != "rest")
                            Text(
                              "${config['sets']} sets • ${config['reps']} reps",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isCompleted
                                        ? colorScheme.onSurface.withAlpha(
                                          (255 * 0.6).round(),
                                        )
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Tooltip(
                message: 'Replace Exercise',
                child: IconButton(
                  icon: Icon(
                    Icons.swap_horiz,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () => _handleReplace(context, exercise.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage({
    required ColorScheme colorScheme,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        size: 40,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
