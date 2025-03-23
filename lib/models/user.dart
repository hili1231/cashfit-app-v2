class User {
  final String id;
  String name;
  String email;
  String avatar;
  int workoutsCompleted;
  int mealsTracked;

  // New fields from the questionnaire
  String? gender;
  String? age;
  String? height;
  String? weight;
  String? activityLevel;
  String? dietGoal;
  String? dietPreference;
  String? workoutGoal;
  String? experienceLevel;
  String? trainingStyle;
  List<String>? availableEquipment;
  List<String>? injuryHistory;
  int? workoutFrequency;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.workoutsCompleted,
    required this.mealsTracked,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.dietGoal,
    this.dietPreference,
    this.workoutGoal,
    this.experienceLevel,
    this.trainingStyle,
    this.availableEquipment,
    this.injuryHistory,
    this.workoutFrequency,
  });
}
