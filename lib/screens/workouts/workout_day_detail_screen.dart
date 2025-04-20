import 'package:cashfit/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../nav_screen.dart';

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
  bool _isWorkoutCompletedToday = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWorkoutCompletion();
  }

  Future<void> _checkWorkoutCompletion() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      final now = DateTime.now();
      final lastCompletion =
          userProvider.currentUser!.lastWorkoutCompletionDate;
      setState(() {
        _isWorkoutCompletedToday =
            lastCompletion != null && isSameDay(lastCompletion, now);
      });
    }
  }

  Future<List<Exercise>> fetchExercises() async {
    if (widget.dayExercises.isEmpty) return [];
    final exerciseIds =
        widget.dayExercises.map((e) => e['exerciseId'] as String).toList();
    final snapshot =
        await FirebaseFirestore.instance
            .collection('exercises')
            .where(FieldPath.documentId, whereIn: exerciseIds)
            .get();
    return snapshot.docs
        .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<int> fetchStepGoal(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      return userData['dailyStepTarget'] as int? ?? 10000;
    }
    return 10000;
  }

  Future<void> _finishWorkout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      if (userProvider.currentUser != null) {
        final now = DateTime.now();
        if (userProvider.currentUser!.lastWorkoutCompletionDate == null ||
            !isSameDay(
              userProvider.currentUser!.lastWorkoutCompletionDate!,
              now,
            )) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .update({
                'lastWorkoutCompletionDate': FieldValue.serverTimestamp(),
                'workoutsCompleted': FieldValue.increment(1),
              });

          await userProvider.loadUserData(userProvider.firebaseUser!.uid);

          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.primary,
              content: Text(
                "Workout completed! Return to Earn Points to claim your reward.",
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

          setState(() {
            _isWorkoutCompletedToday = true;
          });
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.error,
              content: Text(
                "Workout already completed today!",
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
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to complete workout: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.firebaseUser?.uid ?? 'currentUserId';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                FutureBuilder<int>(
                  future: fetchStepGoal(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final stepGoal = snapshot.data ?? 10000;
                    return _buildStepGoalCard(theme, colorScheme, stepGoal);
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Exercise>>(
                  future: fetchExercises(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      if (widget.dayExercises.isNotEmpty &&
                          widget.dayExercises.every(
                            (e) => e['exerciseId'].toString().contains('rest'),
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
                        if (widget.dayExercises.isNotEmpty &&
                            !widget.dayExercises.every(
                              (e) =>
                                  e['exerciseId'].toString().contains('rest'),
                            ))
                          Align(
                            alignment: Alignment.center,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    _isWorkoutCompletedToday
                                        ? colorScheme.onSurfaceVariant
                                            .withOpacity(0.5)
                                        : colorScheme.primary,
                                foregroundColor:
                                    _isWorkoutCompletedToday
                                        ? colorScheme.onSurface.withOpacity(0.6)
                                        : colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed:
                                  _isWorkoutCompletedToday || _isLoading
                                      ? null
                                      : () => _finishWorkout(context),
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        _isWorkoutCompletedToday
                                            ? "Completed Today"
                                            : "Workout Completed",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepGoalCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int stepGoal,
  ) {
    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Step Goal for Day ${widget.dayNumber}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$stepGoal steps",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
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
