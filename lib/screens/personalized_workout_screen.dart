import 'package:flutter/material.dart';
import 'workout_detail_screen.dart';
import '../services/workout_plan_generator.dart';

class PersonalizedWorkoutScreen extends StatelessWidget {
  const PersonalizedWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personalizedPlan = generatePersonalizedWorkoutPlan();

    if (personalizedPlan == null) {
      return const Center(
        child: Text("Please complete your profile to generate a plan."),
      );
    }

    // Simply reuse your WorkoutDetailScreen!
    return WorkoutDetailScreen(workout: personalizedPlan);
  }
}
