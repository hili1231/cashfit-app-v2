import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../nav_screen.dart';
import '../../models/workout_program.dart';
import '../../models/meal_plan.dart';
import '../workouts/workout_detail_screen.dart';
import '../diets/meal_plan_screen.dart';
import '../../theme.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  WorkoutProgram? workoutProgram;
  MealPlan? mealPlan;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutId = prefs.getString('generatedWorkoutId');
    final mealPlanId = prefs.getString('generatedMealPlanId');

    if (workoutId != null) {
      final workoutDoc =
          await FirebaseFirestore.instance
              .collection('workout_programs')
              .doc(workoutId)
              .get();
      if (workoutDoc.exists) {
        setState(() {
          workoutProgram = WorkoutProgram.fromMap(
            workoutDoc.data()!,
            workoutDoc.id,
          );
        });
      }
    }

    if (mealPlanId != null) {
      final mealPlanDoc =
          await FirebaseFirestore.instance
              .collection('meal_plans')
              .doc(mealPlanId)
              .get();
      if (mealPlanDoc.exists) {
        setState(() {
          mealPlan = MealPlan.fromMap(mealPlanDoc.data()!);
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    "Your Personalized Plan",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  else ...[
                    if (workoutProgram != null)
                      AppTheme.animatedCard(
                        child: _buildPlanCard(
                          title: workoutProgram!.title,
                          description: workoutProgram!.description,
                          onTap: () {
                            final navState =
                                context
                                    .findAncestorStateOfType<NavScreenState>();
                            if (navState != null) {
                              navState.setDetailScreen(
                                WorkoutDetailScreen(workout: workoutProgram!),
                              );
                            } else {
                              Navigator.push(
                                context,
                                AppTheme.createPageRoute(
                                  WorkoutDetailScreen(workout: workoutProgram!),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (mealPlan != null)
                      AppTheme.animatedCard(
                        child: _buildPlanCard(
                          title: mealPlan!.planName,
                          description: mealPlan!.description,
                          onTap: () {
                            final navState =
                                context
                                    .findAncestorStateOfType<NavScreenState>();
                            if (navState != null) {
                              navState.setDetailScreen(
                                MealPlanScreen(selectedPlan: mealPlan!),
                              );
                            } else {
                              Navigator.push(
                                context,
                                AppTheme.createPageRoute(
                                  MealPlanScreen(selectedPlan: mealPlan!),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () {
                    final navState =
                        context.findAncestorStateOfType<NavScreenState>();
                    if (navState != null) {
                      navState.setDetailScreen(null);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
