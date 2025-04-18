import 'package:cashfit/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../nav_screen.dart';

class DayDetailScreen extends StatelessWidget {
  final int dayNumber;
  final List<Map<String, dynamic>> dayExercises;
  final WorkoutProgram workout;

  const DayDetailScreen({
    super.key,
    required this.dayNumber,
    required this.dayExercises,
    required this.workout,
  });

  Future<List<Exercise>> fetchExercises() async {
    if (dayExercises.isEmpty) return [];
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
                  'DAY $dayNumber'.toUpperCase(),
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
                        workout.image,
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
                  workout.description,
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
                      if (dayExercises.isNotEmpty &&
                          dayExercises.every(
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
                          itemCount: dayExercises.length,
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
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80),
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
              "Step Goal for Day $dayNumber",
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
            workout: workout,
            dayNumber: dayNumber,
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
