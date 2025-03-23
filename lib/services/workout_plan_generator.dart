import '../models/workout_program.dart';
import '../data/workout_data.dart';
import '../data/user_data.dart';

WorkoutProgram? generatePersonalizedWorkoutPlan() {
  if (currentUser == null) return null;

  final String userLevel = currentUser!.experienceLevel ?? "Beginner";
  final int frequency = currentUser!.workoutFrequency ?? 3;

  // Find a matching program
  final match = workoutPrograms.firstWhere(
    (program) => program.level.toLowerCase() == userLevel.toLowerCase(),
    orElse: () => workoutPrograms.first,
  );

  // Filter exercises by frequency
  final filteredExercises =
      match.exercises.where((ex) => ex.day <= frequency).toList();

  return WorkoutProgram(
    title: "${match.title} (Personalized)",
    image: match.image,
    days: frequency,
    level: match.level,
    description:
        "Customized for your goal, experience, and weekly schedule. Based on ${match.title}.",
    exercises: filteredExercises,
  );
}
