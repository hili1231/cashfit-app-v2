import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../models/meal_portion.dart';
import 'diet_day_detail_screen.dart';
import 'meal_detail_screen.dart';
import '../nav_screen.dart';

class MealPlanScreen extends StatefulWidget {
  final MealPlan selectedPlan;

  const MealPlanScreen({super.key, required this.selectedPlan});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late MealPlan _cachedPlan;

  @override
  void initState() {
    super.initState();
    // Cache the selected plan data once on initialization
    _cachedPlan = widget.selectedPlan;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image (Meal Plan Banner)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPlanImage(colorScheme),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  _cachedPlan.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // For each day in the plan
                ..._cachedPlan.days.map(
                  (day) => _buildDaySection(context, theme, colorScheme, day),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
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
        ],
      ),
    );
  }

  Widget _buildPlanImage(ColorScheme colorScheme) {
    final imageUrl = _getPlanImage();
    return CachedNetworkImage(
      imageUrl:
          imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.jpg',
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => _buildPlaceholderImage(colorScheme, height: 220),
      errorWidget:
          (context, url, error) =>
              _buildPlaceholderImage(colorScheme, height: 220),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  String _getPlanImage() {
    try {
      final mealImage =
          _cachedPlan.days
              .firstWhere((d) => d.breakfast != null)
              .breakfast
              ?.meal
              .image ??
          '';
      return mealImage;
    } catch (_) {
      return '';
    }
  }

  Widget _buildDaySection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    MealDay day,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Day ${day.dayNumber}",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
                onPressed: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.setDetailScreen(
                      DietDayDetailScreen(plan: _cachedPlan, day: day),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DietDayDetailScreen(
                              plan: _cachedPlan,
                              day: day,
                            ),
                      ),
                    );
                  }
                },
                child: Text(
                  "View All",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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

            for (var mp in meals) {
              double estimatedHeight = _estimateTextHeight(
                mp.meal.name,
                theme.textTheme.bodyLarge?.fontSize ?? 16.0,
                2,
              );
              double totalCardHeight = 120 + estimatedHeight + 40;
              if (totalCardHeight > maxHeight) maxHeight = totalCardHeight;
            }

            return SizedBox(
              height: maxHeight + 10,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: meals.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder:
                    (context, index) => _buildMealCard(
                      context,
                      theme,
                      colorScheme,
                      day,
                      meals[index],
                      maxHeight,
                    ),
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
    ThemeData theme,
    ColorScheme colorScheme,
    MealDay day,
    MealPortion mp,
    double maxHeight,
  ) {
    final meal = mp.meal;

    return SizedBox(
      width: 200,
      height: maxHeight,
      child: Card(
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(right: 12),
        elevation: 1,
        child: InkWell(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                MealDetailScreen(plan: _cachedPlan, day: day, meal: meal),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MealDetailScreen(
                        plan: _cachedPlan,
                        day: day,
                        meal: meal,
                      ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      meal.image.isNotEmpty
                          ? meal.image
                          : 'assets/images/placeholder.jpg',
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          _buildPlaceholderImage(colorScheme, height: 110),
                  errorWidget:
                      (context, url, error) =>
                          _buildPlaceholderImage(colorScheme, height: 110),
                  fadeInDuration: const Duration(milliseconds: 200),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(meal.calories * mp.portionMultiplier).round()} Calories",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
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
    final theme = Theme.of(context);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    return textPainter.height;
  }

  Widget _buildPlaceholderImage(
    ColorScheme colorScheme, {
    double height = 100,
  }) {
    return Card(
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Icon(Icons.fastfood, size: 40, color: colorScheme.primary),
      ),
    );
  }
}
