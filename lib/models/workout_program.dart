import 'exercise.dart'; // ✅ Import the Exercise model

class WorkoutProgram {
  final String title;
  final String image;
  final int days;
  final String level;
  final String description;
  final List<Exercise> exercises;

  WorkoutProgram({
    required this.title,
    required this.image,
    required this.days,
    required this.level,
    required this.description,
    required this.exercises,
  });
}
