import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_plan.dart';
import '../models/meal_day.dart';
import '../models/meal.dart';
import 'diet_day_detail_screen.dart';
import '../screens/nav_screen.dart';
import '../theme.dart'; // ✅ Import App Theme

class MealPlanScreen extends StatelessWidget {
  final MealPlan selectedPlan; // ✅ Only one meal plan is shown

  const MealPlanScreen({super.key, required this.selectedPlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ Transparent for global gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // ✅ Global gradient background
        ),
        child: Stack(
          children: [
            // ✅ Main Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼 Plan Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _getPlanImage(),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _buildPlaceholderImage(height: 220),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 📜 Plan Description (Instead of Title)
                  Text(
                    selectedPlan.description, // ✅ Shows plan description
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Colors.white70, // ✅ Text in white70
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 📅 Meal Days Sections
                  ...selectedPlan.days.map((day) {
                    return _buildDaySection(context, day);
                  }),
                ],
              ),
            ),
            // 🔙 Floating Back Button (Black Circle)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87, // ✅ Black circle background
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
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
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Get the Meal Plan Image or Use Placeholder**
  String _getPlanImage() {
    return selectedPlan.days.isNotEmpty &&
            selectedPlan.days.first.breakfast?.image != null
        ? selectedPlan.days.first.breakfast!.image
        : 'assets/images/placeholder.jpg';
  }

  /// ✅ **Builds a section for each meal day**
  Widget _buildDaySection(BuildContext context, MealDay day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        // Day Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Day ${day.dayNumber}",
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              _buildTabButton(
                label: "View All",
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.setDetailScreen(
                      DietDayDetailScreen(plan: selectedPlan, day: day),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 🔥 **Dynamically Adjust Card Height**
        LayoutBuilder(
          builder: (context, constraints) {
            // Get max height needed for any card
            double maxHeight = 180; // Base height

            final List<Meal?> meals = [day.breakfast, day.lunch, day.dinner];

            // Adjust max height based on longest text
            for (var meal in meals) {
              if (meal != null) {
                double estimatedHeight = _estimateTextHeight(
                  meal.name,
                  16.0,
                  2,
                );
                double totalCardHeight =
                    120 + estimatedHeight + 30; // Image + Text + Padding
                if (totalCardHeight > maxHeight) {
                  maxHeight = totalCardHeight;
                }
              }
            }

            return SizedBox(
              height: maxHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: meals.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return _buildMealCard(context, day, meals[index], maxHeight);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// ✅ **Builds a Meal Card with Dynamic Height**
  Widget _buildMealCard(
    BuildContext context,
    MealDay day,
    Meal? meal,
    double maxHeight,
  ) {
    if (meal == null) return const SizedBox.shrink();
    return SizedBox(
      width: 200,
      height: maxHeight, // Ensures all cards are the same height
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(right: 12),
        elevation: 3,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                DietDayDetailScreen(plan: selectedPlan, day: day),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Meal Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  meal.image,
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _buildPlaceholderImage(height: 110),
                ),
              ),
              // 📜 Meal Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.oswald(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${meal.calories} Calories",
                      style: GoogleFonts.oswald(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ **Estimate Text Height to Prevent Overflow**
  double _estimateTextHeight(String text, double fontSize, int maxLines) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: GoogleFonts.oswald(fontSize: fontSize)),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150); // Limit width to card width

    return textPainter.height;
  }

  /// ✅ **Reusable Placeholder Image**
  Widget _buildPlaceholderImage({double height = 100}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 40, color: Colors.amber),
    );
  }

  /// ✅ **Reusable Tab Button**
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
