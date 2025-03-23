import '../models/workout_program.dart';
import '../models/exercise.dart';

List<WorkoutProgram> workoutPrograms = [
  WorkoutProgram(
    title: "Full Body",
    image: "assets/images/beginner_full_body.jpg",
    days: 3,
    level: "Beginner",
    description: "A 3-day full-body beginner workout plan to build strength.",
    exercises: [
      // Day 1
      Exercise(
        name: "Push-ups",
        image: "assets/images/pushups.jpg",
        sets: 3,
        reps: 12,
        instructions:
            "Keep your body straight and lower yourself until elbows are at 90 degrees.",
        day: 1,
      ),
      Exercise(
        name: "Squats",
        image: "assets/images/squats.jpg",
        sets: 3,
        reps: 15,
        instructions:
            "Stand with feet shoulder-width apart and lower yourself down slowly.",
        day: 1,
      ),

      // Day 2
      Exercise(
        name: "Lunges",
        image: "assets/images/lunges.jpg",
        sets: 3,
        reps: 12,
        instructions:
            "Step forward with one leg and lower hips until both knees are bent.",
        day: 2,
      ),
      Exercise(
        name: "Plank",
        image: "assets/images/plank.jpg",
        sets: 3,
        reps: 30,
        instructions:
            "Keep your core tight and body straight. Hold for 30 seconds each set.",
        day: 2,
      ),

      // Day 3
      Exercise(
        name: "Burpees",
        image: "assets/images/burpees.jpg",
        sets: 3,
        reps: 10,
        instructions:
            "Start in a squat, kick feet back into push-up position, and return to squat then jump.",
        day: 3,
      ),
      Exercise(
        name: "Mountain Climbers",
        image: "assets/images/mountain_climbers.jpg",
        sets: 3,
        reps: 20,
        instructions:
            "Bring knees toward your chest one at a time, keeping your core tight.",
        day: 3,
      ),
    ],
  ),
  WorkoutProgram(
    title: "Strength Training",
    image: "assets/images/intermediate_strength.jpg",
    days: 4,
    level: "Intermediate",
    description: "A 4-day strength training program for intermediate lifters.",
    exercises: [
      // Day 1
      Exercise(
        name: "Deadlifts",
        image: "assets/images/deadlifts.jpg",
        sets: 4,
        reps: 10,
        instructions:
            "Keep your back straight and lift using your legs and core.",
        day: 1,
      ),
      Exercise(
        name: "Bench Press",
        image: "assets/images/bench_press.jpg",
        sets: 4,
        reps: 8,
        instructions:
            "Lower the bar slowly to your chest and press up with control.",
        day: 1,
      ),

      // Day 2
      Exercise(
        name: "Overhead Press",
        image: "assets/images/overhead_press.jpg",
        sets: 4,
        reps: 8,
        instructions:
            "Keep core tight and press the bar overhead, locking out elbows.",
        day: 2,
      ),
      Exercise(
        name: "Bent-Over Row",
        image: "assets/images/bent_over_row.jpg",
        sets: 4,
        reps: 10,
        instructions:
            "Hinge at the waist and pull the bar toward your abdomen.",
        day: 2,
      ),

      // Day 3
      Exercise(
        name: "Squats",
        image: "assets/images/squats.jpg",
        sets: 4,
        reps: 10,
        instructions: "Keep your chest up and push through heels when rising.",
        day: 3,
      ),
      Exercise(
        name: "Pull-ups",
        image: "assets/images/pullups.jpg",
        sets: 3,
        reps: 8,
        instructions:
            "Pull your body up until chin is over the bar, then lower slowly.",
        day: 3,
      ),

      // Day 4
      Exercise(
        name: "Farmer's Walk",
        image: "assets/images/farmers_walk.jpg",
        sets: 3,
        reps: 30,
        instructions:
            "Hold weights at sides and walk 30 steps, keeping core braced.",
        day: 4,
      ),
      Exercise(
        name: "Lateral Raises",
        image: "assets/images/lateral_raises.jpg",
        sets: 3,
        reps: 12,
        instructions:
            "Raise dumbbells to shoulder height with slight bend in elbows.",
        day: 4,
      ),
    ],
  ),
];
