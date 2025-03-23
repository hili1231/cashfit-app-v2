import '../models/user.dart';

/// Holds the current logged-in user (null if not logged in)
User? currentUser;

/// Mock user data (used for development or prefill)
final User mockUser = User(
  id: "1",
  name: "Jordan Lee",
  email: "jordan.lee@example.com",
  avatar: "assets/images/avatar.png",
  workoutsCompleted: 42,
  mealsTracked: 29,

  // Questionnaire mock data
  gender: "Male",
  age: "28",
  height: "178",
  weight: "75",
  activityLevel: "Moderately Active",
  dietGoal: "Build Muscle",
  dietPreference: "Balanced",
  workoutGoal: "Build Muscle",
  experienceLevel: "Intermediate",
  trainingStyle: "Gym",
  availableEquipment: ["Dumbbells", "Resistance Bands", "Barbells"],
  injuryHistory: ["Shoulder"],
  workoutFrequency: 5,
);

/// Returns true if a user is currently logged in
bool get isLoggedIn => currentUser != null;
