import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/meal_plan.dart';
import '../screens/nav_screen.dart';
import '../screens/diets/meal_plan_screen.dart';
import '../theme.dart';

class MealPlanCard extends StatelessWidget {
  final MealPlan mealPlan;
  final int? currentDay;
  final VoidCallback? onDayButtonPressed;

  const MealPlanCard({
    super.key,
    required this.mealPlan,
    this.currentDay,
    this.onDayButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = mealPlan.days.length;

    return AnimatedCard(
      child: Container(
        width: 190,
        height: 240,
        decoration: AppTheme.glassCardDecoration(colorScheme),
        child: GestureDetector(
          onTap: () {
            final navScreenState = context.findAncestorStateOfType<NavScreenState>();
            navScreenState?.setDetailScreen(MealPlanScreen(plan: mealPlan));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _buildMealPlanImage(context),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu, color: colorScheme.secondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "$totalDays Days",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(
                  mealPlan.planName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                    onPressed: onDayButtonPressed ??
                        () {
                          final navState = context.findAncestorStateOfType<NavScreenState>();
                          navState?.setDetailScreen(MealPlanScreen(plan: mealPlan));
                        },
                    child: Text(
                      currentDay != null ? "Day $currentDay" : "View Diet",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = (mealPlan.days.isNotEmpty &&
            mealPlan.days.first.breakfast?.meal.image != null)
        ? mealPlan.days.first.breakfast!.meal.image
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80';

    return CachedNetworkImage(
      imageUrl: imageUrl.startsWith('http') ? imageUrl : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        height: 100,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fastfood, size: 44, color: colorScheme.secondary),
      ),
      errorWidget: (context, url, error) => Container(
        height: 100,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.restaurant_menu, size: 44, color: colorScheme.secondary),
      ),
    );
  }
}
