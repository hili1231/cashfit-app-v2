import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/login_screen.dart';
import '../../theme.dart';
import '../nav_screen.dart';

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
  String workoutType = "Strength Training";
  String activityLevel = "Sedentary";
  int workoutFrequency = 3;
  List<String> availableEquipment = [];
  List<String> injuries = [];
  double weight = 0.0;
  double height = 0.0;

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
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const LoginScreen());
        }
      });
      return;
    }
    if (mounted) {
      setState(() => isLoading = false);
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
    "Increase Endurance",
    "General Fitness",
  ];
  final List<String> workoutTypes = [
    "Strength Training",
    "Cardio",
    "HIIT",
    "Bodyweight Workouts",
  ];
  final List<String> activityLevels = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
  ];
  final List<String> equipmentOptions = [
    "Bodyweight Only",
    "Dumbbells",
    "Resistance Bands",
    "Barbells",
    "Gym Equipment",
  ];
  final List<String> injuryList = [
    "Knee Pain",
    "Lower Back Pain",
    "Shoulder Injury",
    "Wrist Issues",
    "Ankle Sprain",
  ];
  final List<String> unitOptions = ["Metric", "Imperial"];

  @override
  Widget build(BuildContext context) {
    if (isLoading || FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Build Your Workout Plan"),
                    _buildDropdown(
                      "Unit System",
                      unitOptions,
                      unitSystem,
                      (val) => unitSystem = val!,
                    ),
                    _buildDropdown(
                      "Experience Level",
                      experienceLevels,
                      experienceLevel,
                      (val) => experienceLevel = val!,
                    ),
                    _buildDropdown(
                      "Workout Goal",
                      workoutGoals,
                      workoutGoal,
                      (val) => workoutGoal = val!,
                    ),
                    _buildDropdown(
                      "Workout Type",
                      workoutTypes,
                      workoutType,
                      (val) => workoutType = val!,
                    ),
                    _buildDropdown(
                      "Activity Level",
                      activityLevels,
                      activityLevel,
                      (val) => activityLevel = val!,
                    ),
                    _buildNumberInput(
                      "Weight (${unitSystem == "Metric" ? "kg" : "lbs"})",
                      (v) => weight = double.tryParse(v) ?? 0.0,
                    ),
                    _buildNumberInput(
                      "Height (${unitSystem == "Metric" ? "cm" : "inches"})",
                      (v) => height = double.tryParse(v) ?? 0.0,
                    ),
                    _buildSliderInput(
                      "Workout Frequency (Days per Week)",
                      workoutFrequency,
                      (val) => workoutFrequency = val.toInt(),
                    ),
                    sectionTitle("Available Equipment"),
                    _buildResponsiveChipGrid(
                      equipmentOptions,
                      availableEquipment,
                    ),
                    sectionTitle("Injury History (Optional)"),
                    _buildResponsiveChipGrid(injuryList, injuries),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
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
                    navState.clearDetailScreen();
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

  Widget sectionTitle(String title) => Padding(
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

  Widget _buildDropdown(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: selectedValue,
      dropdownColor: Colors.grey[900],
      decoration: InputDecoration(
        labelText: title,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
      onChanged: onChanged,
    ),
  );

  Widget _buildNumberInput(String label, ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(color: Colors.white70),
          onChanged: onChanged,
        ),
      );

  Widget _buildSliderInput(
    String label,
    int currentValue,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$label: $currentValue",
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
      Slider(
        value: currentValue.toDouble(),
        min: 1,
        max: 7,
        divisions: 6,
        onChanged: onChanged,
        activeColor: Colors.amber,
      ),
    ],
  );

  Widget _buildResponsiveChipGrid(
    List<String> options,
    List<String> selectedList,
  ) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children:
        options.map((item) {
          final isSelected = selectedList.contains(item);
          return ChoiceChip(
            label: Text(
              item,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: Colors.amber,
            backgroundColor: Colors.grey[850],
            onSelected:
                (_) => setState(() {
                  isSelected
                      ? selectedList.remove(item)
                      : selectedList.add(item);
                }),
          );
        }).toList(),
  );

  Widget _buildSubmitButton() => Center(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Workout Plan Saved!")));
      },
      child: const Text("Generate Workout Plan"),
    ),
  );
}
