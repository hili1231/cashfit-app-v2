import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../nav_screen.dart';
import '../../models/app_user.dart';
import '../../utils/workout_generator.dart';
import '../../providers/user_provider.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final bool buildBoth;

  const WorkoutBuilderScreen({super.key, this.buildBoth = false});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  String unitSystem = "Metric";
  String experienceLevel = "Beginner";
  String workoutGoal = "Build Muscle";
  String activityLevel = "Sedentary";
  String? trainingStyle;
  String? intensity;
  int workoutFrequency = 3;
  double workoutDuration = 30;
  List<String> availableEquipment = [];
  List<String> injuries = [];
  List<String> workoutFocus = [];
  List<String> medicalConditions = [];
  List<String> availableDays = [];
  List<String> preferredWorkoutTimes = [];
  double weight = 0.0;
  double height = 0.0;
  double? maxPushUps, maxPullUps, mileRunTime;
  String? programLength;

  bool isLoading = true;
  User? firebaseUser;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Guard context usage
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const LoginScreen());
        }
      });
      return;
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData(firebaseUser!.uid);
    final user = userProvider.currentUser;
    if (user != null) {
      if (!mounted) return; // Guard context usage
      setState(() {
        unitSystem = user.height.contains("cm") ? "Metric" : "Imperial";
        experienceLevel = user.experienceLevel;
        workoutGoal = user.workoutGoal;
        activityLevel = user.activityLevel;
        trainingStyle = user.trainingStyle;
        intensity = user.intensity;
        workoutFrequency = (user.workoutFrequency).clamp(1, 7);
        workoutDuration = user.workoutDuration;
        availableEquipment = user.availableEquipment;
        injuries = user.injuryHistory;
        workoutFocus = user.workoutFocus;
        medicalConditions = user.medicalConditions;
        availableDays = user.availableDays;
        preferredWorkoutTimes = user.preferredWorkoutTimes ?? [];
        weight = double.tryParse(user.weight) ?? 0.0;
        height = double.tryParse(user.height) ?? 0.0;
        maxPushUps = user.maxPushUps;
        maxPullUps = user.maxPullUps;
        mileRunTime = user.mileRunTime;
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
    await prefs.setString('unitSystem', unitSystem);
    await prefs.setString('experienceLevel', experienceLevel);
    await prefs.setString('workoutGoal', workoutGoal);
    await prefs.setString('activityLevel', activityLevel);
    await prefs.setString('trainingStyle', trainingStyle ?? '');
    await prefs.setString('intensity', intensity ?? '');
    await prefs.setInt('workoutFrequency', workoutFrequency);
    await prefs.setDouble('workoutDuration', workoutDuration);
    await prefs.setStringList('availableEquipment', availableEquipment);
    await prefs.setStringList('injuries', injuries);
    await prefs.setStringList('workoutFocus', workoutFocus);
    await prefs.setStringList('medicalConditions', medicalConditions);
    await prefs.setStringList('availableDays', availableDays);
    await prefs.setStringList('preferredWorkoutTimes', preferredWorkoutTimes);
    await prefs.setDouble('weight', weight);
    await prefs.setDouble('height', height);
    await prefs.setDouble('maxPushUps', maxPushUps ?? 0);
    await prefs.setDouble('maxPullUps', maxPullUps ?? 0);
    await prefs.setDouble('mileRunTime', mileRunTime ?? 0);
    await prefs.setString('programLength', programLength ?? '');
  }

  Future<void> _saveToFirestore() async {
    if (firebaseUser == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    final updatedUser = AppUser(
      id: firebaseUser!.uid,
      name: currentUser.name,
      email: currentUser.email,
      avatar: currentUser.avatar,
      workoutsCompleted: currentUser.workoutsCompleted,
      mealsTracked: currentUser.mealsTracked,
      gender: currentUser.gender,
      age: currentUser.age,
      height: height.toString() + (unitSystem == "Metric" ? " cm" : " in"),
      weight: weight.toString() + (unitSystem == "Metric" ? " kg" : " lbs"),
      activityLevel: activityLevel,
      dietGoal: currentUser.dietGoal,
      dietPreference: currentUser.dietPreference,
      workoutGoal: workoutGoal,
      experienceLevel: experienceLevel,
      trainingStyle: trainingStyle ?? '',
      availableEquipment: availableEquipment,
      injuryHistory: injuries,
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
      hydration: currentUser.hydration,
      dietaryRestrictions: currentUser.dietaryRestrictions,
      workoutFocus: workoutFocus,
      workoutDuration: workoutDuration,
      intensity: intensity,
      availableDays: availableDays,
      mealFrequency: currentUser.mealFrequency,
      mealTimes: currentUser.mealTimes,
      maxPushUps: maxPushUps,
      maxPullUps: maxPullUps,
      mileRunTime: mileRunTime,
      medicalConditions: medicalConditions,
      preferredWorkoutTimes: preferredWorkoutTimes,
      challengeCheckIns: currentUser.challengeCheckIns,
      challengeProgress: currentUser.challengeProgress,
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
        .doc(firebaseUser!.uid)
        .set(updatedUser.toMap(), SetOptions(merge: true));

    // Update UserProvider with the new user data
    userProvider.updateUser(updatedUser);
  }

  Future<void> _generateWorkoutProgram() async {
    if (firebaseUser == null || programLength == null) return;

    int totalDays = int.parse(programLength!.split(' ')[0]);

    if (preferredWorkoutTimes.length < workoutFrequency) {
      for (int i = preferredWorkoutTimes.length; i < workoutFrequency; i++) {
        preferredWorkoutTimes.add("12:00");
      }
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    try {
      await WorkoutGenerator.generateWorkoutProgram(
        user: currentUser,
        totalDays: totalDays,
        workoutFrequency: workoutFrequency,
        availableDays: availableDays,
        preferredWorkoutTimes: preferredWorkoutTimes, context: context,
      );
      await _saveToFirestore();
    } catch (e) {
      throw Exception("Error generating workout program: $e");
    }
  }

  final List<String> experienceLevels = [
    "Beginner",
    "Intermediate",
    "Advanced",
  ];
  final List<String> workoutGoals = [
    "Build Muscle",
    "Lose Fat",
    "Lose Fat & Build Muscle",
    "Improve Endurance",
  ];
  final List<String> trainingStyles = ["Gym", "Home", "Bodyweight", "CrossFit"];
  final List<String> intensityLevels = ["Low", "Moderate", "High"];
  final List<String> activityLevels = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
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
  final List<String> injuryList = [
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
  final List<String> conditionOptions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Arthritis",
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
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final List<String> unitOptions = ["Metric", "Imperial"];
  final List<String> programLengthOptions = [
    "30 Days",
    "60 Days",
    "90 Days",
    "120 Days",
  ];

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Build Your Workout Plan", theme, colorScheme),
                    _buildDropdown(
                      "Unit System",
                      unitOptions,
                      unitSystem,
                      (val) => setState(() => unitSystem = val!),
                      theme,
                      colorScheme,
                    ),
                    _buildNumberInput(
                      "Weight (${unitSystem == "Metric" ? "kg" : "lbs"})",
                      weight.toString(),
                      (v) => setState(() => weight = double.tryParse(v) ?? 0.0),
                      theme,
                      colorScheme,
                    ),
                    _buildNumberInput(
                      "Height (${unitSystem == "Metric" ? "cm" : "inches"})",
                      height.toString(),
                      (v) => setState(() => height = double.tryParse(v) ?? 0.0),
                      theme,
                      colorScheme,
                    ),
                    _buildDropdown(
                      "Activity Level",
                      activityLevels,
                      activityLevel,
                      (val) => setState(() => activityLevel = val!),
                      theme,
                      colorScheme,
                    ),
                    _buildNumberInput(
                      "Max Push-Ups (Optional)",
                      maxPushUps?.toString(),
                      (v) => setState(() => maxPushUps = double.tryParse(v)),
                      theme,
                      colorScheme,
                    ),
                    _buildNumberInput(
                      "Max Pull-Ups (Optional)",
                      maxPullUps?.toString(),
                      (v) => setState(() => maxPullUps = double.tryParse(v)),
                      theme,
                      colorScheme,
                    ),
                    _buildNumberInput(
                      "Mile Run Time (min) (Optional)",
                      mileRunTime?.toString(),
                      (v) => setState(() => mileRunTime = double.tryParse(v)),
                      theme,
                      colorScheme,
                    ),
                    sectionTitle("Workout Goals", theme, colorScheme),
                    _buildDropdown(
                      "Workout Goal",
                      workoutGoals,
                      workoutGoal,
                      (val) => setState(() => workoutGoal = val!),
                      theme,
                      colorScheme,
                    ),
                    _buildDropdown(
                      "Experience Level",
                      experienceLevels,
                      experienceLevel,
                      (val) => setState(() => experienceLevel = val!),
                      theme,
                      colorScheme,
                    ),
                    _buildDropdown(
                      "Training Style",
                      trainingStyles,
                      trainingStyle,
                      (val) => setState(() => trainingStyle = val),
                      theme,
                      colorScheme,
                    ),
                    _buildDropdown(
                      "Length of Program",
                      programLengthOptions,
                      programLength,
                      (val) => setState(() => programLength = val),
                      theme,
                      colorScheme,
                    ),
                    _buildDropdown(
                      "Intensity (Optional)",
                      intensityLevels,
                      intensity,
                      (val) => setState(() => intensity = val),
                      theme,
                      colorScheme,
                    ),
                    _buildSliderInput(
                      "Workout Frequency (Days per Week)",
                      workoutFrequency.toDouble(),
                      (val) => setState(() => workoutFrequency = val.toInt()),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    _buildSliderInput(
                      "Workout Duration (minutes)",
                      workoutDuration,
                      (val) => setState(() => workoutDuration = val),
                      min: 15,
                      max: 120,
                      divisions: 21,
                      required: true,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    sectionTitle(
                      "Available Days (Optional)",
                      theme,
                      colorScheme,
                    ),
                    _buildResponsiveChipGrid(
                      daysOfWeek,
                      availableDays,
                      theme,
                      colorScheme,
                    ),
                    sectionTitle(
                      "Preferred Workout Times (Optional)",
                      theme,
                      colorScheme,
                    ),
                    _buildTimePickerInput(context, theme, colorScheme),
                    sectionTitle("Available Equipment", theme, colorScheme),
                    _buildResponsiveChipGrid(
                      equipmentOptions,
                      availableEquipment,
                      theme,
                      colorScheme,
                    ),
                    sectionTitle(
                      "Injury History (Optional)",
                      theme,
                      colorScheme,
                    ),
                    _buildResponsiveChipGrid(
                      injuryList,
                      injuries,
                      theme,
                      colorScheme,
                    ),
                    sectionTitle(
                      "Medical Conditions (Optional)",
                      theme,
                      colorScheme,
                    ),
                    _buildResponsiveChipGrid(
                      conditionOptions,
                      medicalConditions,
                      theme,
                      colorScheme,
                    ),
                    sectionTitle(
                      "Workout Focus (Optional)",
                      theme,
                      colorScheme,
                    ),
                    _buildResponsiveChipGrid(
                      focusAreas,
                      workoutFocus,
                      theme,
                      colorScheme,
                    ),
                    const SizedBox(height: 30),
                    _buildSubmitButton(context, theme, colorScheme),
                  ],
                ),
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
                onPressed: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.clearDetailScreen();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, ThemeData theme, ColorScheme colorScheme) =>
      Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 10),
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildDropdown(
    String title,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: options.contains(selectedValue) ? selectedValue : null,
      dropdownColor: colorScheme.surfaceContainer,
      decoration: InputDecoration(
        labelText: title,
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
      ),
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
      onChanged: onChanged,
      validator: (val) {
        if (title.contains("(Optional)")) return null;
        return val == null ? 'Please select $title' : null;
      },
    ),
  );

  Widget _buildNumberInput(
    String label,
    String? value,
    ValueChanged<String> onChanged,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
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
      ),
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      onChanged: onChanged,
      validator: (val) {
        if (label.contains("(Optional)")) return null;
        if (val == null || val.isEmpty) return 'Enter $label';
        if ((label.contains("Height") &&
                (double.tryParse(val)! < (unitSystem == "Metric" ? 100 : 40) ||
                    double.tryParse(val)! >
                        (unitSystem == "Metric" ? 250 : 100))) ||
            (label.contains("Weight") &&
                (double.tryParse(val)! < (unitSystem == "Metric" ? 30 : 66) ||
                    double.tryParse(val)! >
                        (unitSystem == "Metric" ? 300 : 660)))) {
          return 'Enter a realistic $label';
        }
        return null;
      },
    ),
  );

  Widget _buildSliderInput(
    String label,
    double currentValue,
    ValueChanged<double> onChanged, {
    double min = 1,
    double max = 7,
    int? divisions,
    bool required = false,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$label: ${currentValue.round()}",
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      Slider(
        value: currentValue,
        min: min,
        max: max,
        divisions: divisions ?? ((max - min) ~/ 1),
        label: "${currentValue.round()}",
        activeColor: colorScheme.primary,
        onChanged: onChanged,
      ),
    ],
  );

  Widget _buildResponsiveChipGrid(
    List<String> options,
    List<String> selectedList,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children:
        options.map((item) {
          final isSelected = selectedList.contains(item);
          return ChoiceChip(
            label: Text(
              item,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainer,
            onSelected:
                (_) => setState(() {
                  isSelected
                      ? selectedList.remove(item)
                      : selectedList.add(item);
                }),
          );
        }).toList(),
  );

  Widget _buildTimePickerInput(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final count = workoutFrequency;
    if (preferredWorkoutTimes.length > count) {
      setState(() {
        preferredWorkoutTimes.removeRange(count, preferredWorkoutTimes.length);
      });
    }

    return Column(
      children: List.generate(count, (index) {
        final timeString =
            preferredWorkoutTimes.length > index
                ? preferredWorkoutTimes[index]
                : "Select Time";
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
                  if (preferredWorkoutTimes.length <= index) {
                    preferredWorkoutTimes.add(formattedTime);
                  } else {
                    preferredWorkoutTimes[index] = formattedTime;
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
                    "Workout ${index + 1} Time: $timeString",
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

  Widget _buildSubmitButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => Center(
    child: ElevatedButton(
      style: theme.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.all(colorScheme.primary),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      onPressed: () async {
        if (_formKey.currentState?.validate() ?? false) {
          // Store Navigator and ScaffoldMessenger before async operation
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                        "Generating Your Workout Plan...",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
          );

          try {
            await _storeDataLocally();
            await _generateWorkoutProgram();
          } catch (e) {
            if (!mounted) return;
            navigator.pop();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error generating workout plan: $e"),
                backgroundColor: colorScheme.error,
              ),
            );
            return;
          }

          if (!mounted) return;
          navigator.pop();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                "Workout Plan Generated! Program Length: ${programLength ?? 'Not specified'}",
              ),
              backgroundColor: colorScheme.primary,
            ),
          );
        }
      },
      child: Text(
        "Generate Workout Plan",
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
    ),
  );
}
