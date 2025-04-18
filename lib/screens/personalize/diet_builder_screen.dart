import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../nav_screen.dart';
import '../../models/app_user.dart';
import '../../utils/diet_generator.dart';
import '../../providers/user_provider.dart';

class DietBuilderScreen extends StatefulWidget {
  const DietBuilderScreen({super.key});

  @override
  DietBuilderScreenState createState() => DietBuilderScreenState();
}

class DietBuilderScreenState extends State<DietBuilderScreen> {
  String selectedGoal = "Lose Fat";
  String? dietPreference;
  String? hydration;
  List<String> selectedRestrictions = [];
  List<String> medicalConditions = [];
  int? mealFrequency;
  List<String> mealTimes = [];
  String? dietPlanLength;

  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  User? firebaseUser;

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

    // Load user data from Firestore
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData(firebaseUser!.uid);
    final user = userProvider.currentUser;
    if (user != null) {
      if (!mounted) return; // Guard context usage
      setState(() {
        selectedGoal = user.dietGoal;
        dietPreference = user.dietPreference;
        hydration = user.hydration;
        selectedRestrictions = user.dietaryRestrictions;
        medicalConditions = user.medicalConditions;
        mealFrequency = user.mealFrequency;
        mealTimes = user.mealTimes ?? [];
      });
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Guard context usage
    setState(() {
      dietPlanLength = prefs.getString('dietPlanLength');
      isLoading = false;
    });
  }

  Future<void> _storeDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dietGoal', selectedGoal);
    await prefs.setString('dietPreference', dietPreference ?? '');
    await prefs.setString('hydration', hydration ?? '');
    await prefs.setStringList('dietaryRestrictions', selectedRestrictions);
    await prefs.setStringList('medicalConditions', medicalConditions);
    await prefs.setInt('mealFrequency', mealFrequency ?? 3);
    await prefs.setStringList('mealTimes', mealTimes);
    await prefs.setString('dietPlanLength', dietPlanLength ?? '');
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
      height: currentUser.height,
      weight: currentUser.weight,
      activityLevel: currentUser.activityLevel,
      dietGoal: selectedGoal,
      dietPreference: dietPreference ?? '',
      workoutGoal: currentUser.workoutGoal,
      experienceLevel: currentUser.experienceLevel,
      trainingStyle: currentUser.trainingStyle,
      availableEquipment: currentUser.availableEquipment,
      injuryHistory: currentUser.injuryHistory,
      workoutFrequency: currentUser.workoutFrequency,
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
      hydration: hydration,
      dietaryRestrictions: selectedRestrictions,
      workoutFocus: currentUser.workoutFocus,
      workoutDuration: currentUser.workoutDuration,
      intensity: currentUser.intensity,
      availableDays: currentUser.availableDays,
      mealFrequency: mealFrequency ?? 3,
      mealTimes: mealTimes,
      maxPushUps: currentUser.maxPushUps,
      maxPullUps: currentUser.maxPullUps,
      mileRunTime: currentUser.mileRunTime,
      medicalConditions: medicalConditions,
      preferredWorkoutTimes: currentUser.preferredWorkoutTimes,
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

  // Generate the diet plan using DietGenerator
  Future<void> _generateDietPlan() async {
    if (firebaseUser == null || dietPlanLength == null) return;

    int totalDays = int.parse(dietPlanLength!.split(' ')[0]);

    // Ensure mealTimes matches mealFrequency
    if (mealTimes.length < (mealFrequency ?? 3)) {
      for (int i = mealTimes.length; i < (mealFrequency ?? 3); i++) {
        mealTimes.add("12:00");
      }
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    // Generate the diet plan
    try {
      await DietGenerator.generateDietPlan(
        context: context,
        user: currentUser,
        totalDays: totalDays,
        mealFrequency: mealFrequency ?? 3,
        mealTimes: mealTimes,
      );

      // Save updated user data (with macro targets and intake history)
      await _saveToFirestore();
    } catch (e) {
      throw Exception("Error generating diet plan: $e");
    }
  }

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
  final List<String> restrictions = ["Nuts", "Dairy", "Gluten", "Soy", "Eggs"];
  final List<String> hydrationLevels = [
    "1-2 Liters",
    "2-3 Liters",
    "3+ Liters",
  ];
  final List<String> conditionOptions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Arthritis",
  ];
  final List<int> mealOptions = [2, 3, 4, 5, 6];
  final List<String> dietPlanLengthOptions = [
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
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Build Your Diet Plan",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Diet Goals", theme, colorScheme),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    "Diet Goal",
                    dietGoals,
                    selectedGoal,
                    (val) => setState(() => selectedGoal = val!),
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Diet Preference (Optional)",
                    dietPreferences,
                    dietPreference,
                    (val) => setState(() => dietPreference = val),
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Length of Diet Plan",
                    dietPlanLengthOptions,
                    dietPlanLength,
                    (val) => setState(() => dietPlanLength = val),
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Meals Per Day (Optional)",
                    mealOptions.map((e) => e.toString()).toList(),
                    mealFrequency?.toString(),
                    (val) => setState(
                      () => mealFrequency = int.tryParse(val ?? '3'),
                    ),
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    "Meal Times (Optional)",
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildTimePickerInput(theme, colorScheme),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    "Dietary Restrictions (Optional)",
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildChipGrid(
                    restrictions,
                    selectedRestrictions,
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    "Medical Conditions (Optional)",
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildChipGrid(
                    conditionOptions,
                    medicalConditions,
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    "Hydration (Optional)",
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    "Hydration",
                    hydrationLevels,
                    hydration,
                    (val) => setState(() => hydration = val),
                    theme,
                    colorScheme,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          colorScheme.primary,
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          colorScheme.onPrimary,
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Store Navigator and ScaffoldMessenger before async operation
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );

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
                                        "Generating Your Diet Plan...",
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                          );

                          try {
                            await _storeDataLocally();
                            await _generateDietPlan();
                          } catch (e) {
                            if (!mounted) return;
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text("Error generating diet plan: $e"),
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
                                "Diet Plan Generated! Duration: ${dietPlanLength ?? 'Not specified'}",
                              ),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Create Diet Plan",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
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

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.primary,
        fontSize: 18,
      ),
    );
  }

  Widget _buildDropdown(
    String title,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildChipGrid(
    List<String> options,
    List<String> selectedList,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Wrap(
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
                      isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainer,
              onSelected:
                  (_) => setState(() {
                    if (isSelected) {
                      selectedList.remove(item);
                    } else {
                      selectedList.add(item);
                    }
                  }),
            );
          }).toList(),
    );
  }

  Widget _buildTimePickerInput(ThemeData theme, ColorScheme colorScheme) {
    final count = mealFrequency ?? 3;
    // Clear excess times if count decreases
    if (mealTimes.length > count) {
      setState(() {
        mealTimes.removeRange(count, mealTimes.length);
      });
    }

    return Column(
      children: List.generate(count, (index) {
        final timeString =
            mealTimes.length > index ? mealTimes[index] : "Select Time";
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
                  if (mealTimes.length <= index) {
                    mealTimes.add(formattedTime);
                  } else {
                    mealTimes[index] = formattedTime;
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
                    "Meal ${index + 1} Time: $timeString",
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
}
