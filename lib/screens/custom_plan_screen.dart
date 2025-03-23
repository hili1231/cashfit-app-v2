import 'package:flutter/material.dart';
import '../theme.dart'; // ✅ Import global theme

class CustomPlanScreen extends StatelessWidget {
  const CustomPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ Uses gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // ✅ Unified gradient
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 **Title**
                Center(
                  child: Text(
                    "Your Custom Plan",
                    style: AppTheme.headline.copyWith(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 **Plan Description**
                Text(
                  "Your customized workout & meal plan is ready!",
                  style: AppTheme.smallText,
                ),
                const SizedBox(height: 20),

                // 🔹 **Workout Plan Card**
                _buildPlanCard(
                  context,
                  title: "Workout Plan",
                  subtitle: "Full body, 5 days a week",
                  icon: Icons.fitness_center,
                  onTap: () {
                    // Navigate to detailed workout plan
                  },
                ),
                const SizedBox(height: 15),

                // 🔹 **Meal Plan Card**
                _buildPlanCard(
                  context,
                  title: "Meal Plan",
                  subtitle: "High Protein Diet",
                  icon: Icons.restaurant_menu,
                  onTap: () {
                    // Navigate to detailed meal plan
                  },
                ),
                const SizedBox(height: 30),

                // 🔹 **Edit Plan Button**
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: AppTheme.buttonStyle,
                      icon: const Icon(Icons.edit, color: Colors.black),
                      label: const Text("Edit Plan"),
                      onPressed: () {
                        // Navigate to Workout Builder Form
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **✅ Builds a Reusable Plan Card**
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.cardDecoration,
        child: ListTile(
          leading: Icon(icon, color: Colors.amber, size: 30),
          title: Text(title, style: AppTheme.goldText.copyWith(fontSize: 18)),
          subtitle: Text(subtitle, style: AppTheme.smallText),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        ),
      ),
    );
  }
}
