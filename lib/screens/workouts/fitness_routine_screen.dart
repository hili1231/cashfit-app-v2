import 'package:flutter/material.dart';
import '../personalize/fitness_goal_screen.dart';
import '../../theme.dart'; // ✅ Import centralized theme
import '../../widgets/selection_button.dart';

class FitnessRoutineScreen extends StatelessWidget {
  const FitnessRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient, // Global gradient background
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparent so gradient shows
        appBar: AppBar(
          title: Text(
            "Do you have a fitness routine?",
            style: AppTheme.headline.copyWith(
              color: AppTheme.gold,
              fontSize: 20,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  // Convert 0.5 opacity to alpha (~128)
                  color: Colors.amberAccent.withAlpha((0.5 * 255).round()),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 2,
          // Convert 0.2 opacity to alpha (~51)
          shadowColor: Colors.amberAccent.withAlpha((0.2 * 255).round()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📌 Intro Text
              Text(
                "Help us personalize your fitness journey!",
                textAlign: TextAlign.center,
                style: AppTheme.smallText.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 30),
              // ✅ YES BUTTON
              SelectionButton(
                text: "Yes, I have a routine",
                icon: Icons.check_circle,
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.createPageRoute(const FitnessGoalScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              // ❌ NO BUTTON
              SelectionButton(
                text: "No, I need help",
                icon: Icons.close,
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.createPageRoute(const FitnessGoalScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
