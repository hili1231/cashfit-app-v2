import 'package:flutter/material.dart';
import '../../theme.dart'; // ✅ Import global theme
import '../nav_screen.dart'; // For finding NavScreenState

class DietBuilderScreen extends StatefulWidget {
  const DietBuilderScreen({super.key});

  @override
  DietBuilderScreenState createState() => DietBuilderScreenState();
}

class DietBuilderScreenState extends State<DietBuilderScreen> {
  String selectedGoal = "Weight Loss";
  List<String> selectedRestrictions = [];

  final List<String> dietGoals = [
    "Weight Loss",
    "Muscle Gain",
    "Maintenance",
    "Keto",
    "Vegan",
  ];

  final List<String> restrictions = [
    "Gluten-Free",
    "Dairy-Free",
    "Nut-Free",
    "Vegetarian",
    "No Red Meat",
  ];

  void _toggleRestriction(String restriction) {
    setState(() {
      if (selectedRestrictions.contains(restriction)) {
        selectedRestrictions.remove(restriction);
      } else {
        selectedRestrictions.add(restriction);
      }
    });
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header
                    Center(
                      child: Text(
                        "Build Your Diet Plan",
                        style: AppTheme.headline.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("Select Your Goal"),
                    const SizedBox(height: 8),
                    _buildDropdown(),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Dietary Restrictions"),
                    const SizedBox(height: 8),
                    _buildChipGrid(),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: AppTheme.buttonStyle,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Diet Plan Created!")),
                          );
                        },
                        child: const Text("Create Diet Plan"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔙 Floating Back Button
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.goldText.copyWith(fontSize: 18));
  }

  Widget _buildDropdown() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: DropdownButtonFormField<String>(
        value: selectedGoal,
        dropdownColor: AppTheme.cardBg,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items:
            dietGoals
                .map(
                  (goal) => DropdownMenuItem(
                    value: goal,
                    child: Text(goal, style: AppTheme.smallText),
                  ),
                )
                .toList(),
        onChanged: (newGoal) => setState(() => selectedGoal = newGoal!),
      ),
    );
  }

  Widget _buildChipGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          restrictions.map((item) {
            final isSelected = selectedRestrictions.contains(item);
            return GestureDetector(
              onTap: () => _toggleRestriction(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber : Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
