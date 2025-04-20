import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/meal_plan.dart';
import '../screens/nav_screen.dart';
import '../screens/diets/meal_plan_screen.dart';
import '../theme.dart';

class MealPlanCard extends StatelessWidget {
  final MealPlan mealPlan;

  const MealPlanCard({super.key, required this.mealPlan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = mealPlan.days.length;

    return AnimatedCard(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 180,
        height: 240,
        child: GestureDetector(
          onTap: () {
            final navScreenState =
                context.findAncestorStateOfType<NavScreenState>();
            if (navScreenState != null) {
              navScreenState.setDetailScreen(
                MealPlanScreen(selectedPlan: mealPlan),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MealPlanScreen(selectedPlan: mealPlan),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: _buildMealPlanImage(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  mealPlan.planName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "$totalDays days",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: FilledButton(
                  onPressed: () {
                    final navScreenState =
                        context.findAncestorStateOfType<NavScreenState>();
                    if (navScreenState != null) {
                      navScreenState.setDetailScreen(
                        MealPlanScreen(selectedPlan: mealPlan),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MealPlanScreen(selectedPlan: mealPlan),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "View Plan",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
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
    final imageUrl =
        (mealPlan.days.isNotEmpty &&
                mealPlan.days.first.breakfast?.meal.image != null)
            ? mealPlan.days.first.breakfast!.meal.image
            : '';

    if (imageUrl.isEmpty) {
      return Container(
        height: 80,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 80,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder:
          (context, url) => Container(
            height: 80,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
          ),
      errorWidget:
          (context, url, error) => Container(
            height: 80,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
          ),
      memCacheWidth: 320,
      maxWidthDiskCache: 320,
    );
  }
}
