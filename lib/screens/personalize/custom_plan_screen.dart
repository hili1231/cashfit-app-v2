import 'package:flutter/material.dart';

class CustomPlanScreen extends StatelessWidget {
  const CustomPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 **Title**
              Center(
                child: Text(
                  "Your Custom Plan",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 **Plan Description**
              Text(
                "Your customized workout & meal plan is ready!",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
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
                theme: theme,
                colorScheme: colorScheme,
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
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 30),

              // 🔹 **Edit Plan Button**
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        colorScheme.onPrimary,
                      ),
                    ),
                    icon: Icon(Icons.edit, color: colorScheme.onPrimary),
                    label: Text(
                      "Edit Plan",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
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
    );
  }

  /// **✅ Builds a Reusable Plan Card**
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: colorScheme.surfaceContainer,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: colorScheme.primary, size: 30),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
