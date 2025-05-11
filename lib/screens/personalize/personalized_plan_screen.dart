import 'package:cashfit/models/meal_plan.dart';
import 'package:cashfit/models/workout_program.dart';
import 'package:cashfit/screens/personalize/workout_diet_builder_screen.dart';
import 'package:cashfit/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cashfit/providers/user_provider.dart';
import 'package:cashfit/models/active_workout_program.dart';
import 'package:cashfit/models/active_diet_plan.dart';
import 'package:logger/logger.dart';
import '../workouts/workout_detail_screen.dart';
import '../diets/meal_plan_screen.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  String? workoutPlanId;
  String? mealPlanId;
  WorkoutProgram? workoutProgram;
  MealPlan? mealPlan;
  bool isLoading = true;
  String? errorMessage;
  final CacheService _cacheService = CacheService();
  final Logger _logger = Logger();
  bool _plansAddedToActive = false;

  @override
  void initState() {
    super.initState();
    _loadPlanIds();
  }

  Future<void> _loadPlanIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        workoutPlanId = prefs.getString('generatedWorkoutId');
        mealPlanId = prefs.getString('generatedMealPlanId');
      });

      if (workoutPlanId == null || mealPlanId == null) {
        setState(() {
          errorMessage = "No plans found. Please generate a new plan.";
          isLoading = false;
        });
        return;
      }

      // Fetch the plans from Firestore
      await _fetchPlans();
      
      // Automatically add plans to active programs if not done already
      if (!_plansAddedToActive) {
        await _addPlansToActivePrograms();
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading plans: $e";
        isLoading = false;
      });
    }
  }
  
  Future<void> _addPlansToActivePrograms() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
        _logger.w('User not logged in, cannot add plans to active programs');
        return;
      }
      
      final userId = userProvider.firebaseUser!.uid;
      
      // Add workout program to active workouts
      if (workoutProgram != null && workoutPlanId != null) {
        _logger.i('Adding workout to active programs: ${workoutProgram!.id}');
        
        // Create a reference to the active program document
        final activeProgramRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('activeWorkoutPrograms')
            .doc(workoutPlanId);
        
        // Check if it's already active
        final programDoc = await activeProgramRef.get();
        if (!programDoc.exists) {
          // Add the program to active workouts
          await activeProgramRef.set({
            'workoutProgramId': workoutPlanId,
            'startDate': DateTime.now().toIso8601String(),
            'currentDay': 1,
            'completedDays': [],
          });
          
          _logger.i('Workout added to active programs');
          
          // Update the user's active workout programs
          final activePrograms = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('activeWorkoutPrograms')
              .get();
              
          final mappedPrograms = activePrograms.docs
              .map((doc) => ActiveWorkoutProgram.fromMap(doc.data()))
              .toList();
              
          await userProvider.updateActiveWorkoutPrograms(mappedPrograms);
        }
      }
      
      // Add meal plan to active diet plans
      if (mealPlan != null && mealPlanId != null) {
        _logger.i('Adding diet plan to active diet plans: ${mealPlan!.id}');
        
        // Create a reference to the active diet plan document
        final activePlanRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('activeDietPlans')
            .doc(mealPlanId);
        
        // Check if it's already active
        final planDoc = await activePlanRef.get();
        if (!planDoc.exists) {
          // Add the plan to active diet plans
          await activePlanRef.set({
            'dietPlanId': mealPlanId,
            'startDate': DateTime.now().toIso8601String(),
            'currentDay': 1,
            'completedDays': [],
          });
          
          _logger.i('Diet plan added to active diet plans');
          
          // Update the user's active diet plans
          final activePlans = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('activeDietPlans')
              .get();
              
          final mappedPlans = activePlans.docs
              .map((doc) => ActiveDietPlan.fromMap(doc.data()))
              .toList();
              
          await userProvider.updateActiveDietPlans(mappedPlans);
        }
      }
      
      _plansAddedToActive = true;
    } catch (e) {
      _logger.e('Error adding plans to active programs: $e');
      // Don't fail the screen load if this fails
    }
  }

  Future<void> _fetchPlans() async {
    try {
      // Try to get workout from cache first
      workoutProgram = await _cacheService.getSingleWorkoutProgram(
        workoutPlanId!,
        forceRefresh: false
      );
      
      if (workoutProgram == null) {
        // Fetch Workout Program from Firestore
        final workoutDoc =
            await FirebaseFirestore.instance
                .collection('workoutPrograms')
                .doc(workoutPlanId)
                .get();
                
        if (!workoutDoc.exists) {
          throw Exception("Workout program not found.");
        }
        
        workoutProgram = WorkoutProgram.fromMap(
          workoutDoc.data() as Map<String, dynamic>,
          workoutDoc.id,
        );
        
        // Cache this workout for future use
        await _cacheService.cacheSingleWorkoutProgram(workoutProgram!);
      }

      // Try to get meal plan from cache first
      mealPlan = await _cacheService.getSingleMealPlan(
        mealPlanId!,
        forceRefresh: false
      );
      
      if (mealPlan == null) {
        // Fetch Meal Plan from Firestore
        final mealDoc =
            await FirebaseFirestore.instance
                .collection('mealPlans')
                .doc(mealPlanId)
                .get();
                
        if (!mealDoc.exists) {
          throw Exception("Meal plan not found.");
        }
        
        mealPlan = MealPlan.fromMap(mealDoc.data() as Map<String, dynamic>);
        
        // Cache this meal plan for future use
        await _cacheService.cacheSingleMealPlan(mealPlan!);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching plans: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutDietBuilderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text("Generate a New Plan"),
              ),
            ],
          ),
        ),
      );
    }

    // Determine workout subtitle
    String workoutSubtitle = "Full body, ${workoutProgram!.days.length} days";
    if (workoutProgram!.preferredWorkoutTimes.isNotEmpty) {
      workoutSubtitle +=
          ", ${workoutProgram!.preferredWorkoutTimes.length} days/week";
    }

    // Determine meal plan subtitle
    String mealPlanSubtitle = mealPlan!.type ?? "Custom Diet";

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
                title: workoutProgram!.title,
                subtitle: workoutSubtitle,
                icon: Icons.fitness_center,                onTap: () {
                  // Navigate to detailed workout plan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        workout: workoutProgram!,
                      ),
                    ),
                  );
                },
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 15),

              // 🔹 **Meal Plan Card**
              _buildPlanCard(
                context,
                title: mealPlan!.planName,
                subtitle: mealPlanSubtitle,
                icon: Icons.restaurant_menu,                onTap: () {
                  // Navigate to detailed meal plan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MealPlanScreen(
                        plan: mealPlan!,
                      ),
                    ),
                  );
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const WorkoutDietBuilderScreen(),
                        ),
                      );
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
