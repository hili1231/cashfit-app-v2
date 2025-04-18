import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Timestamp
import 'package:cashfit/models/active_workout_program.dart';
import '../../models/active_diet_plan.dart';

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
  List<Map<String, dynamic>> weightHistory;
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
  DateTime? premiumExpiryDate;
  bool autoRenew;
  List<ActiveWorkoutProgram> activeWorkoutPrograms;
  List<ActiveDietPlan> activeDietPlans;
  List<String> joinedChallenges;
  String? activeChallengeId;
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
  String? hydration;
  List<String> dietaryRestrictions;
  List<String> workoutFocus;
  double workoutDuration;
  String? intensity;
  List<String> availableDays;
  int? mealFrequency;
  List<String>? mealTimes;
  double? maxPushUps;
  double? maxPullUps;
  double? mileRunTime;
  List<String> medicalConditions;
  List<String>? preferredWorkoutTimes;
  List<Map<String, dynamic>> challengeCheckIns;
  int challengeProgress;
  int? dailyStepTarget;
  List<Map<String, dynamic>> stepTargetHistory;
  double? dailyCalorieTarget;
  double? dailyProteinTarget;
  double? dailyCarbsTarget;
  double? dailyFatTarget;
  List<Map<String, dynamic>> macroIntakeHistory;
  String? preferredWorkoutStyle;
  bool isBanned;
  bool notificationsEnabled;
  String? dailyReminderTime;
  String? weeklyReminderTime;
  String? fcmToken;
  DateTime? lastCheckIn;
  int dailyAdsWatched;
  DateTime? lastAdsWatchedDate;
  bool hasBuiltPlans;
  bool hasClaimedBuildPlansReward;
  int checkInStreak;

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
    this.weightHistory = const [],
    required this.activityLevel,
    required this.dietGoal,
    required this.dietPreference,
    required this.workoutGoal,
    required this.experienceLevel,
    required this.trainingStyle,
    required this.availableEquipment,
    required this.injuryHistory,
    this.workoutFrequency = 1,
    required this.allergies,
    required this.isAdmin,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.autoRenew = false,
    required this.activeWorkoutPrograms,
    required this.activeDietPlans,
    this.joinedChallenges = const [],
    this.activeChallengeId,
    this.joinedSideHustles = const [],
    this.lastLogin,
    this.streak = 0,
    this.points = 0,
    this.badges = const [],
    this.workoutHistory,
    this.mealHistory,
    this.theme,
    this.notifications,
    this.language,
    this.createdAt,
    this.referrer,
    this.balance,
    this.hydration,
    this.dietaryRestrictions = const [],
    this.workoutFocus = const [],
    this.workoutDuration = 30.0,
    this.intensity,
    this.availableDays = const [],
    this.mealFrequency = 3,
    this.mealTimes = const [],
    this.maxPushUps,
    this.maxPullUps,
    this.mileRunTime,
    this.medicalConditions = const [],
    this.preferredWorkoutTimes = const [],
    this.challengeCheckIns = const [],
    this.challengeProgress = 0,
    this.dailyStepTarget,
    this.stepTargetHistory = const [],
    this.dailyCalorieTarget,
    this.dailyProteinTarget,
    this.dailyCarbsTarget,
    this.dailyFatTarget,
    this.macroIntakeHistory = const [],
    this.preferredWorkoutStyle,
    this.isBanned = false,
    this.notificationsEnabled = true,
    this.dailyReminderTime = "08:00",
    this.weeklyReminderTime = "09:00",
    this.fcmToken,
    this.lastCheckIn,
    this.dailyAdsWatched = 0,
    this.lastAdsWatchedDate,
    this.hasBuiltPlans = false,
    this.hasClaimedBuildPlansReward = false,
    this.checkInStreak = 0,
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
      'weightHistory': weightHistory,
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
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'autoRenew': autoRenew,
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
      if (hydration != null) 'hydration': hydration,
      'dietaryRestrictions': dietaryRestrictions,
      'workoutFocus': workoutFocus,
      'workoutDuration': workoutDuration,
      if (intensity != null) 'intensity': intensity,
      'availableDays': availableDays,
      if (mealFrequency != null) 'mealFrequency': mealFrequency,
      if (mealTimes != null) 'mealTimes': mealTimes,
      if (maxPushUps != null) 'maxPushUps': maxPushUps,
      if (maxPullUps != null) 'maxPullUps': maxPullUps,
      if (mileRunTime != null) 'mileRunTime': mileRunTime,
      'medicalConditions': medicalConditions,
      if (preferredWorkoutTimes != null)
        'preferredWorkoutTimes': preferredWorkoutTimes,
      'challengeCheckIns': challengeCheckIns,
      if (activeChallengeId != null) 'activeChallengeId': activeChallengeId,
      'challengeProgress': challengeProgress,
      if (dailyStepTarget != null) 'dailyStepTarget': dailyStepTarget,
      'stepTargetHistory': stepTargetHistory,
      if (dailyCalorieTarget != null) 'dailyCalorieTarget': dailyCalorieTarget,
      if (dailyProteinTarget != null) 'dailyProteinTarget': dailyProteinTarget,
      if (dailyCarbsTarget != null) 'dailyCarbsTarget': dailyCarbsTarget,
      if (dailyFatTarget != null) 'dailyFatTarget': dailyFatTarget,
      'macroIntakeHistory': macroIntakeHistory,
      'isBanned': isBanned,
      'notificationsEnabled': notificationsEnabled,
      'dailyReminderTime': dailyReminderTime,
      'weeklyReminderTime': weeklyReminderTime,
      'fcmToken': fcmToken,
      if (preferredWorkoutStyle != null)
        'preferredWorkoutStyle': preferredWorkoutStyle,
      if (lastCheckIn != null) 'lastCheckIn': lastCheckIn!.toIso8601String(),
      'dailyAdsWatched': dailyAdsWatched,
      if (lastAdsWatchedDate != null)
        'lastAdsWatchedDate': lastAdsWatchedDate!.toIso8601String(),
      'hasBuiltPlans': hasBuiltPlans,
      'hasClaimedBuildPlansReward': hasClaimedBuildPlansReward,
      'checkInStreak': checkInStreak,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? expiryDate =
        map['premiumExpiryDate'] != null
            ? (map['premiumExpiryDate'] is Timestamp
                ? (map['premiumExpiryDate'] as Timestamp).toDate()
                : DateTime.tryParse(map['premiumExpiryDate']))
            : null;
    bool isPremium = map['isPremium'] ?? false;
    if (expiryDate != null) {
      isPremium = expiryDate.isAfter(DateTime.now());
    }
    int loadedFrequency = map['workoutFrequency'] ?? 1;
    loadedFrequency = loadedFrequency.clamp(1, 7);

    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      activeChallengeId: map['activeChallengeId'],
      avatar: map['avatar'] ?? '',
      workoutsCompleted: map['workoutsCompleted'] ?? 0,
      mealsTracked: map['mealsTracked'] ?? 0,
      gender: map['gender'] ?? '',
      age: map['age'] ?? '',
      height: map['height'] ?? '',
      weight: map['weight'] ?? '',
      weightHistory: List<Map<String, dynamic>>.from(
        map['weightHistory'] ?? [],
      ),
      activityLevel: map['activityLevel'] ?? '',
      dietGoal: map['dietGoal'] ?? '',
      dietPreference: map['dietPreference'] ?? '',
      workoutGoal: map['workoutGoal'] ?? '',
      experienceLevel: map['experienceLevel'] ?? '',
      trainingStyle: map['trainingStyle'] ?? '',
      availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
      injuryHistory: List<String>.from(map['injuryHistory'] ?? []),
      workoutFrequency: loadedFrequency,
      allergies: List<String>.from(map['allergies'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      isPremium: isPremium,
      premiumExpiryDate: expiryDate,
      autoRenew: map['autoRenew'] ?? false,
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
          map['lastLogin'] != null
              ? (map['lastLogin'] is Timestamp
                  ? (map['lastLogin'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastLogin']))
              : null,
      streak: map['streak'] ?? 0,
      points: map['points'] ?? 0,
      badges: (map['badges'] as List?)?.cast<String>(),
      workoutHistory: (map['workoutHistory'] as List?)?.cast<String>(),
      mealHistory: (map['mealHistory'] as List?)?.cast<String>(),
      theme: map['theme'],
      notifications: map['notifications'],
      language: map['language'],
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] is Timestamp
                  ? (map['createdAt'] as Timestamp).toDate()
                  : DateTime.tryParse(map['createdAt']))
              : null,
      referrer: map['referrer'],
      balance:
          map['balance'] != null ? (map['balance'] as num).toDouble() : null,
      hydration: map['hydration'],
      dietaryRestrictions: List<String>.from(map['dietaryRestrictions'] ?? []),
      workoutFocus: List<String>.from(map['workoutFocus'] ?? []),
      workoutDuration:
          map['workoutDuration'] != null
              ? (map['workoutDuration'] as num).toDouble()
              : 30.0,
      intensity: map['intensity'],
      availableDays: List<String>.from(map['availableDays'] ?? []),
      mealFrequency: map['mealFrequency'] ?? 3,
      mealTimes: List<String>.from(map['mealTimes'] ?? []),
      maxPushUps: map['maxPushUps']?.toDouble(),
      maxPullUps: map['maxPullUps']?.toDouble(),
      mileRunTime: map['mileRunTime']?.toDouble(),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      preferredWorkoutTimes: List<String>.from(
        map['preferredWorkoutTimes'] ?? [],
      ),
      challengeCheckIns: List<Map<String, dynamic>>.from(
        map['challengeCheckIns'] ?? [],
      ),
      challengeProgress: map['challengeProgress'] ?? 0,
      dailyStepTarget: map['dailyStepTarget'],
      stepTargetHistory: List<Map<String, dynamic>>.from(
        map['stepTargetHistory'] ?? [],
      ),
      dailyCalorieTarget: map['dailyCalorieTarget']?.toDouble(),
      dailyProteinTarget: map['dailyProteinTarget']?.toDouble(),
      dailyCarbsTarget: map['dailyCarbsTarget']?.toDouble(),
      dailyFatTarget: map['dailyFatTarget']?.toDouble(),
      macroIntakeHistory: List<Map<String, dynamic>>.from(
        map['macroIntakeHistory'] ?? [],
      ),
      preferredWorkoutStyle: map['preferredWorkoutStyle'],
      isBanned: map['isBanned'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      dailyReminderTime: map['dailyReminderTime'] ?? "08:00",
      weeklyReminderTime: map['weeklyReminderTime'] ?? "09:00",
      fcmToken: map['fcmToken'],
      lastCheckIn:
          map['lastCheckIn'] != null
              ? (map['lastCheckIn'] is Timestamp
                  ? (map['lastCheckIn'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastCheckIn']))
              : null,
      dailyAdsWatched: map['dailyAdsWatched'] ?? 0,
      lastAdsWatchedDate:
          map['lastAdsWatchedDate'] != null
              ? (map['lastAdsWatchedDate'] is Timestamp
                  ? (map['lastAdsWatchedDate'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastAdsWatchedDate']))
              : null,
      hasBuiltPlans: map['hasBuiltPlans'] ?? false,
      hasClaimedBuildPlansReward: map['hasClaimedBuildPlansReward'] ?? false,
      checkInStreak: map['checkInStreak'] ?? 0,
    );
  }

  bool isPremiumActive() {
    if (premiumExpiryDate == null) return false;
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  int daysUntilPremiumExpiry() {
    if (premiumExpiryDate == null) return 0;
    return premiumExpiryDate!.difference(DateTime.now()).inDays;
  }
}
