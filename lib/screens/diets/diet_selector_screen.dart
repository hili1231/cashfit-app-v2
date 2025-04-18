import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/meal_plan.dart';
import '../../widgets/meal_card.dart';
import '../../theme.dart';

class DietSelectorScreen extends StatefulWidget {
  const DietSelectorScreen({super.key});

  /// Static cache so we don't re-fetch every time
  static List<MealPlan>? _cachedMealPlans;

  @override
  State<DietSelectorScreen> createState() => _DietSelectorScreenState();
}

class _DietSelectorScreenState extends State<DietSelectorScreen> {
  late Future<List<MealPlan>> _fetchFuture;

  @override
  void initState() {
    super.initState();
    // If cached data is present, use that immediately
    if (DietSelectorScreen._cachedMealPlans != null) {
      _fetchFuture = Future.value(DietSelectorScreen._cachedMealPlans);
    } else {
      // Otherwise fetch from Firestore and store in static cache
      _fetchFuture = _fetchMealPlans().then((plans) {
        DietSelectorScreen._cachedMealPlans = plans;
        return plans;
      });
    }
  }

  Future<List<MealPlan>> _fetchMealPlans() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('mealPlans').get();
    return snapshot.docs.map((doc) => MealPlan.fromMap(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: AppTheme.backgroundGradient(
        colorScheme,
      ), // Add gradient background
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        body: FutureBuilder<List<MealPlan>>(
          future: _fetchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No meal plans found",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            // If we reach here, we have meal plans (either from cache or Firestore)
            final mealPlans = snapshot.data!;

            // Categorize meal plans by type
            final Map<String, List<MealPlan>> categorizedPlans = {};
            for (var plan in mealPlans) {
              final category = plan.type?.trim().toLowerCase() ?? 'general';
              if (!categorizedPlans.containsKey(category)) {
                categorizedPlans[category] = [];
              }
              categorizedPlans[category]!.add(plan);
            }

            // Convert categories to a list for display, with titles capitalized
            final categories =
                categorizedPlans.keys.toList()
                  ..sort(); // Sort categories alphabetically
            final capitalizedCategories =
                categories.map((category) {
                  return category[0].toUpperCase() + category.substring(1);
                }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "MEAL PLANS",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Display each category as a section
                  ...capitalizedCategories.asMap().entries.map((entry) {
                    final category = entry.value;
                    final plans = categorizedPlans[category.toLowerCase()]!;
                    return _buildCategorySection(
                      theme,
                      colorScheme,
                      category,
                      plans,
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    ThemeData theme,
    ColorScheme colorScheme,
    String category,
    List<MealPlan> plans,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240, // Enough space for MealPlanCard
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Padding(
                padding: const EdgeInsets.only(
                  right: 14,
                ), // Space between cards
                child: MealPlanCard(mealPlan: plan),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
