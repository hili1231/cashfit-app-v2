import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/meal_plan_data.dart';
import '../models/diet_category.dart';
import '../models/meal_plan.dart';
import 'meal_plan_screen.dart';
import 'nav_screen.dart';
import '../theme.dart';

class DietSelectorScreen extends StatelessWidget {
  const DietSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // ✅ Transparent background for gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // ✅ Global gradient background
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16,
          ), // ✅ Minimal top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                allDiets.map((category) {
                  return _buildDietCategorySection(context, category);
                }).toList(),
          ),
        ),
      ),
    );
  }

  /// **🔹 Builds a section for each diet category.**
  Widget _buildDietCategorySection(
    BuildContext context,
    DietCategory category,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **Category Title - Now in CAPS & No Icon**
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            category.dietName.toUpperCase(), // ✅ Title in CAPS
            style: GoogleFonts.oswald(
              color: Colors.white70, // ✅ Text in white70
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // **Horizontal Scroll List for Meal Plans**
        SizedBox(
          height: 180, // ✅ Reduced height for a tighter look
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: category.plans.length,
            itemBuilder: (context, index) {
              return _buildMealPlanCard(context, category.plans[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// **🔹 Builds a meal plan card with image, title, and button.**
  Widget _buildMealPlanCard(BuildContext context, MealPlan plan) {
    return GestureDetector(
      onTap: () => _navigateToPlan(context, plan),
      child: Container(
        width: 160, // ✅ Ensures proper card width
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.black, // ✅ Card is black
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Meal Plan Image**
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: SizedBox(
                width: 160,
                height: 90,
                child: Image.asset(
                  plan.days.isNotEmpty
                      ? plan.days.first.breakfast?.image ?? ''
                      : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(90),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // **Plan Name - Now in CAPS**
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plan.planName.toUpperCase(), // ✅ Title in CAPS
                style: GoogleFonts.oswald(
                  color: Colors.white70, // ✅ Text in white70
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildTabButton(
                label: "VIEW PLAN",
                onTap: () => _navigateToPlan(context, plan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Navigates to the Meal Plan screen.**
  void _navigateToPlan(BuildContext context, MealPlan plan) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (navState != null) {
      navState.setDetailScreen(MealPlanScreen(selectedPlan: plan));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealPlanScreen(selectedPlan: plan),
        ),
      );
    }
  }

  /// **🔹 Placeholder image for missing images.**
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

  /// **🔹 A single tab-like button (reusable) with text in white70.**
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
          label.toUpperCase(), // ✅ Button text in CAPS
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70, // ✅ Text in white70
          ),
        ),
      ),
    );
  }
}
