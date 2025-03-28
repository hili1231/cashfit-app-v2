import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_plan.dart';
import '../screens/nav_screen.dart';

class MealPlanCard extends StatelessWidget {
  final MealPlan mealPlan;

  const MealPlanCard({super.key, required this.mealPlan});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final navScreenState =
              context.findAncestorStateOfType<NavScreenState>();
          navScreenState?.onItemTapped(3);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        child: Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.white70.withAlpha(25),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildMealPlanImage(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  mealPlan.planName,
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${mealPlan.days.length} days",
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanImage() {
    final imagePath = _getPlanImage();
    return Image.asset(
      imagePath,
      height: 110,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
    );
  }

  String _getPlanImage() {
    return mealPlan.days.isNotEmpty &&
            mealPlan.days.first.breakfast?.meal.image != null
        ? mealPlan.days.first.breakfast!.meal.image
        : 'assets/images/placeholder.jpg';
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
    );
  }
}
