import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/meal_day.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_portion.dart';
import '../nav_screen.dart';
import 'meal_plan_screen.dart';
import 'meal_detail_screen.dart';

class DietDayDetailScreen extends StatefulWidget {
  final MealPlan plan;
  final MealDay day;

  const DietDayDetailScreen({super.key, required this.plan, required this.day});

  @override
  State<DietDayDetailScreen> createState() => _DietDayDetailScreenState();
}

class _DietDayDetailScreenState extends State<DietDayDetailScreen> {
  late MealDay _cachedDay;
  late MealPlan _cachedPlan;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    // Cache the plan and day data once on initialization
    _cachedDay = widget.day;
    _cachedPlan = widget.plan;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Day ${_cachedDay.dayNumber}",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                MealPlanScreen(selectedPlan: _cachedPlan),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isCustom)
            IconButton(
              icon: Icon(Icons.save_alt, color: colorScheme.onSurface),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (!mounted) return;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "⚠ You must be logged in to save custom plans",
                      ),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                  return;
                }

                // Store ScaffoldMessenger before async operation
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final customPlan = _cachedPlan.copyWith(
                  id:
                      "custom_${user.uid}_${DateTime.now().millisecondsSinceEpoch}",
                  userId: user.uid,
                );

                await FirebaseFirestore.instance
                    .collection("mealPlans")
                    .doc(customPlan.id)
                    .set(customPlan.toMap());

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text("✅ Custom meal plan saved!"),
                    backgroundColor: colorScheme.primary,
                  ),
                );

                setState(() => _isCustom = false);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildMealsList(context, theme, colorScheme),
        ),
      ),
    );
  }

  List<Widget> _buildMealsList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final meals = [
      {"portion": _cachedDay.breakfast, "type": "Breakfast"},
      {"portion": _cachedDay.snack1, "type": "Snack1"},
      {"portion": _cachedDay.lunch, "type": "Lunch"},
      {"portion": _cachedDay.snack2, "type": "Snack2"},
      {"portion": _cachedDay.dinner, "type": "Dinner"},
      {"portion": _cachedDay.snack3, "type": "Snack3"},
    ];

    // Only return cards for non-null meal portions
    return meals.where((m) => m['portion'] != null).map((obj) {
      final portion = obj["portion"] as MealPortion;
      final type = obj["type"] as String;
      return _buildMealCard(context, portion, type, theme, colorScheme);
    }).toList();
  }

  Widget _buildMealCard(
    BuildContext context,
    MealPortion portion,
    String mealType,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final meal = portion.meal;

    return Card(
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToMealDetail(context, meal),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    meal.image.isNotEmpty
                        ? meal.image
                        : 'assets/images/placeholder.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => _buildPlaceholderImage(200, colorScheme),
                errorWidget:
                    (context, url, error) =>
                        _buildPlaceholderImage(200, colorScheme),
                fadeInDuration: const Duration(milliseconds: 200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${meal.calories.round()} Cal",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Uncomment if you want to re-enable the Replace button
                  /*
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildReplaceButton(
                      context: context,
                      meal: meal,
                      mealType: mealType,
                      portion: portion,
                    ),
                  ),
                  */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMealDetail(BuildContext context, Meal meal) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (navState != null) {
      navState.setDetailScreen(
        MealDetailScreen(plan: _cachedPlan, day: _cachedDay, meal: meal),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => MealDetailScreen(
                plan: _cachedPlan,
                day: _cachedDay,
                meal: meal,
              ),
        ),
      );
    }
  }

  Widget _buildPlaceholderImage(double size, ColorScheme colorScheme) {
    return Container(
      height: size,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood,
        size: 30,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
