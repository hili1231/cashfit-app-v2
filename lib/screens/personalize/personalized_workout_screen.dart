import 'package:cashfit/models/workout_program.dart';
import 'package:flutter/material.dart';
import '../workouts/workout_detail_screen.dart';
import '../../services/workout_plan_generator.dart';

class PersonalizedWorkoutScreen extends StatelessWidget {
  const PersonalizedWorkoutScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkoutProgram?>(
      future: generatePersonalizedWorkoutPlan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Text("Please complete your profile to generate a plan."),
          );
        } else {
          return WorkoutDetailScreen(workout: snapshot.data!);
        }
      },
    );
  }
}
