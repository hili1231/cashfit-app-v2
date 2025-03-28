import 'package:cashfit/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../utils/meal_plan_generator.dart';
import 'personalized_plan_screen.dart';
import '../../models/workout_program.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

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
  List<String> injuryHistory = [], availableEquipment = [];
  int workoutFrequency = 3;
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
    "Maintain Weight",
  ];
  final List<String> dietPreferences = [
    "Balanced",
    "Vegetarian",
    "Vegan",
    "Keto",
    "Paleo",
  ];
  final List<String> workoutGoals = [
    "Build Muscle",
    "Lose Fat",
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
  ];
  final List<String> equipmentOptions = [
    "Bodyweight Only",
    "Dumbbells",
    "Resistance Bands",
    "Barbells",
    "Gym Equipment",
  ];

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
  }

  Future<void> generatePersonalizedPlans() async {
    final prefs = await SharedPreferences.getInstance();

    final level = experience ?? "Beginner";

    // Fetch matching workout programs from Firestore based on experience level
    final snapshot =
        await FirebaseFirestore.instance
            .collection('workoutPrograms')
            .where('level', isEqualTo: level)
            .get();

    final matchingWorkouts =
        snapshot.docs
            .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
            .toList();
    final generatedWorkout =
        matchingWorkouts.isNotEmpty ? matchingWorkouts.first : null;

    final generatedMealPlan = generatePersonalizedMealPlan(
      userId:
          "defaultUserId", // Replace with the actual userId variable or value
      dietGoal: dietGoal ?? "Maintain Weight",
      dietPreference: dietPreference ?? "Balanced",
      activityLevel: activity ?? "Moderately Active",
      weight: weight ?? "70",
      height: height ?? "175",
      days: workoutFrequency,
    );

    if (generatedWorkout != null) {
      await prefs.setString('personalizedWorkout', generatedWorkout.title);
    }

    await prefs.setString('personalizedMealPlan', generatedMealPlan.planName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Personalized Workout & Meal Plans Created!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle("Your Profile"),
                    _dropdown("Gender", genders, gender, (v) => gender = v),
                    _textInput("Age", age, (v) => age = v),
                    _textInput("Height (cm)", height, (v) => height = v),
                    _textInput("Weight (kg)", weight, (v) => weight = v),
                    _dropdown(
                      "Activity Level",
                      activityLevels,
                      activity,
                      (v) => activity = v,
                    ),

                    _sectionTitle("Diet Goals"),
                    _dropdown(
                      "Diet Goal",
                      dietGoals,
                      dietGoal,
                      (v) => dietGoal = v,
                    ),
                    _dropdown(
                      "Diet Preference",
                      dietPreferences,
                      dietPreference,
                      (v) => dietPreference = v,
                    ),

                    _sectionTitle("Workout Goals"),
                    _dropdown(
                      "Workout Goal",
                      workoutGoals,
                      workoutGoal,
                      (v) => workoutGoal = v,
                    ),
                    _dropdown(
                      "Experience Level",
                      experienceLevels,
                      experience,
                      (v) => experience = v,
                    ),
                    _dropdown(
                      "Training Style",
                      trainingStyles,
                      trainingStyle,
                      (v) => trainingStyle = v,
                    ),
                    _slider(
                      "Workout Frequency (days/week)",
                      workoutFrequency.toDouble(),
                      (val) => workoutFrequency = val.toInt(),
                    ),

                    _sectionTitle("Available Equipment"),
                    _chipGrid(equipmentOptions, availableEquipment),
                    _sectionTitle("Injury History"),
                    _chipGrid(injuryOptions, injuryHistory),

                    const SizedBox(height: 25),
                    _buildGenerateButton(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: InkWell(
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.clearDetailScreen(); // Or setDetailScreen(null);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },

                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: options.contains(selected) ? selected : null,
      decoration: _inputDecoration(label),
      dropdownColor: Colors.grey[900],
      iconEnabledColor: Colors.amber,
      style: const TextStyle(color: Colors.white),
      items:
          options
              .map(
                (val) => DropdownMenuItem(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
              .toList(),
      onChanged: (val) => setState(() => onChanged(val)),
      validator: (val) => val == null ? 'Please select $label' : null,
    );
  }

  Widget _textInput(
    String label,
    String? value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white70),
        decoration: _inputDecoration(label),
        validator:
            (val) => (val == null || val.isEmpty) ? 'Enter $label' : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${value.toInt()}",
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: value,
          min: 1,
          max: 7,
          divisions: 6,
          label: "${value.toInt()}",
          activeColor: Colors.amber,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Widget _chipGrid(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8,
      children:
          options.map((item) {
            final selected = selectedList.contains(item);
            return ChoiceChip(
              label: Text(
                item,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                ),
              ),
              selected: selected,
              selectedColor: Colors.amber,
              backgroundColor: Colors.grey[800],
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

  Widget _buildGenerateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () async {
        if (_formKey.currentState?.validate() ?? false) {
          await _storeDataLocally();
          await generatePersonalizedPlans();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalizedPlanScreen(),
            ),
          );
        }
      },
      child: const Text("Generate My Plan"),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }
}
