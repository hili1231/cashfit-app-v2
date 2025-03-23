import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../data/workout_data.dart';
import 'workout_detail_screen.dart';
import '../auth/register_screen.dart'; // <-- Create this screen if user is not logged in
import 'nav_screen.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  String? workoutTitle;
  String? mealPlanTitle;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      workoutTitle = prefs.getString('personalizedWorkout');
      mealPlanTitle = prefs.getString('personalizedMealPlan');
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            "Personalized Plan",
            style: TextStyle(color: Colors.amber),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white54,
          currentIndex: 0,
          onTap:
              (index) => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const NavScreen()),
              ),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildPlanCard(
                  title: "Workout Plan",
                  value: workoutTitle ?? "Not generated yet",
                  icon: Icons.fitness_center_rounded,
                  onTap: workoutTitle != null ? _goToWorkout : null,
                ),
                const SizedBox(height: 20),
                _buildPlanCard(
                  title: "Meal Plan",
                  value: mealPlanTitle ?? "Not generated yet",
                  icon: Icons.lunch_dining_rounded,
                  onTap: mealPlanTitle != null ? _goToMealPlan : null,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const NavScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLoggedIn ? "Back to Home" : "Register to Save Plan",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToWorkout() {
    final workout = workoutPrograms.firstWhere(
      (w) => w.title == workoutTitle,
      orElse: () => workoutPrograms.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
    );
  }

  void _goToMealPlan() {
    // You should store/load the actual MealPlan object for full functionality
    // For now this assumes it's already loaded or retrieved elsewhere
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Meal Plan view not implemented yet.")),
    );
  }
}
