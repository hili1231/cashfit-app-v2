import 'package:cashfit/models/active_diet_plan.dart';
import 'package:cashfit/models/active_workout_plan.dart';

class AppUser {
  final String id;
  String name;
  String email;
  String avatar;
  int workoutsCompleted;
  int mealsTracked;
  String gender;
  String age;
  String height;
  String weight;
  String activityLevel;
  String dietGoal;
  String dietPreference;
  String workoutGoal;
  String experienceLevel;
  String trainingStyle;
  List<String> availableEquipment;
  List<String> injuryHistory;
  int workoutFrequency;
  List<String> allergies;
  bool isAdmin;
  bool isPremium;

  List<ActiveWorkoutProgram> activeWorkoutPrograms;
  List<ActiveDietPlan> activeDietPlans;

  // ✅ NEW FIELDS
  List<String> joinedChallenges;
  List<String> joinedSideHustles;

  DateTime? lastLogin;
  int? streak;
  int? points;
  List<String>? badges;
  List<String>? workoutHistory;
  List<String>? mealHistory;
  String? theme;
  bool? notifications;
  String? language;
  DateTime? createdAt;
  String? referrer;
  double? balance;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.workoutsCompleted,
    required this.mealsTracked,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.dietGoal,
    required this.dietPreference,
    required this.workoutGoal,
    required this.experienceLevel,
    required this.trainingStyle,
    required this.availableEquipment,
    required this.injuryHistory,
    required this.workoutFrequency,
    required this.allergies,
    required this.isAdmin,
    this.isPremium = false,
    required this.activeWorkoutPrograms,
    required this.activeDietPlans,
    this.joinedChallenges = const [],
    this.joinedSideHustles = const [],
    this.lastLogin,
    this.streak,
    this.points,
    this.badges,
    this.workoutHistory,
    this.mealHistory,
    this.theme,
    this.notifications,
    this.language,
    this.createdAt,
    this.referrer,
    this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'workoutsCompleted': workoutsCompleted,
      'mealsTracked': mealsTracked,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'dietGoal': dietGoal,
      'dietPreference': dietPreference,
      'workoutGoal': workoutGoal,
      'experienceLevel': experienceLevel,
      'trainingStyle': trainingStyle,
      'availableEquipment': availableEquipment,
      'injuryHistory': injuryHistory,
      'workoutFrequency': workoutFrequency,
      'allergies': allergies,
      'isAdmin': isAdmin,
      'isPremium': isPremium,
      'activeWorkoutPrograms':
          activeWorkoutPrograms.map((p) => p.toMap()).toList(),
      'activeDietPlans': activeDietPlans.map((d) => d.toMap()).toList(),
      'joinedChallenges': joinedChallenges,
      'joinedSideHustles': joinedSideHustles,
      if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
      if (streak != null) 'streak': streak,
      if (points != null) 'points': points,
      if (badges != null) 'badges': badges,
      if (workoutHistory != null) 'workoutHistory': workoutHistory,
      if (mealHistory != null) 'mealHistory': mealHistory,
      if (theme != null) 'theme': theme,
      if (notifications != null) 'notifications': notifications,
      if (language != null) 'language': language,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (referrer != null) 'referrer': referrer,
      if (balance != null) 'balance': balance,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'] ?? '',
      workoutsCompleted: map['workoutsCompleted'] ?? 0,
      mealsTracked: map['mealsTracked'] ?? 0,
      gender: map['gender'] ?? '',
      age: map['age'] ?? '',
      height: map['height'] ?? '',
      weight: map['weight'] ?? '',
      activityLevel: map['activityLevel'] ?? '',
      dietGoal: map['dietGoal'] ?? '',
      dietPreference: map['dietPreference'] ?? '',
      workoutGoal: map['workoutGoal'] ?? '',
      experienceLevel: map['experienceLevel'] ?? '',
      trainingStyle: map['trainingStyle'] ?? '',
      availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
      injuryHistory: List<String>.from(map['injuryHistory'] ?? []),
      workoutFrequency: map['workoutFrequency'] ?? 0,
      allergies: List<String>.from(map['allergies'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      isPremium: map['isPremium'] ?? false,
      activeWorkoutPrograms:
          (map['activeWorkoutPrograms'] as List<dynamic>?)
              ?.map(
                (e) => ActiveWorkoutProgram.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      activeDietPlans:
          (map['activeDietPlans'] as List<dynamic>?)
              ?.map((e) => ActiveDietPlan.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      joinedChallenges: List<String>.from(map['joinedChallenges'] ?? []),
      joinedSideHustles: List<String>.from(map['joinedSideHustles'] ?? []),
      lastLogin:
          map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin']) : null,
      streak: map['streak'],
      points: map['points'],
      badges: (map['badges'] as List?)?.cast<String>(),
      workoutHistory: (map['workoutHistory'] as List?)?.cast<String>(),
      mealHistory: (map['mealHistory'] as List?)?.cast<String>(),
      theme: map['theme'],
      notifications: map['notifications'],
      language: map['language'],
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      referrer: map['referrer'],
      balance:
          map['balance'] != null ? (map['balance'] as num).toDouble() : null,
    );
  }
}
