import 'package:cashfit/utils/workout_generator.dart' as generator;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_program.dart';
import '../../providers/user_provider.dart';

/// Generates a personalized workout plan for the current user by calling WorkoutGenerator.
Future<WorkoutProgram?> generatePersonalizedWorkoutPlan({
  required BuildContext context,
  required int totalDays,
  required int workoutFrequency,
  required List<String> availableDays,
  required List<String> preferredWorkoutTimes,
  Function(double)? onProgress,
}) async {
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      throw Exception("User not found. Please ensure you are logged in.");
    }

    // Validate input parameters
    if (totalDays <= 0 || workoutFrequency <= 0) {
      throw Exception(
        "Total days and workout frequency must be positive integers.",
      );
    }
    if (availableDays.isEmpty) {
      throw Exception("At least one available day must be specified.");
    }

    // Call WorkoutGenerator to generate a fully personalized workout program
    return await generator.WorkoutGenerator.generateWorkoutProgram(
      context: context,
      totalDays: totalDays,
      workoutFrequency: workoutFrequency,
      availableDays: availableDays,
      preferredWorkoutTimes: preferredWorkoutTimes,
      onProgress: onProgress,
      user: user,
    );
  } catch (e) {
    throw Exception("Failed to generate personalized workout plan: $e");
  }
}
