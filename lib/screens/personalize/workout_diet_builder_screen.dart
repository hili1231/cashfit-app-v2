import 'package:cashfit/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../utils/workout_generator.dart';
import '../../utils/diet_generator.dart';
import '../../models/active_diet_plan.dart';
import '../../models/active_workout_program.dart';
import '../../screens/personalize/personalized_plan_screen.dart';
import '../../providers/user_provider.dart';

class WorkoutDietBuilderScreen extends StatefulWidget {
  const WorkoutDietBuilderScreen({super.key});

  @override
  State<WorkoutDietBuilderScreen> createState() =>
      _WorkoutDietBuilderScreenState();
}

class _WorkoutDietBuilderScreenState extends State<WorkoutDietBuilderScreen> {
  String? gender,
      age,
      height,
      weight,
      activity,
      dietGoal,
      dietPreference,
      workoutGoal,
      experience,
      trainingStyle;
  List<String> injuryHistory = [],
      availableEquipment = [],
      workoutFocus = [],
      dietaryRestrictions = [];
  int workoutFrequency = 1;
  String? hydration;
  double workoutDuration = 30;
  String? intensity;
  List<String> availableDays = [];
  int? mealFrequency;
  List<String> mealTimes = [];
  double? maxPushUps, maxPullUps, mileRunTime;
  List<String> medicalConditions = [];
  List<String> preferredWorkoutTimes = [];
  String? programLength;

  bool isGenerating = false;

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // TextEditingControllers for form fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _maxPushUpsController = TextEditingController();
  final TextEditingController _maxPullUpsController = TextEditingController();
  final TextEditingController _mileRunTimeController = TextEditingController();

  // FocusNodes for auto-scrolling to invalid fields
  final Map<String, FocusNode> _focusNodes = {
    'gender': FocusNode(),
    'age': FocusNode(),
    'height': FocusNode(),
    'weight': FocusNode(),
    'activity': FocusNode(),
    'dietGoal': FocusNode(),
    'workoutGoal': FocusNode(),
    'experience': FocusNode(),
    'trainingStyle': FocusNode(),
    'programLength': FocusNode(),
  };

  final List<String> genders = ["Male", "Female", "Other"];
  final List<String> activityLevels = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
  ];
  final List<String> dietGoals = [
    "Lose Fat",
    "Build Muscle",
    "Lose Fat & Build Muscle",
    "Maintain Weight",
  ];
  final List<String> dietPreferences = [
    "Balanced",
    "Vegetarian",
    "Vegan",
    "Keto",
    "Paleo",
    "Nut-Free",
    "High Fiber",
    "Low Fat",
    "Low Sugar",
    "Low Carb",
    "FODMAP Friendly",
    "Gluten-Free",
    "Dairy-Free",
    "High Protein",
    "Mediterranean",
    "Low Glycemic",
    "Pescatarian",
  ];
  final List<String> workoutGoals = [
    "Build Muscle",
    "Lose Fat",
    "Lose Fat & Build Muscle",
    "Improve Endurance",
  ];
  final List<String> experienceLevels = [
    "Beginner",
    "Intermediate",
    "Advanced",
  ];
  final List<String> trainingStyles = ["Gym", "Home", "Bodyweight", "CrossFit"];
  final List<String> injuryOptions = [
    "Knee",
    "Back",
    "Shoulder",
    "Wrist",
    "Ankle",
    "Elbow",
    "Hip",
    "Neck",
    "Foot",
    "Hand",
    "Chest",
  ];
  final List<String> equipmentOptions = [
    "Bodyweight Only",
    "Dumbbells",
    "Barbells",
    "Gym",
    "Kettlebells",
    "Pull-Up Bar",
    "Treadmill",
    "Stationary Bike",
    "Bench",
    "Jump Rope",
    "Medicine Ball",
    "Resistance Bands",
    "TRX Suspension Trainer",
    "Foam Roller",
  ];
  final List<String> hydrationLevels = [
    "1-2 Liters",
    "2-3 Liters",
    "3+ Liters",
  ];
  final List<String> focusAreas = [
    "Abs",
    "Arms",
    "Legs",
    "Chest",
    "Back",
    "Shoulders",
    "Full Body",
  ];
  final List<String> intensityLevels = ["Low", "Moderate", "High"];
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final List<int> mealOptions = [2, 3, 4, 5, 6];
  final List<String> conditionOptions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Arthritis",
  ];
  final List<String> programLengthOptions = [
    "30 Days",
    "60 Days",
    "90 Days",
    "120 Days",
  ];

  @override
  void initState() {
    super.initState();
    // Load programLength from SharedPreferences
    _loadProgramLength();
  }

  Future<void> _loadProgramLength() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      programLength = prefs.getString('programLength');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _maxPushUpsController.dispose();
    _maxPullUpsController.dispose();
    _mileRunTimeController.dispose();
    _focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  Future<void> _storeDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', gender ?? '');
    await prefs.setString('age', age ?? '');
    await prefs.setString('height', height ?? '');
    await prefs.setString('weight', weight ?? '');
    await prefs.setString('activity', activity ?? '');
    await prefs.setString('dietGoal', dietGoal ?? '');
    await prefs.setString('dietPreference', dietPreference ?? '');
    await prefs.setString('workoutGoal', workoutGoal ?? '');
    await prefs.setString('experience', experience ?? '');
    await prefs.setString('trainingStyle', trainingStyle ?? '');
    await prefs.setStringList('availableEquipment', availableEquipment);
    await prefs.setStringList('injuryHistory', injuryHistory);
    await prefs.setInt('workoutFrequency', workoutFrequency);
    await prefs.setString('hydration', hydration ?? '');
    await prefs.setStringList('dietaryRestrictions', dietaryRestrictions);
    await prefs.setStringList('workoutFocus', workoutFocus);
    await prefs.setDouble('workoutDuration', workoutDuration);
    await prefs.setString('intensity', intensity ?? '');
    await prefs.setStringList('availableDays', availableDays);
    await prefs.setInt('mealFrequency', mealFrequency ?? 3);
    await prefs.setStringList('mealTimes', mealTimes);
    await prefs.setDouble('maxPushUps', maxPushUps ?? 0);
    await prefs.setDouble('maxPullUps', maxPullUps ?? 0);
    await prefs.setDouble('mileRunTime', mileRunTime ?? 0);
    await prefs.setStringList('medicalConditions', medicalConditions);
    await prefs.setStringList('preferredWorkoutTimes', preferredWorkoutTimes);
    await prefs.setString('programLength', programLength ?? '');
  }

  Future<void> _saveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      // If currentUser is null, create a minimal AppUser object with the form data
      final newUser = AppUser(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        avatar: user.photoURL ?? '',
        workoutsCompleted: 0,
        mealsTracked: 0,
        gender: gender ?? '',
        age: age ?? '',
        height: height ?? '',
        weight: weight ?? '',
        activityLevel: activity ?? '',
        dietGoal: dietGoal ?? '',
        dietPreference: dietPreference ?? '',
        workoutGoal: workoutGoal ?? '',
        experienceLevel: experience ?? '',
        trainingStyle: trainingStyle ?? '',
        availableEquipment: availableEquipment,
        injuryHistory: injuryHistory,
        workoutFrequency: workoutFrequency,
        allergies: [],
        isAdmin: false,
        isPremium: false,
        activeWorkoutPrograms: [],
        activeDietPlans: [],
        joinedSideHustles: [],
        lastLogin: DateTime.now(),
        streak: 0,
        points: 0,
        badges: [],
        workoutHistory: [],
        mealHistory: [],
        theme: 'light',
        notifications: true,
        language: 'en',
        createdAt: DateTime.now(),
        referrer: null,
        balance: 0,
        hydration: hydration,
        dietaryRestrictions: dietaryRestrictions,
        workoutFocus: workoutFocus,
        workoutDuration: workoutDuration,
        intensity: intensity,
        availableDays: availableDays,
        mealFrequency: mealFrequency,
        mealTimes: mealTimes,
        maxPushUps: maxPushUps,
        maxPullUps: maxPullUps,
        mileRunTime: mileRunTime,
        medicalConditions: medicalConditions,
        preferredWorkoutTimes: preferredWorkoutTimes,
        dailyStepTarget: 0,
        stepTargetHistory: [],
        dailyCalorieTarget: 0,
        dailyProteinTarget: 0,
        dailyCarbsTarget: 0,
        dailyFatTarget: 0,
        macroIntakeHistory: [],
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(newUser.toMap(), SetOptions(merge: true));

      // Update UserProvider with the new user data
      userProvider.updateUser(newUser);
      return;
    }

    // Update existing user with form data
    final updatedUser = AppUser(
      id: user.uid,
      name: currentUser.name,
      email: currentUser.email,
      avatar: currentUser.avatar,
      workoutsCompleted: currentUser.workoutsCompleted,
      mealsTracked: currentUser.mealsTracked,
      gender: gender ?? currentUser.gender,
      age: age ?? currentUser.age,
      height: height ?? currentUser.height,
      weight: weight ?? currentUser.weight,
      activityLevel: activity ?? currentUser.activityLevel,
      dietGoal: dietGoal ?? currentUser.dietGoal,
      dietPreference: dietPreference ?? currentUser.dietPreference,
      workoutGoal: workoutGoal ?? currentUser.workoutGoal,
      experienceLevel: experience ?? currentUser.experienceLevel,
      trainingStyle: trainingStyle ?? currentUser.trainingStyle,
      availableEquipment:
          availableEquipment.isNotEmpty
              ? availableEquipment
              : currentUser.availableEquipment,
      injuryHistory:
          injuryHistory.isNotEmpty ? injuryHistory : currentUser.injuryHistory,
      workoutFrequency: workoutFrequency,
      allergies: currentUser.allergies,
      isAdmin: currentUser.isAdmin,
      isPremium: currentUser.isPremium,
      activeWorkoutPrograms: currentUser.activeWorkoutPrograms,
      activeDietPlans: currentUser.activeDietPlans,
      joinedSideHustles: currentUser.joinedSideHustles,
      lastLogin: currentUser.lastLogin,
      streak: currentUser.streak,
      points: currentUser.points,
      badges: currentUser.badges,
      workoutHistory: currentUser.workoutHistory,
      mealHistory: currentUser.mealHistory,
      theme: currentUser.theme,
      notifications: currentUser.notifications,
      language: currentUser.language,
      createdAt: currentUser.createdAt,
      referrer: currentUser.referrer,
      balance: currentUser.balance,
      hydration: hydration ?? currentUser.hydration,
      dietaryRestrictions:
          dietaryRestrictions.isNotEmpty
              ? dietaryRestrictions
              : currentUser.dietaryRestrictions,
      workoutFocus:
          workoutFocus.isNotEmpty ? workoutFocus : currentUser.workoutFocus,
      workoutDuration:
          workoutDuration != 30 ? workoutDuration : currentUser.workoutDuration,
      intensity: intensity ?? currentUser.intensity,
      availableDays:
          availableDays.isNotEmpty ? availableDays : currentUser.availableDays,
      mealFrequency: mealFrequency ?? currentUser.mealFrequency,
      mealTimes: mealTimes.isNotEmpty ? mealTimes : currentUser.mealTimes,
      maxPushUps: maxPushUps ?? currentUser.maxPushUps,
      maxPullUps: maxPullUps ?? currentUser.maxPullUps,
      mileRunTime: mileRunTime ?? currentUser.mileRunTime,
      medicalConditions:
          medicalConditions.isNotEmpty
              ? medicalConditions
              : currentUser.medicalConditions,
      preferredWorkoutTimes:
          preferredWorkoutTimes.isNotEmpty
              ? preferredWorkoutTimes
              : currentUser.preferredWorkoutTimes,
      dailyStepTarget: currentUser.dailyStepTarget,
      stepTargetHistory: currentUser.stepTargetHistory,
      dailyCalorieTarget: currentUser.dailyCalorieTarget,
      dailyProteinTarget: currentUser.dailyProteinTarget,
      dailyCarbsTarget: currentUser.dailyCarbsTarget,
      dailyFatTarget: currentUser.dailyFatTarget,
      macroIntakeHistory: currentUser.macroIntakeHistory,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updatedUser.toMap(), SetOptions(merge: true));

    // Update UserProvider with the new user data
    userProvider.updateUser(updatedUser);
  }

  // Add a method to validate user inputs
  bool _validateInputs() {
    if (gender == null || gender!.isEmpty) {
      _showError("Please select your gender.");
      return false;
    }
    if (age == null || int.tryParse(age!) == null) {
      _showError("Please enter a valid age.");
      return false;
    }
    if (height == null || double.tryParse(height!) == null) {
      _showError("Please enter a valid height.");
      return false;
    }
    if (weight == null || double.tryParse(weight!) == null) {
      _showError("Please enter a valid weight.");
      return false;
    }
    if (workoutFrequency <= 0) {
      _showError("Workout frequency must be at least 1 day per week.");
      return false;
    }
    if (workoutDuration <= 0) {
      _showError("Workout duration must be greater than 0 minutes.");
      return false;
    }
    return true;
  }

  // Add a helper method to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Update the generatePersonalizedPlans method to include validation
  Future<void> generatePersonalizedPlans() async {
    if (!_validateInputs()) return;

    if (programLength == null) {
      throw const FormatException("Program length must be selected.");
    }

    int totalDays = int.parse(programLength!.split(' ')[0]);

    try {
      // Ensure preferredWorkoutTimes matches workoutFrequency
      if (preferredWorkoutTimes.length < workoutFrequency) {
        for (int i = preferredWorkoutTimes.length; i < workoutFrequency; i++) {
          preferredWorkoutTimes.add("12:00");
        }
      }

      // Ensure mealTimes matches mealFrequency
      if (mealTimes.length < (mealFrequency ?? 3)) {
        for (int i = mealTimes.length; i < (mealFrequency ?? 3); i++) {
          mealTimes.add("12:00");
        }
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw const AuthenticationException("User not authenticated.");
      }

      // Retrieve form data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Remove unused local variables
      // Removed: localWorkoutDuration, localAvailableDays, localPreferredWorkoutTimes, localIntensity, localMealFrequency, localMealTimes, localMedicalConditions, localMaxPushUps, localMaxPullUps, localMileRunTime

      // Use relevant variables directly from SharedPreferences or class properties
      final localTrainingStyle =
          prefs.getString('trainingStyle') ?? trainingStyle ?? "Gym";
      final localExperienceLevel =
          prefs.getString('experience') ?? experience ?? "Beginner";
      final localWorkoutGoal =
          prefs.getString('workoutGoal') ?? workoutGoal ?? "Build Muscle";
      final localDietGoal =
          prefs.getString('dietGoal') ?? dietGoal ?? "Maintain Weight";
      final localDietPreference =
          prefs.getString('dietPreference') ?? dietPreference ?? "Balanced";

      // Update the AppUser with the form data
      final updatedUserWithFormData = AppUser(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        avatar: currentUser.avatar,
        workoutsCompleted: currentUser.workoutsCompleted,
        mealsTracked: currentUser.mealsTracked,
        gender: gender ?? currentUser.gender,
        age: age ?? currentUser.age,
        height: height ?? currentUser.height,
        weight: weight ?? currentUser.weight,
        weightHistory: currentUser.weightHistory,
        activityLevel: activity ?? currentUser.activityLevel,
        dietGoal: localDietGoal,
        dietPreference: localDietPreference,
        workoutGoal: localWorkoutGoal,
        experienceLevel: localExperienceLevel,
        trainingStyle: localTrainingStyle,
        availableEquipment:
            availableEquipment.isNotEmpty
                ? availableEquipment
                : currentUser.availableEquipment,
        injuryHistory:
            injuryHistory.isNotEmpty
                ? injuryHistory
                : currentUser.injuryHistory,
        workoutFrequency: workoutFrequency,
        allergies: currentUser.allergies,
        isAdmin: currentUser.isAdmin,
        isPremium: currentUser.isPremium,
        activeWorkoutPrograms: currentUser.activeWorkoutPrograms,
        activeDietPlans: currentUser.activeDietPlans,
        joinedSideHustles: currentUser.joinedSideHustles,
        lastLogin: currentUser.lastLogin,
        streak: currentUser.streak,
        points: currentUser.points,
        badges: currentUser.badges,
        workoutHistory: currentUser.workoutHistory,
        mealHistory: currentUser.mealHistory,
        theme: currentUser.theme,
        notifications: currentUser.notifications,
        language: currentUser.language,
        createdAt: currentUser.createdAt,
        referrer: currentUser.referrer,
        balance: currentUser.balance,
        hydration: hydration ?? currentUser.hydration,
        dietaryRestrictions:
            dietaryRestrictions.isNotEmpty
                ? dietaryRestrictions
                : currentUser.dietaryRestrictions,
        workoutFocus:
            workoutFocus.isNotEmpty ? workoutFocus : currentUser.workoutFocus,
        workoutDuration: workoutDuration,
        intensity: intensity ?? currentUser.intensity,
        availableDays:
            availableDays.isNotEmpty
                ? availableDays
                : currentUser.availableDays,
        mealFrequency: mealFrequency ?? currentUser.mealFrequency,
        mealTimes: mealTimes.isNotEmpty ? mealTimes : currentUser.mealTimes,
        maxPushUps: maxPushUps ?? currentUser.maxPushUps,
        maxPullUps: maxPullUps ?? currentUser.maxPullUps,
        mileRunTime: mileRunTime ?? currentUser.mileRunTime,
        medicalConditions:
            medicalConditions.isNotEmpty
                ? medicalConditions
                : currentUser.medicalConditions,
        preferredWorkoutTimes:
            preferredWorkoutTimes.isNotEmpty
                ? preferredWorkoutTimes
                : currentUser.preferredWorkoutTimes,
        dailyStepTarget: currentUser.dailyStepTarget,
        stepTargetHistory: currentUser.stepTargetHistory,
        dailyCalorieTarget: currentUser.dailyCalorieTarget,
        dailyProteinTarget: currentUser.dailyProteinTarget,
        dailyCarbsTarget: currentUser.dailyCarbsTarget,
        dailyFatTarget: currentUser.dailyFatTarget,
        macroIntakeHistory: currentUser.macroIntakeHistory,
      );

      // Save the updated user data to Firestore
      debugPrint('Saving form data to Firestore before plan generation...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .set(updatedUserWithFormData.toMap(), SetOptions(merge: true));

      // Update UserProvider with the updated user data
      userProvider.updateUser(updatedUserWithFormData);
      debugPrint(
        'User data updated: trainingStyle=${updatedUserWithFormData.trainingStyle}, experienceLevel=${updatedUserWithFormData.experienceLevel}',
      );

      // Use the updated user for plan generation
      final userForPlanGeneration = updatedUserWithFormData;

      // Guard the use of 'BuildContext' with a 'mounted' check
      if (!mounted) return;

      // Generate Workout Program using userForPlanGeneration
      debugPrint('Starting workout program generation...');
      final workoutProgram = await WorkoutGenerator.generateWorkoutProgram(
        user: userForPlanGeneration,
        totalDays: totalDays,
        workoutFrequency: workoutFrequency,
        availableDays: availableDays,
        preferredWorkoutTimes: preferredWorkoutTimes,
        context: context,
      );
      debugPrint('Workout program generated: ${workoutProgram.id}');

      // Guard the use of 'BuildContext' with a 'mounted' check
      if (!mounted) return;

      // Generate Diet Plan using userForPlanGeneration
      debugPrint('Starting diet plan generation...');
      final mealPlan = await DietGenerator.generateDietPlan(
        user: userForPlanGeneration,
        totalDays: totalDays,
        mealFrequency: mealFrequency ?? 3,
        mealTimes: mealTimes,
        context: context,
      );
      debugPrint('Diet plan generated: ${mealPlan.id}');

      // Prepare the new active workout and diet plans
      final newActiveWorkoutProgram = ActiveWorkoutProgram(
        workoutProgramId: workoutProgram.id,
        startDate: DateTime.now(),
        currentDay: 1,
        isCompleted: false,
        completedDays: const [],
      );

      final newActiveDietPlan = ActiveDietPlan(
        dietPlanId: mealPlan.id,
        startDate: DateTime.now(),
        currentDay: 1,
        isCompleted: false,
        completedDays: const [],
      );

      // Update existing plans to set isActive: false
      List<ActiveWorkoutProgram> updatedWorkoutPrograms =
          userForPlanGeneration.activeWorkoutPrograms.map((program) {
            return ActiveWorkoutProgram(
              workoutProgramId: program.workoutProgramId,
              startDate: program.startDate,
              currentDay: program.currentDay,
              isCompleted: program.isCompleted,
              completedDays: program.completedDays,
            );
          }).toList();

      List<ActiveDietPlan> updatedDietPlans =
          userForPlanGeneration.activeDietPlans.map((plan) {
            return ActiveDietPlan(
              dietPlanId: plan.dietPlanId,
              startDate: plan.startDate,
              currentDay: plan.currentDay,
              isCompleted: plan.isCompleted,
              completedDays: plan.completedDays,
            );
          }).toList();

      // Append the new plans
      updatedWorkoutPrograms.add(newActiveWorkoutProgram);
      updatedDietPlans.add(newActiveDietPlan);

      // Update user's active programs and plans in Firestore
      final finalUpdatedUser = AppUser(
        id: userForPlanGeneration.id,
        name: userForPlanGeneration.name,
        email: userForPlanGeneration.email,
        avatar: userForPlanGeneration.avatar,
        workoutsCompleted: userForPlanGeneration.workoutsCompleted,
        mealsTracked: userForPlanGeneration.mealsTracked,
        gender: userForPlanGeneration.gender,
        age: userForPlanGeneration.age,
        height: userForPlanGeneration.height,
        weight: userForPlanGeneration.weight,
        weightHistory: userForPlanGeneration.weightHistory,
        activityLevel: userForPlanGeneration.activityLevel,
        dietGoal: userForPlanGeneration.dietGoal,
        dietPreference: userForPlanGeneration.dietPreference,
        workoutGoal: userForPlanGeneration.workoutGoal,
        experienceLevel: userForPlanGeneration.experienceLevel,
        trainingStyle: userForPlanGeneration.trainingStyle,
        availableEquipment: userForPlanGeneration.availableEquipment,
        injuryHistory: userForPlanGeneration.injuryHistory,
        workoutFrequency: userForPlanGeneration.workoutFrequency,
        allergies: userForPlanGeneration.allergies,
        isAdmin: userForPlanGeneration.isAdmin,
        isPremium: userForPlanGeneration.isPremium,
        premiumExpiryDate: userForPlanGeneration.premiumExpiryDate,
        autoRenew: userForPlanGeneration.autoRenew,
        activeWorkoutPrograms: updatedWorkoutPrograms, // Updated list
        activeDietPlans: updatedDietPlans, // Updated list
        joinedSideHustles: userForPlanGeneration.joinedSideHustles,
        lastLogin: userForPlanGeneration.lastLogin,
        streak: userForPlanGeneration.streak,
        points: userForPlanGeneration.points,
        badges: userForPlanGeneration.badges,
        workoutHistory: userForPlanGeneration.workoutHistory,
        mealHistory: userForPlanGeneration.mealHistory,
        theme: userForPlanGeneration.theme,
        notifications: userForPlanGeneration.notifications,
        language: userForPlanGeneration.language,
        createdAt: userForPlanGeneration.createdAt,
        referrer: userForPlanGeneration.referrer,
        balance: userForPlanGeneration.balance,
        hydration: userForPlanGeneration.hydration,
        dietaryRestrictions: userForPlanGeneration.dietaryRestrictions,
        workoutFocus: userForPlanGeneration.workoutFocus,
        workoutDuration: userForPlanGeneration.workoutDuration,
        intensity: userForPlanGeneration.intensity,
        availableDays: userForPlanGeneration.availableDays,
        mealFrequency: userForPlanGeneration.mealFrequency,
        mealTimes: userForPlanGeneration.mealTimes,
        maxPushUps: userForPlanGeneration.maxPushUps,
        maxPullUps: userForPlanGeneration.maxPullUps,
        mileRunTime: userForPlanGeneration.mileRunTime,
        medicalConditions: userForPlanGeneration.medicalConditions,
        preferredWorkoutTimes: userForPlanGeneration.preferredWorkoutTimes,
        dailyStepTarget: userForPlanGeneration.dailyStepTarget,
        stepTargetHistory: userForPlanGeneration.stepTargetHistory,
        dailyCalorieTarget: userForPlanGeneration.dailyCalorieTarget,
        dailyProteinTarget: userForPlanGeneration.dailyProteinTarget,
        dailyCarbsTarget: userForPlanGeneration.dailyCarbsTarget,
        dailyFatTarget: userForPlanGeneration.dailyFatTarget,
        macroIntakeHistory: userForPlanGeneration.macroIntakeHistory,
        preferredWorkoutStyle: userForPlanGeneration.preferredWorkoutStyle,
        isBanned: userForPlanGeneration.isBanned,
        notificationsEnabled: userForPlanGeneration.notificationsEnabled,
        dailyReminderTime: userForPlanGeneration.dailyReminderTime,
        weeklyReminderTime: userForPlanGeneration.weeklyReminderTime,
        fcmToken: userForPlanGeneration.fcmToken,
        lastCheckIn: userForPlanGeneration.lastCheckIn,
        dailyAdsWatched: userForPlanGeneration.dailyAdsWatched,
        lastAdsWatchedDate: userForPlanGeneration.lastAdsWatchedDate,
        hasBuiltPlans: userForPlanGeneration.hasBuiltPlans,
        hasClaimedBuildPlansReward:
            userForPlanGeneration.hasClaimedBuildPlansReward,
        checkInStreak: userForPlanGeneration.checkInStreak,
        lastWorkoutCompletionDate:
            userForPlanGeneration.lastWorkoutCompletionDate,
        lastMealPlanCompletionDate:
            userForPlanGeneration.lastMealPlanCompletionDate,
        lastStepGoalCompletionDate:
            userForPlanGeneration.lastStepGoalCompletionDate,
        lastWeightUpdateDate: userForPlanGeneration.lastWeightUpdateDate,
        completedOneOffIds: userForPlanGeneration.completedOneOffIds,
        completedDailyIds: userForPlanGeneration.completedDailyIds,
        lastAdWatchedTimestamp: userForPlanGeneration.lastAdWatchedTimestamp,
        claimedRewards: userForPlanGeneration.claimedRewards,
      );

      // Update Firestore with the updated active programs and plans
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .set(finalUpdatedUser.toMap(), SetOptions(merge: true));

      // Update UserProvider
      userProvider.updateUser(finalUpdatedUser);

      // Store the generated plans in SharedPreferences for PersonalizedPlanScreen
      await prefs.setString('generatedWorkoutId', workoutProgram.id);
      await prefs.setString('generatedMealPlanId', mealPlan.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Personalized Workout & Meal Plans Created!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } on FormatException catch (e) {
      throw FormatException(e.message);
    } on AuthenticationException catch (e) {
      throw AuthenticationException(e.message);
    } on FirebaseException catch (e) {
      throw Exception("Firestore error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  double calculateBMR() {
    double wt = double.tryParse(weight ?? '70') ?? 70;
    double ht = double.tryParse(height ?? '170') ?? 170;
    int ag = int.tryParse(age ?? '30') ?? 30;
    if (gender == "Male") {
      return 10 * wt + 6.25 * ht - 5 * ag + 5;
    } else {
      return 9.99 * wt + 6.25 * ht - 4.92 * ag - 161;
    }
  }

  double calculateTDEE(double bmr) {
    const activityMultipliers = {
      "Sedentary": 1.2,
      "Lightly Active": 1.375,
      "Moderately Active": 1.55,
      "Very Active": 1.725,
    };
    return bmr * (activityMultipliers[activity] ?? 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if the user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Please log in to continue.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text("Log In"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle("Your Profile", theme, colorScheme),
                  _dropdown(
                    "Gender",
                    genders,
                    gender,
                    (v) => setState(() {
                      gender = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['gender'],
                  ),
                  _textInput(
                    "Age",
                    _ageController,
                    (v) => setState(() {
                      age = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['age'],
                  ),
                  _textInput(
                    "Height (cm)",
                    _heightController,
                    (v) => setState(() {
                      height = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['height'],
                  ),
                  _textInput(
                    "Weight (kg)",
                    _weightController,
                    (v) => setState(() {
                      weight = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['weight'],
                  ),
                  _dropdown(
                    "Activity Level",
                    activityLevels,
                    activity,
                    (v) => setState(() {
                      activity = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['activity'],
                  ),
                  _textInput(
                    "Max Push-Ups (Optional)",
                    _maxPushUpsController,
                    (v) => setState(() {
                      maxPushUps = double.tryParse(v);
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),
                  _textInput(
                    "Max Pull-Ups (Optional)",
                    _maxPullUpsController,
                    (v) => setState(() {
                      maxPullUps = double.tryParse(v);
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),
                  _textInput(
                    "Mile Run Time (min) (Optional)",
                    _mileRunTimeController,
                    (v) => setState(() {
                      mileRunTime = double.tryParse(v);
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),

                  _sectionTitle("Diet Goals", theme, colorScheme),
                  _dropdown(
                    "Diet Goal",
                    dietGoals,
                    dietGoal,
                    (v) => setState(() {
                      dietGoal = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['dietGoal'],
                  ),
                  _dropdown(
                    "Diet Preference (Optional)",
                    dietPreferences,
                    dietPreference,
                    (v) => setState(() {
                      dietPreference = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),
                  _dropdown(
                    "Meals Per Day (Optional)",
                    mealOptions.map((e) => e.toString()).toList(),
                    mealFrequency?.toString(),
                    (v) => setState(() {
                      mealFrequency = int.tryParse(v ?? '3');
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),
                  _sectionTitle("Meal Times (Optional)", theme, colorScheme),
                  _buildTimePickerInput(
                    isMealTime: true,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),

                  _sectionTitle("Workout Goals", theme, colorScheme),
                  _dropdown(
                    "Workout Goal",
                    workoutGoals,
                    workoutGoal,
                    (v) => setState(() {
                      workoutGoal = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['workoutGoal'],
                  ),
                  _dropdown(
                    "Experience Level",
                    experienceLevels,
                    experience,
                    (v) => setState(() {
                      experience = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['experience'],
                  ),
                  _dropdown(
                    "Training Style",
                    trainingStyles,
                    trainingStyle,
                    (v) => setState(() {
                      trainingStyle = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['trainingStyle'],
                  ),
                  _dropdown(
                    "Intensity (Optional)",
                    intensityLevels,
                    intensity,
                    (v) => setState(() {
                      intensity = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),
                  _dropdown(
                    "Length of Program",
                    programLengthOptions,
                    programLength,
                    (val) => setState(() {
                      programLength = val;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    focusNode: _focusNodes['programLength'],
                  ),
                  _slider(
                    "Workout Frequency (days/week)",
                    workoutFrequency.toDouble(),
                    (val) => setState(() {
                      workoutFrequency = val.toInt();
                      _formKey.currentState?.validate();
                    }),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _slider(
                    "Workout Duration (minutes) (Optional)",
                    workoutDuration,
                    (val) => setState(() {
                      workoutDuration = val;
                      _formKey.currentState?.validate();
                    }),
                    min: 15,
                    max: 120,
                    divisions: 21,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _sectionTitle(
                    "Available Days (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _chipGrid(daysOfWeek, availableDays, theme, colorScheme),
                  _sectionTitle(
                    "Preferred Workout Times (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _buildTimePickerInput(
                    isMealTime: false,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),

                  _sectionTitle(
                    "Available Equipment (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _chipGrid(
                    equipmentOptions,
                    availableEquipment,
                    theme,
                    colorScheme,
                  ),
                  _sectionTitle(
                    "Injury History (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _chipGrid(injuryOptions, injuryHistory, theme, colorScheme),
                  _sectionTitle(
                    "Medical Conditions (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _chipGrid(
                    conditionOptions,
                    medicalConditions,
                    theme,
                    colorScheme,
                  ),

                  _sectionTitle("Hydration (Optional)", theme, colorScheme),
                  _dropdown(
                    "Hydration",
                    hydrationLevels,
                    hydration,
                    (v) => setState(() {
                      hydration = v;
                      _formKey.currentState?.validate();
                    }),
                    theme,
                    colorScheme,
                    isOptional: true,
                  ),

                  _sectionTitle(
                    "Dietary Restrictions (Optional)",
                    theme,
                    colorScheme,
                  ),
                  _chipGrid(
                    ["Nuts", "Dairy", "Gluten", "Soy", "Eggs"],
                    dietaryRestrictions,
                    theme,
                    colorScheme,
                  ),

                  _sectionTitle("Workout Focus (Optional)", theme, colorScheme),
                  _chipGrid(focusAreas, workoutFocus, theme, colorScheme),

                  const SizedBox(height: 25),
                  _buildGenerateButton(context, theme, colorScheme),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme, ColorScheme colorScheme) {
    String displayTitle = title;
    bool isOptional = title.contains("(Optional)");
    if (isOptional) {
      displayTitle = title.replaceAll("(Optional)", "");
    }
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        displayTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontStyle: isOptional ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isOptional = false,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        focusNode: focusNode,
        value: options.contains(selected) ? selected : null,
        decoration: _inputDecoration(label, theme, colorScheme),
        dropdownColor: colorScheme.surfaceContainer,
        iconEnabledColor: colorScheme.primary,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        items:
            options
                .map(
                  (val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      val,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: (val) {
          if (isOptional) return null;
          return val == null ? 'Please select $label' : null;
        },
      ),
    );
  }

  Widget _textInput(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isOptional = false,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        keyboardType: TextInputType.number,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: _inputDecoration(label, theme, colorScheme),
        validator: (val) {
          if (isOptional) return null;
          if (val == null || val.isEmpty) return 'Enter $label';
          if (label == "Age" &&
              (int.tryParse(val)! < 13 || int.tryParse(val)! > 120)) {
            return 'Enter a valid age (13-120)';
          }
          if ((label == "Height (cm)" &&
                  (double.tryParse(val)! < 100 ||
                      double.tryParse(val)! > 250)) ||
              (label == "Weight (kg)" &&
                  (double.tryParse(val)! < 30 ||
                      double.tryParse(val)! > 300))) {
            return 'Enter a realistic $label';
          }
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double min = 1,
    double max = 7,
    int? divisions,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions ?? ((max - min) ~/ 1),
          label: "${value.round()}",
          activeColor: colorScheme.primary,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Widget _chipGrid(
    List<String> options,
    List<String> selectedList,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 8,
      children:
          options.map((item) {
            final selected = selectedList.contains(item);
            return ChoiceChip(
              label: Text(
                item,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      selected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              selected: selected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainer,
              onSelected:
                  (_) => setState(
                    () =>
                        selected
                            ? selectedList.remove(item)
                            : selectedList.add(item),
                  ),
            );
          }).toList(),
    );
  }

  Widget _buildTimePickerInput({
    required bool isMealTime,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final count = isMealTime ? (mealFrequency ?? 3) : workoutFrequency;
    final timesList = isMealTime ? mealTimes : preferredWorkoutTimes;

    if (timesList.length > count) {
      setState(() {
        timesList.removeRange(count, timesList.length);
      });
    }

    return Column(
      children: List.generate(count, (index) {
        final timeString =
            timesList.length > index ? timesList[index] : "Select Time";
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: colorScheme.primary,
                        onPrimary: colorScheme.onPrimary,
                        surface: colorScheme.surfaceContainer,
                        onSurface: colorScheme.onSurface,
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: colorScheme.surface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final formattedTime =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                setState(() {
                  if (timesList.length <= index) {
                    timesList.add(formattedTime);
                  } else {
                    timesList[index] = formattedTime;
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${isMealTime ? 'Meal' : 'Workout'} ${index + 1} Time: $timeString",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Icon(Icons.access_time, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Helper method to get the current value of a field
  dynamic _getFieldValue(String fieldName) {
    switch (fieldName) {
      case 'gender':
        return gender;
      case 'age':
        return age;
      case 'height':
        return height;
      case 'weight':
        return weight;
      case 'activity':
        return activity;
      case 'dietGoal':
        return dietGoal;
      case 'workoutGoal':
        return workoutGoal;
      case 'experience':
        return experience;
      case 'trainingStyle':
        return trainingStyle;
      case 'programLength':
        return programLength;
      default:
        return null;
    }
  }

  // Helper method to validate a field
  bool _validateField(String fieldName, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return false;
    }
    if (fieldName == 'age') {
      final ageValue = int.tryParse(value);
      return ageValue != null && ageValue >= 13 && ageValue <= 120;
    }
    if (fieldName == 'height') {
      final heightValue = double.tryParse(value);
      return heightValue != null && heightValue >= 100 && heightValue <= 250;
    }
    if (fieldName == 'weight') {
      final weightValue = double.tryParse(value);
      return weightValue != null && weightValue >= 30 && weightValue <= 300;
    }
    return true;
  }

  Widget _buildGenerateButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ElevatedButton(
      style: theme.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.all(colorScheme.primary),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
      ),
      onPressed:
          isGenerating
              ? null
              : () async {
                setState(() {
                  isGenerating = true;
                });

                // Store Navigator and ScaffoldMessenger before async operation
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  // Validate the form
                  if (_formKey.currentState?.validate() ?? false) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor: colorScheme.surface,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Generating Your Plan...",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    );

                    // Save form data to SharedPreferences
                    await _storeDataLocally();
                    // Generate plans using local data
                    await generatePersonalizedPlans();
                    await _saveToFirestore();

                    // Save to Firestore (already handled in generatePersonalizedPlans)

                    if (!mounted) return;
                    navigator.pop(); // Dismiss loading dialog

                    if (!mounted) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => const PersonalizedPlanScreen(),
                      ),
                    );
                  } else {
                    // Collect validation errors for required fields
                    List<String> errors = [];
                    FocusNode? firstInvalidFocusNode;

                    // Check each required field for validation errors
                    _focusNodes.forEach((fieldName, focusNode) {
                      final fieldValue = _getFieldValue(fieldName);
                      final isValid = _validateField(fieldName, fieldValue);
                      if (!isValid) {
                        errors.add(
                          "$fieldName: Please provide a valid $fieldName",
                        );
                        firstInvalidFocusNode ??= focusNode;
                      }
                    });

                    // Scroll to the first invalid field
                    if (firstInvalidFocusNode != null) {
                      final fieldContext = firstInvalidFocusNode!.context;
                      if (fieldContext != null) {
                        final renderBox =
                            fieldContext.findRenderObject() as RenderBox?;
                        final offset = renderBox?.localToGlobal(Offset.zero);
                        if (offset != null) {
                          _scrollController.animateTo(
                            offset.dy - 100, // Adjust for padding
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    }

                    // Show validation errors in a SnackBar
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          errors.isNotEmpty
                              ? "Please fix the following required fields:\n${errors.join('\n')}"
                              : "Please fill in all required fields.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onError,
                          ),
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } on FormatException catch (e) {
                  if (!mounted) return;
                  navigator.pop(); // Dismiss loading dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        e.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } on AuthenticationException catch (e) {
                  if (!mounted) return;
                  navigator.pop(); // Dismiss loading dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        e.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } on FirebaseException catch (e) {
                  if (!mounted) return;
                  navigator.pop(); // Dismiss loading dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        "Database error: ${e.message}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  navigator.pop(); // Dismiss loading dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        "An unexpected error occurred: $e",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      isGenerating = false;
                    });
                  }
                }
              },
      child: Text(
        "Generate My Plan",
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }
}

// Custom exceptions for better error handling
class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
  @override
  String toString() => message;
}
