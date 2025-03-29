import '../models/exercise.dart';

final List<Exercise> exerciseLibrary = [
  Exercise(
    id: 'incline_barbell_press',
    name: "Incline Barbell Press",
    instructions:
        "Lie on an incline bench with feet planted. Grip the bar slightly wider than your shoulders. Lower it toward your upper chest, then press upward, focusing on your upper chest and shoulders.",
    videoUrl: null,
    image: "assets/images/incline_barbell_press.jpg",
    muscleGroups: ["Upper Chest", "Shoulders", "Arms"],
    injuryRisks: ["Shoulders"],
    category: "Gym",
  ),
  Exercise(
    id: 'flat_dumbbell_press',
    name: "Flat Dumbbell Press",
    instructions:
        "Lie on a flat bench with dumbbells at chest level. Press the weights upward until your arms are fully extended, then lower them slowly.",
    videoUrl: null,
    image: "assets/images/flat_dumbbell_press.jpg",
    muscleGroups: ["Chest", "Arms"],
    injuryRisks: ["Shoulders"],
    category: "Gym",
  ),
  Exercise(
    id: 'decline_bench_press',
    name: "Decline Bench Press",
    instructions:
        "Lie on a decline bench with a barbell. Grip the bar slightly wider than shoulder-width. Lower it to your lower chest, then press upward.",
    videoUrl: null,
    image: "assets/images/decline_bench_press.jpg",
    muscleGroups: ["Lower Chest", "Arms"],
    injuryRisks: ["Shoulders"],
    category: "Gym",
  ),
  Exercise(
    id: 'front_dumbbell_raise',
    name: "Front Dumbbell Raise",
    instructions:
        "Stand with dumbbells at your sides. Lift the weights in front of you to shoulder height with a slight bend in the elbows, then lower slowly.",
    videoUrl: null,
    image: "assets/images/front_dumbbell_raise.jpg",
    muscleGroups: ["Shoulders"],
    injuryRisks: ["Shoulders"],
    category: "Dumbbells",
  ),
  Exercise(
    id: 'lateral_raise',
    name: "Lateral Raise",
    instructions:
        "Stand with dumbbells at your sides, palms facing inward. Raise your arms out to shoulder height, pause, then lower slowly.",
    videoUrl: null,
    image: "assets/images/lateral_raise.jpg",
    muscleGroups: ["Side Delts"],
    injuryRisks: ["Shoulders"],
    category: "Dumbbells",
  ),
  Exercise(
    id: 'reverse_pec_deck_fly',
    name: "Reverse Pec Deck Fly",
    instructions:
        "Sit at a pec deck machine facing the pads. With a slight bend in your elbows, pull the pads outward, squeezing your shoulder blades together, then return slowly.",
    videoUrl: null,
    image: "assets/images/reverse_pec_deck_fly.jpg",
    muscleGroups: ["Rear Delts", "Upper Back"],
    injuryRisks: ["Shoulders"],
    category: "Gym",
  ),
  Exercise(
    id: 'incline_dumbbell_curl',
    name: "Incline Dumbbell Curl",
    instructions:
        "Sit on an incline bench with your arms hanging straight. Curl the dumbbells upward while keeping your elbows fixed, then lower slowly.",
    videoUrl: null,
    image: "assets/images/incline_dumbbell_curl.jpg",
    muscleGroups: ["Biceps"],
    injuryRisks: ["Elbows"],
    category: "Dumbbells",
  ),
  Exercise(
    id: 'preacher_curl',
    name: "Preacher Curl",
    instructions:
        "Sit at a preacher bench and rest your arms on the pad. Curl the weight upward, squeeze your biceps, then lower it back down slowly.",
    videoUrl: null,
    image: "assets/images/preacher_curl.jpg",
    muscleGroups: ["Biceps"],
    injuryRisks: ["Elbows"],
    category: "Gym",
  ),
  Exercise(
    id: 'hammer_curl',
    name: "Hammer Curl",
    instructions:
        "Stand holding dumbbells with your palms facing inward. Curl the weights upward while keeping your wrists neutral, then lower slowly.",
    videoUrl: null,
    image: "assets/images/hammer_curl.jpg",
    muscleGroups: ["Biceps", "Forearms"],
    injuryRisks: ["Elbows"],
    category: "Dumbbells",
  ),
  Exercise(
    id: 'overhead_dumbbell_extension',
    name: "Overhead Dumbbell Extension",
    instructions:
        "Stand or sit while holding a dumbbell with both hands overhead. Lower the weight behind your head by bending your elbows, then extend your arms to lift it back up.",
    videoUrl: null,
    image: "assets/images/overhead_dumbbell_extension.jpg",
    muscleGroups: ["Triceps"],
    injuryRisks: ["Shoulders"],
    category: "Dumbbells",
  ),
  Exercise(
    id: 'tricep_pushdown_rope',
    name: "Tricep Pushdown (Rope)",
    instructions:
        "Stand at a cable machine with a rope attachment. With elbows pinned to your sides, push the rope downward until your arms are fully extended, then return slowly.",
    videoUrl: null,
    image: "assets/images/tricep_pushdown_rope.jpg",
    muscleGroups: ["Triceps"],
    injuryRisks: ["Elbows"],
    category: "Gym",
  ),
  Exercise(
    id: 'close_grip_bench_press',
    name: "Close-Grip Bench Press",
    instructions:
        "Lie on a flat bench with a barbell. Grip the bar with your hands closer than shoulder-width apart. Lower the bar to your chest and then press upward, focusing on your triceps.",
    videoUrl: null,
    image: "assets/images/close_grip_bench_press.jpg",
    muscleGroups: ["Chest", "Triceps"],
    injuryRisks: ["Shoulders"],
    category: "Gym",
  ),
];
