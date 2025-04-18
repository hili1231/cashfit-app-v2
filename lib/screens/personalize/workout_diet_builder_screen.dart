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

  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();

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
    _checkAuthAndLoadUser();
  }

  Future<void> _checkAuthAndLoadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return; // Guard context usage
      setState(() => isLoading = false);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData(user.uid);
    final currentUser = userProvider.currentUser;
    if (currentUser != null) {
      if (!mounted) return; // Guard context usage
      setState(() {
        gender = currentUser.gender;
        age = currentUser.age;
        height = currentUser.height;
        weight = currentUser.weight;
        activity = currentUser.activityLevel;
        dietGoal = currentUser.dietGoal;
        dietPreference = currentUser.dietPreference;
        workoutGoal = currentUser.workoutGoal;
        experience = currentUser.experienceLevel;
        trainingStyle = currentUser.trainingStyle;
        availableEquipment = currentUser.availableEquipment;
        injuryHistory = currentUser.injuryHistory;
        workoutFrequency = (currentUser.workoutFrequency).clamp(1, 7);
        hydration = currentUser.hydration;
        dietaryRestrictions = currentUser.dietaryRestrictions;
        workoutFocus = currentUser.workoutFocus;
        workoutDuration = currentUser.workoutDuration;
        intensity = currentUser.intensity;
        availableDays = currentUser.availableDays;
        mealFrequency = currentUser.mealFrequency;
        mealTimes = currentUser.mealTimes ?? [];
        maxPushUps = currentUser.maxPushUps;
        maxPullUps = currentUser.maxPullUps;
        mileRunTime = currentUser.mileRunTime;
        medicalConditions = currentUser.medicalConditions;
        preferredWorkoutTimes = currentUser.preferredWorkoutTimes ?? [];
      });
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Guard context usage
    setState(() {
      programLength = prefs.getString('programLength');
      isLoading = false;
    });
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

    if (currentUser == null) return;

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
      joinedChallenges: currentUser.joinedChallenges,
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

  Future<void> generatePersonalizedPlans() async {
    if (programLength == null) {
      throw Exception("Program length must be selected.");
    }

    int totalDays = int.parse(programLength!.split(' ')[0]);

    // Store Navigator and ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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

      if (currentUser == null) return;

      // Generate Workout Program
      final workoutProgram = await WorkoutGenerator.generateWorkoutProgram(
        user: currentUser,
        totalDays: totalDays,
        workoutFrequency: workoutFrequency,
        availableDays: availableDays,
        preferredWorkoutTimes: preferredWorkoutTimes,
        context: context,
      );

      // Generate Diet Plan
      final mealPlan = await DietGenerator.generateDietPlan(
        user: currentUser,
        totalDays: totalDays,
        mealFrequency: mealFrequency ?? 3,
        // ignore: use_build_context_synchronously
        mealTimes: mealTimes,
        context: context,
      );

      // Update user's active programs and plans
      currentUser.activeWorkoutPrograms = [
        ActiveWorkoutProgram(
          workoutProgramId: workoutProgram.id,
          startDate: DateTime.now(),
          currentDay: 1,
          isCompleted: false,
          completedDays: const [],
        ),
      ];
      currentUser.activeDietPlans = [
        ActiveDietPlan(
          dietPlanId: mealPlan.id,
          startDate: DateTime.now(),
          currentDay: 1,
          isCompleted: false,
          completedDays: const [],
        ),
      ];

      // Save to Firestore
      await _saveToFirestore();

      // Store the generated plans in SharedPreferences for PersonalizedPlanScreen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('generatedWorkoutId', workoutProgram.id);
      await prefs.setString('generatedMealPlanId', mealPlan.id);

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("Personalized Workout & Meal Plans Created!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Error generating plans: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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

    if (isLoading || FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle("Your Profile", theme, colorScheme),
                  _dropdown(
                    "Gender",
                    genders,
                    gender,
                    (v) => gender = v,
                    theme,
                    colorScheme,
                  ),
                  _textInput("Age", age, (v) => age = v, theme, colorScheme),
                  _textInput(
                    "Height (cm)",
                    height,
                    (v) => height = v,
                    theme,
                    colorScheme,
                  ),
                  _textInput(
                    "Weight (kg)",
                    weight,
                    (v) => weight = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Activity Level",
                    activityLevels,
                    activity,
                    (v) => activity = v,
                    theme,
                    colorScheme,
                  ),
                  _textInput(
                    "Max Push-Ups",
                    maxPushUps?.toString(),
                    (v) => maxPushUps = double.tryParse(v),
                    theme,
                    colorScheme,
                  ),
                  _textInput(
                    "Max Pull-Ups",
                    maxPullUps?.toString(),
                    (v) => maxPullUps = double.tryParse(v),
                    theme,
                    colorScheme,
                  ),
                  _textInput(
                    "Mile Run Time (min)",
                    mileRunTime?.toString(),
                    (v) => mileRunTime = double.tryParse(v),
                    theme,
                    colorScheme,
                  ),

                  _sectionTitle("Diet Goals", theme, colorScheme),
                  _dropdown(
                    "Diet Goal",
                    dietGoals,
                    dietGoal,
                    (v) => dietGoal = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Diet Preference (Optional)",
                    dietPreferences,
                    dietPreference,
                    (v) => dietPreference = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Meals Per Day (Optional)",
                    mealOptions.map((e) => e.toString()).toList(),
                    mealFrequency?.toString(),
                    (v) => mealFrequency = int.tryParse(v ?? '3'),
                    theme,
                    colorScheme,
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
                    (v) => workoutGoal = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Experience Level",
                    experienceLevels,
                    experience,
                    (v) => experience = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Training Style",
                    trainingStyles,
                    trainingStyle,
                    (v) => trainingStyle = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Intensity (Optional)",
                    intensityLevels,
                    intensity,
                    (v) => intensity = v,
                    theme,
                    colorScheme,
                  ),
                  _dropdown(
                    "Length of Program",
                    programLengthOptions,
                    programLength,
                    (val) => setState(() => programLength = val),
                    theme,
                    colorScheme,
                  ),
                  _slider(
                    "Workout Frequency (days/week)",
                    workoutFrequency.toDouble(),
                    (val) => workoutFrequency = val.toInt(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _slider(
                    "Workout Duration (minutes) (Optional)",
                    workoutDuration,
                    (val) => workoutDuration = val,
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
                    (v) => hydration = v,
                    theme,
                    colorScheme,
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
    if (title == "Meal Times" ||
        title == "Available Days" ||
        title == "Preferred Workout Times" ||
        title == "Available Equipment" ||
        title == "Injury History" ||
        title == "Medical Conditions" ||
        title == "Hydration" ||
        title == "Dietary Restrictions" ||
        title == "Workout Focus") {
      displayTitle = "$title (Optional)";
    }
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        displayTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
    ColorScheme colorScheme,
  ) {
    return DropdownButtonFormField<String>(
      value: options.contains(selected) ? selected : null,
      decoration: _inputDecoration(label, theme, colorScheme),
      dropdownColor: colorScheme.surfaceContainer,
      iconEnabledColor: colorScheme.primary,
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
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
      onChanged: (val) => setState(() => onChanged(val)),
      validator: (val) {
        if (label.contains("(Optional)")) return null;
        return val == null ? 'Please select $label' : null;
      },
    );
  }

  Widget _textInput(
    String label,
    String? value,
    ValueChanged<String> onChanged,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: _inputDecoration(label, theme, colorScheme),
        validator: (val) {
          if (label.contains("(Optional)")) return null;
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
      onPressed: () async {
        if (_formKey.currentState?.validate() ?? false) {
          // Store Navigator and ScaffoldMessenger before async operation
          final navigator = Navigator.of(context);
          ScaffoldMessenger.of(context);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  backgroundColor: colorScheme.surface,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
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

          await _storeDataLocally();
          await generatePersonalizedPlans();
          await _saveToFirestore();

          if (!mounted) return;
          navigator.pop();

          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const PersonalizedPlanScreen(),
            ),
          );
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
    );
  }
}
