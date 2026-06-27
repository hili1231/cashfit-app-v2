import '../models/exercise.dart';

final List<Exercise> exerciseLibrary = [
  Exercise(
    id: 'smith_machine_incline_bench_press',
    name: "Incline Smith Machine Bench Press",
    instructions:
        "Step 1: Set the bench to a 30-45 degree incline under the Smith Machine.\nStep 2: Grip the bar slightly wider than shoulder-width apart.\nStep 3: Unrack the bar and slowly lower it towards your upper chest.\nStep 4: Press the bar upward explosively while keeping your core tight.",
    videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-man-doing-bench-press-exercise-42867-large.mp4",
    image: "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80",
    muscleGroups: ["Chest", "Shoulders", "Triceps"],
    injuryRisks: ["Shoulder"],
    category: "Gym",
  ),
  Exercise(
    id: 'bodyweight_pushups',
    name: "Push-Ups",
    instructions:
        "Step 1: Place hands slightly wider than shoulder-width apart in a high plank position.\nStep 2: Lower your chest toward the floor until your elbows form a 90-degree angle.\nStep 3: Push through your palms to return to starting position.",
    videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-man-doing-push-ups-in-a-gym-42868-large.mp4",
    image: "https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=600&q=80",
    muscleGroups: ["Chest", "Core", "Triceps"],
    injuryRisks: ["Wrist"],
    category: "Bodyweight",
  ),
  Exercise(
    id: 'dumbbell_goblet_squat',
    name: "Dumbbell Goblet Squat",
    instructions:
        "Step 1: Hold a dumbbell vertically against your chest with both hands.\nStep 2: Stand with feet shoulder-width apart, toes pointed slightly outward.\nStep 3: Lower your hips down and back until thighs are parallel to the floor.\nStep 4: Drive through your heels to return to standing.",
    videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-young-man-doing-squats-in-a-gym-42869-large.mp4",
    image: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=80",
    muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
    injuryRisks: ["Knee", "Lower Back"],
    category: "Dumbbell",
  ),
  Exercise(
    id: 'lat_pulldown',
    name: "Cable Lat Pulldown",
    instructions:
        "Step 1: Sit at lat pulldown machine and adjust thigh pad securely.\nStep 2: Grasp bar with wide overhand grip.\nStep 3: Lean back slightly and pull bar down toward upper chest while squeezing shoulder blades.\nStep 4: Slowly return bar upward with control.",
    videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-man-doing-weight-training-in-a-gym-42870-large.mp4",
    image: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=600&q=80",
    muscleGroups: ["Lats", "Biceps", "Upper Back"],
    injuryRisks: ["Shoulder"],
    category: "Gym",
  ),
  Exercise(
    id: 'plank_hold',
    name: "Core Plank Hold",
    instructions:
        "Step 1: Place forearms on ground with elbows directly under shoulders.\nStep 2: Extend legs back and balance on toes, forming a straight line from head to heels.\nStep 3: Engage abdominal muscles and hold for designated duration without letting hips sag.",
    videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-woman-doing-plank-exercise-in-gym-42871-large.mp4",
    image: "https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=600&q=80",
    muscleGroups: ["Abs", "Core", "Lower Back"],
    injuryRisks: ["Lower Back"],
    category: "Bodyweight",
  ),
];
