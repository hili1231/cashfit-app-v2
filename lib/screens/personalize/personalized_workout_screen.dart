import 'package:flutter/material.dart';
import '../../models/workout_program.dart';
import '../workouts/workout_detail_screen.dart';
import '../../services/workout_plan_generator.dart';

class PersonalizedWorkoutScreen extends StatelessWidget {
  const PersonalizedWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Material 3 background color
      body: FutureBuilder<WorkoutProgram?>(
        future: generatePersonalizedWorkoutPlan(context: context, totalDays: 7, workoutFrequency: 3, availableDays: [], preferredWorkoutTimes: []),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary, // Material 3 color
              ),
            );
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                "Please complete your profile to generate a plan.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant, // Material 3 color
                  fontSize: 16,
                ),
              ),
            );
          } else {
            return WorkoutDetailScreen(workout: snapshot.data!);
          }
        },
      ),
    );
  }
}
