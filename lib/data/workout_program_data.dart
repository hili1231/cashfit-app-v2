import '../models/workout_program.dart';

final workoutProgramExample = WorkoutProgram(
  id: '1', // Add an ID here for the example program (this can be any string or a unique identifier)
  title: "5-Day Muscle Gain Split",
  image: "assets/images/muscle_gain_split.jpg",
  level: "Intermediate",
  description: "A targeted program focusing on muscle growth.",
  days: {
    "1": [
      'incline_barbell_press_standard',
      'flat_dumbbell_press_standard',
      'decline_bench_press_standard',
    ],
    "2": [
      'front_dumbbell_raise_standard',
      'lateral_raise_standard',
      'reverse_pec_deck_fly_standard',
    ],
    "3": [
      'incline_dumbbell_curl_standard',
      'preacher_curl_standard',
      'hammer_curl_standard',
    ],
    "4": [
      'overhead_dumbbell_extension_standard',
      'tricep_pushdown_rope_standard',
      'close_grip_bench_press_standard',
    ],
    "5": [
      'incline_barbell_press_standard',
      'incline_dumbbell_curl_standard',
      'overhead_dumbbell_extension_standard',
    ],
  },
);
