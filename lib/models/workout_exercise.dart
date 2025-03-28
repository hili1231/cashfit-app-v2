import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final int sets;
  final int reps;
  Exercise? exercise; // This will hold the fetched Exercise object

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.exercise, // Optional, can be null if not fetched
  });

  // Fetch the Exercise from Firestore and return a Future
  Future<Exercise?> fetchExercise() async {
    final exerciseSnapshot =
        await FirebaseFirestore.instance
            .collection('exercises')
            .doc(exerciseId)
            .get();

    if (exerciseSnapshot.exists) {
      return Exercise.fromMap(exerciseSnapshot.data()!);
    }
    return null; // Return null if the exercise doesn't exist
  }

  Map<String, dynamic> toMap() {
    return {'exerciseId': exerciseId, 'sets': sets, 'reps': reps};
  }

  factory WorkoutExercise.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutExercise(
      id: id,
      exerciseId: map['exerciseId'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
    );
  }

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    int? sets,
    int? reps,
    Exercise? exercise,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      exercise: exercise ?? this.exercise,
    );
  }
}
