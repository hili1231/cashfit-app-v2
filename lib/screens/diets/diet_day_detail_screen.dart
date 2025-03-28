import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/meal_day.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_portion.dart';

import '../nav_screen.dart';
import 'meal_plan_screen.dart';
import 'meal_detail_screen.dart';
import '../../theme.dart';

class DietDayDetailScreen extends StatefulWidget {
  final MealPlan plan;
  final MealDay day;

  const DietDayDetailScreen({super.key, required this.plan, required this.day});

  @override
  State<DietDayDetailScreen> createState() => _DietDayDetailScreenState();
}

class _DietDayDetailScreenState extends State<DietDayDetailScreen> {
  late MealDay _day;
  late MealPlan _plan;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _day = widget.day;
    _plan = widget.plan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Day ${_day.dayNumber}",
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
              color: Colors.black87,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () {
                final navState =
                    context.findAncestorStateOfType<NavScreenState>();
                if (navState != null) {
                  navState.setDetailScreen(MealPlanScreen(selectedPlan: _plan));
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        actions: [
          if (_isCustom)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "⚠ You must be logged in to save custom plans",
                      ),
                    ),
                  );
                  return;
                }

                final customPlan = _plan.copyWith(
                  id:
                      "custom_${user.uid}_${DateTime.now().millisecondsSinceEpoch}",
                  userId: user.uid,
                );

                await FirebaseFirestore.instance
                    .collection("mealPlans")
                    .doc(customPlan.id)
                    .set(customPlan.toJson());

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Custom meal plan saved!")),
                );

                setState(() => _isCustom = false);
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
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

  List<Widget> _buildMealsList(BuildContext context) {
    final meals = [
      {"portion": _day.breakfast, "type": "Breakfast"},
      {"portion": _day.snack1, "type": "Snack1"},
      {"portion": _day.lunch, "type": "Lunch"},
      {"portion": _day.snack2, "type": "Snack2"},
      {"portion": _day.dinner, "type": "Dinner"},
      {"portion": _day.snack3, "type": "Snack3"},
    ];

    // Only return cards for non-null meal portions
    return meals.where((m) => m['portion'] != null).map((obj) {
      final portion = obj["portion"] as MealPortion;
      final type = obj["type"] as String;
      return _buildMealCard(context, portion, type);
    }).toList();
  }

  Widget _buildMealCard(
    BuildContext context,
    MealPortion portion,
    String mealType,
  ) {
    final meal = portion.meal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      // The entire container is wrapped in InkWell
      child: InkWell(
        // 1) Tapping anywhere on the container -> open MealDetailScreen
        onTap: () => _navigateToMealDetail(context, meal),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child:
                  meal.image.isNotEmpty
                      ? Image.asset(
                        meal.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _buildPlaceholderImage(200),
                      )
                      : _buildPlaceholderImage(200),
            ),

            // Meal Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType.toUpperCase(),
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${meal.calories.round()} Cal",
                        style: GoogleFonts.oswald(
                          color: Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2) The Replace button is separate, does not affect the rest of the onTap
                  //Align(
                  //  alignment: Alignment.centerLeft,
                  //  child: _buildReplaceButton(
                  //    context: context,
                  //    meal: meal,
                  //    mealType: mealType,
                  //    portion: portion,
                  //  ),
                  //),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Widget _buildReplaceButton({
  //  required BuildContext context,
  //  required Meal meal,
  //  required String mealType,
  //  required MealPortion portion,
  //}) {
  //  return InkWell(
  //    borderRadius: BorderRadius.circular(8),
  //    onTap: () async {
  //      // Show bottom sheet to pick replacements
  //      final replacements =
  //          mealData
  //              .where((m) => m.category == meal.category && m.id != meal.id)
  //              .toList();
  //      final Meal? selected = await showModalBottomSheet<Meal>(
  //        context: context,
  //        backgroundColor: Colors.grey[900],
  //        shape: const RoundedRectangleBorder(
  //          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //        ),
  //        builder: (_) => _buildReplacementModal(context, replacements),
  //      );
  //      if (selected != null) {
  //        setState(() {
  //          // Swap the meal for the day
  //          _day = _day.swapMeal(
  //            mealType.toLowerCase(),
  //            selected,
  //            portion.portionMultiplier,
  //          );
  //          // Update plan with new day
  //          _plan = _plan.copyWith(
  //            days:
  //                _plan.days.map((d) {
  //                  return d.dayNumber == _day.dayNumber ? _day : d;
  //                }).toList(),
  //          );
  //          _isCustom = true;
  //        });
  //      }
  //    },
  //    child: Container(
  //      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  //      decoration: BoxDecoration(
  //        color: const Color.fromARGB(255, 33, 33, 33),
  //        borderRadius: BorderRadius.circular(8),
  //      ),
  //      child: Text(
  //        "Replace",
  //        style: GoogleFonts.oswald(
  //          fontSize: 12,
  //          fontWeight: FontWeight.bold,
  //          color: Colors.white70,
  //        ),
  //      ),
  //    ),
  //  );
  //}
//
  //Widget _buildReplacementModal(BuildContext context, List<Meal> options) {
  //  return ListView.builder(
  //    itemCount: options.length,
  //    itemBuilder: (_, i) {
  //      final m = options[i];
  //      return ListTile(
  //        leading: CircleAvatar(backgroundImage: AssetImage(m.image)),
  //        title: Text(m.name, style: const TextStyle(color: Colors.white70)),
  //        subtitle: Text(
  //          '${m.calories.round()} cal',
  //          style: const TextStyle(color: Colors.amber),
  //        ),
  //        onTap: () => Navigator.pop(context, m),
  //      );
  //    },
  //  );
  //}

  /// Navigate to MealDetailScreen, ignoring "Replace" logic
  void _navigateToMealDetail(BuildContext context, Meal meal) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (navState != null) {
      navState.setDetailScreen(
        MealDetailScreen(plan: _plan, day: _day, meal: meal),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MealDetailScreen(plan: _plan, day: _day, meal: meal),
        ),
      );
    }
  }

  Widget _buildPlaceholderImage(double size) {
    return Container(
      height: size,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 30, color: Colors.white70),
    );
  }
}
