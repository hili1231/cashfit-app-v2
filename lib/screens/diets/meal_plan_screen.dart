import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../models/meal_portion.dart';
import 'diet_day_detail_screen.dart';
import 'meal_detail_screen.dart'; // <--- Import your MealDetailScreen
import '../nav_screen.dart';
import '../../theme.dart';

class MealPlanScreen extends StatelessWidget {
  final MealPlan selectedPlan;

  const MealPlanScreen({super.key, required this.selectedPlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Image (Meal Plan Banner)
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

                  // Description
                  Text(
                    selectedPlan.description,
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // For each day in the plan
                  ...selectedPlan.days.map((day) {
                    return _buildDaySection(context, day);
                  }),
                ],
              ),
            ),

            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
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

  String _getPlanImage() {
    try {
      // Attempt to grab the breakfast image from the first day if available
      final mealImage =
          selectedPlan.days
              .firstWhere((d) => d.breakfast != null)
              .breakfast
              ?.meal
              .image ??
          '';
      return mealImage.isNotEmpty ? mealImage : 'assets/images/placeholder.jpg';
    } catch (_) {
      return 'assets/images/placeholder.jpg';
    }
  }

  Widget _buildDaySection(BuildContext context, MealDay day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        // Day Title + "View All"
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
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DietDayDetailScreen(
                              plan: selectedPlan,
                              day: day,
                            ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Meals List
        LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = 180;
            final meals =
                [
                  day.breakfast,
                  day.snack1,
                  day.lunch,
                  day.snack2,
                  day.dinner,
                  day.snack3,
                ].whereType<MealPortion>().toList();

            // Estimate how tall each meal card might be to size the list
            for (var mp in meals) {
              double estimatedHeight = _estimateTextHeight(
                mp.meal.name,
                16.0,
                2,
              );
              double totalCardHeight = 120 + estimatedHeight + 40;
              if (totalCardHeight > maxHeight) {
                maxHeight = totalCardHeight;
              }
                        }

            return SizedBox(
              height: maxHeight + 10,
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

  Widget _buildMealCard(
    BuildContext context,
    MealDay day,
    MealPortion mp,
    double maxHeight,
  ) {
    final meal = mp.meal;

    return SizedBox(
      width: 200,
      height: maxHeight,
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(right: 12),
        elevation: 3,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 🔑 Navigate to the *MealDetailScreen* (not the DietDayDetailScreen).
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                MealDetailScreen(plan: selectedPlan, day: day, meal: meal),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MealDetailScreen(
                        plan: selectedPlan,
                        day: day,
                        meal: meal,
                      ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  meal.image.isNotEmpty
                      ? meal.image
                      : 'assets/images/placeholder.jpg',
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _buildPlaceholderImage(height: 110),
                ),
              ),
              // Meal Info
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
                      "${(meal.calories * mp.portionMultiplier).round()} Calories",
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

  double _estimateTextHeight(String text, double fontSize, int maxLines) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: GoogleFonts.oswald(fontSize: fontSize)),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);

    return textPainter.height;
  }

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
