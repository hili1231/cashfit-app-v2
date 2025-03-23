import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_day.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../screens/nav_screen.dart';
import 'meal_plan_screen.dart';
import 'meal_detail_screen.dart';
import '../theme.dart';

class DietDayDetailScreen extends StatelessWidget {
  final MealPlan plan;
  final MealDay day;

  const DietDayDetailScreen({super.key, required this.plan, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black, // ✅ Consistent black AppBar
        elevation: 2, // ✅ Slight shadow for better separation
        centerTitle: true,
        title: Text(
          "Day ${day.dayNumber}",
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87, // ✅ Black circle around back button
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () {
                final navState =
                    context.findAncestorStateOfType<NavScreenState>();
                if (navState != null) {
                  navState.setDetailScreen(MealPlanScreen(selectedPlan: plan));
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // ✅ Global gradient background
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildMealsList(context),
          ),
        ),
      ),
    );
  }

  /// ✅ **Generates the meal list dynamically.**
  List<Widget> _buildMealsList(BuildContext context) {
    final List<Map<String, dynamic>> mealItems = [
      if (day.breakfast != null) {"meal": day.breakfast, "type": "Breakfast"},
      if (day.snack1 != null) {"meal": day.snack1, "type": "Snack #1"},
      if (day.lunch != null) {"meal": day.lunch, "type": "Lunch"},
      if (day.snack2 != null) {"meal": day.snack2, "type": "Snack #2"},
      if (day.dinner != null) {"meal": day.dinner, "type": "Dinner"},
      if (day.snack3 != null) {"meal": day.snack3, "type": "Snack #3"},
    ];

    return mealItems.map((obj) {
      final Meal meal = obj["meal"] as Meal;
      final String mealType = obj["type"] as String;
      return _buildMealCard(context, meal, mealType);
    }).toList();
  }

  /// ✅ **Creates a meal card with image, title, and a button.**
  Widget _buildMealCard(BuildContext context, Meal meal, String mealType) {
    return GestureDetector(
      onTap: () {
        // ✅ Navigate to MealDetailScreen.
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(
            MealDetailScreen(plan: plan, day: day, meal: meal),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.black, // ✅ Card is black.
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Meal Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child:
                    meal.image.isNotEmpty
                        ? Image.asset(
                          meal.image,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildPlaceholderImage(200),
                        )
                        : _buildPlaceholderImage(200),
              ),
            ),
            // ✅ Meal Information
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🍽 Meal Type Title (2 fonts bigger)
                  Text(
                    mealType.toUpperCase(),
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 16, // 🔺 Increased font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 📝 Meal Name
                  Text(
                    meal.name,
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 🔥 Calories in Amber
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.amber, // ✅ Now in Amber
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${meal.calories} Cal",
                        style: GoogleFonts.oswald(
                          color: Colors.amber, // ✅ Calories text in Amber
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "View Recipe" Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildTabButton(
                label: "View Recipe",
                onTap: () => _navigateToMealDetail(context, meal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Navigates to the MealDetailScreen.**
  void _navigateToMealDetail(BuildContext context, Meal meal) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (navState != null) {
      navState.setDetailScreen(
        MealDetailScreen(plan: plan, day: day, meal: meal),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MealDetailScreen(plan: plan, day: day, meal: meal),
        ),
      );
    }
  }

  /// ✅ **Placeholder image for missing images.**
  Widget _buildPlaceholderImage(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 30, color: Colors.white70),
    );
  }

  /// ✅ **A single tab-like button (reusable) with text in white70.**
  Widget _buildTabButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 33, 33, 33),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
