import 'package:flutter/material.dart';
import '../theme.dart'; // Global theme
import 'nav_screen.dart'; // Navigation state for back button

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
                    _buildDropdown("Unit System", unitOptions, unitSystem, (
                      value,
                    ) {
                      setState(() => unitSystem = value!);
                    }),
                    _buildDropdown(
                      "Experience Level",
                      experienceLevels,
                      experienceLevel,
                      (value) {
                        setState(() => experienceLevel = value!);
                      },
                    ),
                    _buildDropdown("Workout Goal", workoutGoals, workoutGoal, (
                      value,
                    ) {
                      setState(() => workoutGoal = value!);
                    }),
                    _buildDropdown("Workout Type", workoutTypes, workoutType, (
                      value,
                    ) {
                      setState(() => workoutType = value!);
                    }),
                    _buildDropdown(
                      "Activity Level",
                      activityLevels,
                      activityLevel,
                      (value) {
                        setState(() => activityLevel = value!);
                      },
                    ),
                    _buildNumberInput(
                      "Weight (${unitSystem == "Metric" ? "kg" : "lbs"})",
                      (value) => setState(
                        () => weight = double.tryParse(value) ?? 0.0,
                      ),
                    ),
                    _buildNumberInput(
                      "Height (${unitSystem == "Metric" ? "cm" : "inches"})",
                      (value) => setState(
                        () => height = double.tryParse(value) ?? 0.0,
                      ),
                    ),
                    _buildSliderInput(
                      "Workout Frequency (Days per Week)",
                      workoutFrequency,
                      (value) {
                        setState(() => workoutFrequency = value.toInt());
                      },
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
          // Floating back button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.clearDetailScreen();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
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

  Widget sectionTitle(String title) {
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

  Widget _buildDropdown(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
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
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberInput(String label, ValueChanged<String> onChanged) {
    return Padding(
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
  }

  Widget _buildSliderInput(
    String label,
    int currentValue,
    ValueChanged<double> onChanged,
  ) {
    return Column(
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
  }

  Widget _buildResponsiveChipGrid(
    List<String> options,
    List<String> selectedList,
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
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.amber,
              backgroundColor: Colors.grey[850],
              onSelected: (_) {
                setState(() {
                  isSelected
                      ? selectedList.remove(item)
                      : selectedList.add(item);
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
}
