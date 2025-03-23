import 'package:flutter/material.dart';
import 'custom_plan_screen.dart';
import '../data/fitness_goals.dart';

class FitnessGoalScreen extends StatefulWidget {
  const FitnessGoalScreen({super.key});

  @override
  FitnessGoalScreenState createState() => FitnessGoalScreenState();
}

class FitnessGoalScreenState extends State<FitnessGoalScreen> {
  final Set<String> _selectedGoals = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "What goal do you want to achieve?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent.shade200.withOpacity(0.9),
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: Colors.amberAccent.withOpacity(0.5), blurRadius: 8),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
        shadowColor: Colors.amberAccent.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ℹ️ Instructional Text
            const Text(
              "You can choose more than one:",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 15),

            // 🏋️ Fitness Goal Selection
            Expanded(
              child: ListView(
                children:
                    fitnessGoals.map((goal) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGoals.contains(goal)
                                ? _selectedGoals.remove(goal)
                                : _selectedGoals.add(goal);
                          });
                        },
                        child: Card(
                          color:
                              _selectedGoals.contains(goal)
                                  ? Colors.amber.withOpacity(0.2)
                                  : Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            activeColor: Colors.amber,
                            checkColor: Colors.black,
                            title: Text(
                              goal,
                              style: TextStyle(
                                color:
                                    _selectedGoals.contains(goal)
                                        ? Colors.amber
                                        : Colors.white70,
                                fontWeight:
                                    _selectedGoals.contains(goal)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            value: _selectedGoals.contains(goal),
                            onChanged: (bool? isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  _selectedGoals.add(goal);
                                } else {
                                  _selectedGoals.remove(goal);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),

      // ➡️ Floating Action Button for Navigation
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _selectedGoals.isNotEmpty ? 1.0 : 0.5,
        child: FloatingActionButton(
          backgroundColor:
              _selectedGoals.isNotEmpty ? Colors.amber : Colors.grey,
          onPressed:
              _selectedGoals.isNotEmpty
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomPlanScreen(),
                      ),
                    );
                  }
                  : null,
          child: const Icon(Icons.arrow_forward, color: Colors.black),
        ),
      ),
    );
  }
}
