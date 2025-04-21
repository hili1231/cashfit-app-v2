import 'package:cashfit/providers/user_provider.dart';
import 'package:cashfit/screens/workouts/workout_repository.dart';
import 'package:cashfit/widgets/step_counter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';
import '../nav_screen.dart';
import 'exercise_detail_screen.dart';

enum DayStatus { notDone, doneToday, doneEarlier }

class DayDetailScreen extends StatefulWidget {
  final int dayNumber;
  final List<Map<String, dynamic>> dayExercises;
  final WorkoutProgram workout;

  const DayDetailScreen({
    super.key,
    required this.dayNumber,
    required this.dayExercises,
    required this.workout,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleDayCompleted(BuildContext context, bool markDone) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final repo = context.read<WorkoutRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = userProvider.firebaseUser!.uid;
      if (!markDone &&
          !await repo
              .streamActiveWorkout(userId, widget.workout.id)
              .first
              .then((value) => value != null)) {
        throw Exception('Cannot undo completion for inactive workout');
      }

      if (markDone) {
        await repo.setActiveWorkout(
          userId,
          widget.workout.id,
          widget.dayNumber,
        );
      }

      await repo.toggleDayCompleted(
        userId,
        widget.workout.id,
        widget.dayNumber,
        markDone,
        widget.workout.days.length,
      );

      await userProvider.loadUserData(userId, silent: true);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.primary,
            content: Text(
              markDone
                  ? "Workout completed! Return to Earn Points to claim your reward."
                  : "Day completion undone.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to ${markDone ? 'complete' : 'undo'} workout: $e';
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              'Error: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.firebaseUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Please log in to view this page.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<ActiveWorkoutProgram?>(
      stream: context.read<WorkoutRepository>().streamActiveWorkout(
        userId,
        widget.workout.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading workout: ${snapshot.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: Text(
                      'Retry',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activeProgram = snapshot.data;

        final isWorkoutActive = activeProgram != null;
        final completedDays = activeProgram?.completedDays ?? [];
        final isWorkoutCompletedToday =
            completedDays.contains(widget.dayNumber) &&
            activeProgram?.lastCompletion != null &&
            DateUtils.isSameDay(activeProgram!.lastCompletion, DateTime.now());
        final dayStatus =
            isWorkoutCompletedToday
                ? DayStatus.doneToday
                : completedDays.contains(widget.dayNumber)
                ? DayStatus.doneEarlier
                : DayStatus.notDone;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY ${widget.dayNumber}'.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.workout.image,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildPlaceholderImage(
                                  colorScheme: colorScheme,
                                  height: 220,
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholderImage(
                                colorScheme: colorScheme,
                                height: 220,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      widget.workout.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StepCounterWidget(),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    FutureBuilder<List<Exercise>>(
                      future: context.read<WorkoutRepository>().fetchExercises(
                        widget.dayExercises
                            .map((e) => e['exerciseId'] as String)
                            .toList(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          if (widget.dayExercises.isNotEmpty &&
                              widget.dayExercises.every(
                                (e) =>
                                    e['exerciseId'].toString().contains('rest'),
                              )) {
                            return _buildRestDayMessage(theme, colorScheme);
                          }
                          return Center(
                            child: Text(
                              "No exercises available for this day",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        final exercises = snapshot.data!;
                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.dayExercises.length,
                              itemBuilder: (context, index) {
                                final config = widget.dayExercises[index];
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
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                    if (widget.dayExercises.isNotEmpty)
                      Align(
                        alignment: Alignment.center,
                        child: DayCompletionButton(
                          status: dayStatus,
                          isLoading: _isLoading,
                          onPressed:
                              isWorkoutActive
                                  ? (bool markDone) =>
                                      _toggleDayCompleted(context, markDone)
                                  : (bool _) =>
                                      _toggleDayCompleted(context, true),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          const SizedBox(height: 10),
          Text(
            "Take a well-deserved rest day!",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Recharge for your next challenge.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        navState?.setDetailScreen(
          ExerciseDetailScreen(
            exercise: exercise,
            workout: widget.workout,
            dayNumber: widget.dayNumber,
          ),
        );
      },
      child: Card(
        elevation: 1,
        color: colorScheme.surfaceContainer,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Image.network(
                exercise.image ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => _buildPlaceholderImage(
                      colorScheme: colorScheme,
                      height: 100,
                    ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage(
                    colorScheme: colorScheme,
                    height: 100,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (exercise.name.toLowerCase() != "rest")
                      Text(
                        "${config['sets']} sets • ${config['reps']} reps",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (config['restSeconds'] != null)
                      Text(
                        "Rest: ${config['restSeconds']} sec",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (config['supersetWith'] != null)
                      Text(
                        "Superset with: ${config['supersetWith']}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
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

class DayCompletionButton extends StatelessWidget {
  final DayStatus status;
  final bool isLoading;
  final void Function(bool markDone)? onPressed;

  const DayCompletionButton({
    super.key,
    required this.status,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = status != DayStatus.notDone;
    final buttonText = isDone ? "Undo Completion" : "Workout Completed";
    final buttonColor =
        isDone
            ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
            : colorScheme.primary;
    final textColor =
        isDone
            ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
            : colorScheme.onPrimary;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: isLoading ? null : () => onPressed?.call(!isDone),
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
              : Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
    );
  }
}
