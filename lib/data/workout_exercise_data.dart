import '../models/workout_exercise.dart';
import 'exercise_data.dart';

// Helper function to get exercise ID by name
String exerciseIdByName(String name) =>
    exerciseLibrary.firstWhere((ex) => ex.name == name).id;

final List<WorkoutExercise> workoutExerciseLibrary = [
  WorkoutExercise(
    id: 'incline_barbell_press_standard',
    exerciseId: exerciseIdByName("Incline Barbell Press"),
    sets: 4,
    reps: "10",
  ),
  WorkoutExercise(
    id: 'flat_dumbbell_press_standard',
    exerciseId: exerciseIdByName("Flat Dumbbell Press"),
    sets: 3,
    reps: "10",
  ),
  WorkoutExercise(
    id: 'decline_bench_press_standard',
    exerciseId: exerciseIdByName("Decline Bench Press"),
    sets: 3,
    reps: "10",
  ),
  WorkoutExercise(
    id: 'front_dumbbell_raise_standard',
    exerciseId: exerciseIdByName("Front Dumbbell Raise"),
    sets: 3,
    reps: "12",
  ),
  WorkoutExercise(
    id: 'lateral_raise_standard',
    exerciseId: exerciseIdByName("Lateral Raise"),
    sets: 4,
    reps: "15",
  ),
  WorkoutExercise(
    id: 'reverse_pec_deck_fly_standard',
    exerciseId: exerciseIdByName("Reverse Pec Deck Fly"),
    sets: 3,
    reps: "12",
  ),
  WorkoutExercise(
    id: 'incline_dumbbell_curl_standard',
    exerciseId: exerciseIdByName("Incline Dumbbell Curl"),
    sets: 3,
    reps: "10",
  ),
  WorkoutExercise(
    id: 'preacher_curl_standard',
    exerciseId: exerciseIdByName("Preacher Curl"),
    sets: 3,
    reps: "12",
  ),
  WorkoutExercise(
    id: 'hammer_curl_standard',
    exerciseId: exerciseIdByName("Hammer Curl"),
    sets: 4,
    reps: "10",
  ),
  WorkoutExercise(
    id: 'overhead_dumbbell_extension_standard',
    exerciseId: exerciseIdByName("Overhead Dumbbell Extension"),
    sets: 3,
    reps: "12",
  ),
  WorkoutExercise(
    id: 'tricep_pushdown_rope_standard',
    exerciseId: exerciseIdByName("Tricep Pushdown (Rope)"),
    sets: 3,
    reps: "15",
  ),
  WorkoutExercise(
    id: 'close_grip_bench_press_standard',
    exerciseId: exerciseIdByName("Close-Grip Bench Press"),
    sets: 3,
    reps: "10",
  ),
];
