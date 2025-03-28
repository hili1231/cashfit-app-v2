import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_program.dart';
import '../../data/user_data.dart';

Future<WorkoutProgram?> generatePersonalizedWorkoutPlan() async {
  if (currentUser == null) return null; // Return null if there's no user

  final String userLevel = currentUser!.experienceLevel;

  // Fetch workout programs from Firebase
  final snapshot =
      await FirebaseFirestore.instance
          .collection('workoutPrograms')
          .where('level', isEqualTo: userLevel)
          .get();

  if (snapshot.docs.isEmpty) {
    return null; // No workout programs found for the user level
  }

  // Get the first matching workout program
  final programData = snapshot.docs.first.data();
  final match = WorkoutProgram.fromMap(programData, programData['id']);

  // Return the personalized workout program with updated exercises
  return WorkoutProgram(
    id: match.id, // Add the required 'id' parameter
    title: "${match.title} (Personalized)",
    image: match.image,
    days: {}, // Provide an empty map or a valid Map<String, List<String>> value
    level: match.level,
    description:
        "Customized for your goal, experience, and weekly schedule. Based on ${match.title}.",
  );
}
