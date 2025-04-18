import 'package:cashfit/screens/admin/admin_dashboard_screen.dart';
import 'package:cashfit/screens/admin/admin_manage_meals_csv_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_upload_ingredients_screen.dart';
import 'admin_create_meal_screen.dart';
import 'admin_side_hustle_screen.dart';
import 'admin_meal_plan_creator_screen.dart';
import 'admin_exercise_management_screen.dart';
import 'workout_program_management_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Text(
                "Admin Panel",
                style: GoogleFonts.oswald(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildNavTile(
              context,
              "Manage Side Hustles",
              Icons.monetization_on,
              const AdminCreateSideHustleScreen(),
            ),
            _buildNavTile(
              context,
              "Manage Ingredients",
              Icons.science,
              const AdminUploadIngredientsScreen(),
            ),
            _buildNavTile(
              context,
              "Create Meal",
              Icons.restaurant,
              const AdminCreateMealScreen(),
            ),
            _buildNavTile(
              context,
              "Create Meal Plan",
              Icons.menu_book,
              const AdminCreateMealPlanScreen(),
            ),
            _buildNavTile(
              context,
              "Upload CSV",
              Icons.menu_book,
              const AdminManageMealsScreen(),
            ),
            _buildNavTile(
              context,
              "Admin",
              Icons.menu_book,
              const AdminDashboardScreen(),
            ),
            _buildNavTile(
              context,
              "Create exercise",
              Icons.menu_book,
              const AdminExerciseManagementScreen(),
            ),
            _buildNavTile(
              context,
              "Create workout program",
              Icons.menu_book,
              const AdminWorkoutProgramManagementScreen(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          "Welcome to the Admin Dashboard",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  ListTile _buildNavTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
