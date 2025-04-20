import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/active_workout_program.dart';
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
  DateTime? lastWorkoutCompletionDate;
  DateTime? lastMealPlanCompletionDate;
  DateTime? lastStepGoalCompletionDate;
  DateTime? lastWeightUpdateDate;
  List<String> completedOneOffIds;
  DateTime? lastAdWatchedTimestamp;
  Map<String, dynamic> claimedRewards; // Map to track reward claims

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
    this.lastWorkoutCompletionDate,
    this.lastMealPlanCompletionDate,
    this.lastStepGoalCompletionDate,
    this.lastWeightUpdateDate,
    this.completedOneOffIds = const [],
    this.lastAdWatchedTimestamp,
    this.claimedRewards = const {},
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
      'premiumExpiryDate':
          premiumExpiryDate != null
              ? Timestamp.fromDate(premiumExpiryDate!)
              : null,
      'autoRenew': autoRenew,
      'activeWorkoutPrograms':
          activeWorkoutPrograms.map((p) => p.toMap()).toList(),
      'activeDietPlans': activeDietPlans.map((d) => d.toMap()).toList(),
      'joinedChallenges': joinedChallenges,
      'joinedSideHustles': joinedSideHustles,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'streak': streak,
      'points': points,
      'badges': badges,
      'workoutHistory': workoutHistory,
      'mealHistory': mealHistory,
      'theme': theme,
      'notifications': notifications,
      'language': language,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'referrer': referrer,
      'balance': balance,
      'hydration': hydration,
      'dietaryRestrictions': dietaryRestrictions,
      'workoutFocus': workoutFocus,
      'workoutDuration': workoutDuration,
      'intensity': intensity,
      'availableDays': availableDays,
      'mealFrequency': mealFrequency,
      'mealTimes': mealTimes,
      'maxPushUps': maxPushUps,
      'maxPullUps': maxPullUps,
      'mileRunTime': mileRunTime,
      'medicalConditions': medicalConditions,
      'preferredWorkoutTimes': preferredWorkoutTimes,
      'challengeCheckIns': challengeCheckIns,
      'activeChallengeId': activeChallengeId,
      'challengeProgress': challengeProgress,
      'dailyStepTarget': dailyStepTarget,
      'stepTargetHistory': stepTargetHistory,
      'dailyCalorieTarget': dailyCalorieTarget,
      'dailyProteinTarget': dailyProteinTarget,
      'dailyCarbsTarget': dailyCarbsTarget,
      'dailyFatTarget': dailyFatTarget,
      'macroIntakeHistory': macroIntakeHistory,
      'preferredWorkoutStyle': preferredWorkoutStyle,
      'isBanned': isBanned,
      'notificationsEnabled': notificationsEnabled,
      'dailyReminderTime': dailyReminderTime,
      'weeklyReminderTime': weeklyReminderTime,
      'fcmToken': fcmToken,
      'lastCheckIn':
          lastCheckIn != null ? Timestamp.fromDate(lastCheckIn!) : null,
      'dailyAdsWatched': dailyAdsWatched,
      'lastAdsWatchedDate':
          lastAdsWatchedDate != null
              ? Timestamp.fromDate(lastAdsWatchedDate!)
              : null,
      'hasBuiltPlans': hasBuiltPlans,
      'hasClaimedBuildPlansReward': hasClaimedBuildPlansReward,
      'checkInStreak': checkInStreak,
      'lastWorkoutCompletionDate':
          lastWorkoutCompletionDate != null
              ? Timestamp.fromDate(lastWorkoutCompletionDate!)
              : null,
      'lastMealPlanCompletionDate':
          lastMealPlanCompletionDate != null
              ? Timestamp.fromDate(lastMealPlanCompletionDate!)
              : null,
      'lastStepGoalCompletionDate':
          lastStepGoalCompletionDate != null
              ? Timestamp.fromDate(lastStepGoalCompletionDate!)
              : null,
      'lastWeightUpdateDate':
          lastWeightUpdateDate != null
              ? Timestamp.fromDate(lastWeightUpdateDate!)
              : null,
      'completedOneOffIds': completedOneOffIds,
      'lastAdWatchedTimestamp':
          lastAdWatchedTimestamp != null
              ? Timestamp.fromDate(lastAdWatchedTimestamp!)
              : null,
      'claimedRewards': claimedRewards, // Serialize claimedRewards
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? expiryDate =
        map['premiumExpiryDate'] != null
            ? (map['premiumExpiryDate'] is Timestamp
                ? (map['premiumExpiryDate'] as Timestamp).toDate()
                : DateTime.tryParse(map['premiumExpiryDate'] as String))
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
              ?.map((e) => ActiveWorkoutProgram.fromMap(e))
              .toList() ??
          [],
      activeDietPlans:
          (map['activeDietPlans'] as List<dynamic>?)
              ?.map((e) => ActiveDietPlan.fromMap(e))
              .toList() ??
          [],
      joinedChallenges: List<String>.from(map['joinedChallenges'] ?? []),
      joinedSideHustles: List<String>.from(map['joinedSideHustles'] ?? []),
      lastLogin:
          map['lastLogin'] != null
              ? (map['lastLogin'] is Timestamp
                  ? (map['lastLogin'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastLogin'] as String))
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
                  : DateTime.tryParse(map['createdAt'] as String))
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
                  : DateTime.tryParse(map['lastCheckIn'] as String))
              : null,
      dailyAdsWatched: map['dailyAdsWatched'] ?? 0,
      lastAdsWatchedDate:
          map['lastAdsWatchedDate'] != null
              ? (map['lastAdsWatchedDate'] is Timestamp
                  ? (map['lastAdsWatchedDate'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastAdsWatchedDate'] as String))
              : null,
      hasBuiltPlans: map['hasBuiltPlans'] ?? false,
      hasClaimedBuildPlansReward: map['hasClaimedBuildPlansReward'] ?? false,
      checkInStreak: map['checkInStreak'] ?? 0,
      lastWorkoutCompletionDate:
          map['lastWorkoutCompletionDate'] != null
              ? (map['lastWorkoutCompletionDate'] is Timestamp
                  ? (map['lastWorkoutCompletionDate'] as Timestamp).toDate()
                  : DateTime.tryParse(
                    map['lastWorkoutCompletionDate'] as String,
                  ))
              : null,
      lastMealPlanCompletionDate:
          map['lastMealPlanCompletionDate'] != null
              ? (map['lastMealPlanCompletionDate'] is Timestamp
                  ? (map['lastMealPlanCompletionDate'] as Timestamp).toDate()
                  : DateTime.tryParse(
                    map['lastMealPlanCompletionDate'] as String,
                  ))
              : null,
      lastStepGoalCompletionDate:
          map['lastStepGoalCompletionDate'] != null
              ? (map['lastStepGoalCompletionDate'] is Timestamp
                  ? (map['lastStepGoalCompletionDate'] as Timestamp).toDate()
                  : DateTime.tryParse(
                    map['lastStepGoalCompletionDate'] as String,
                  ))
              : null,
      lastWeightUpdateDate:
          map['lastWeightUpdateDate'] != null
              ? (map['lastWeightUpdateDate'] is Timestamp
                  ? (map['lastWeightUpdateDate'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastWeightUpdateDate'] as String))
              : null,
      completedOneOffIds: List<String>.from(map['completedOneOffIds'] ?? []),
      lastAdWatchedTimestamp:
          map['lastAdWatchedTimestamp'] != null
              ? (map['lastAdWatchedTimestamp'] is Timestamp
                  ? (map['lastAdWatchedTimestamp'] as Timestamp).toDate()
                  : DateTime.tryParse(map['lastAdWatchedTimestamp'] as String))
              : null,
      claimedRewards: Map<String, dynamic>.from(map['claimedRewards'] ?? {}),
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
