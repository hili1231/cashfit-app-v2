import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/meal_plan.dart';
import 'meal_plan_screen.dart';
import '../nav_screen.dart';
import '../../theme.dart';

class DietSelectorScreen extends StatefulWidget {
  const DietSelectorScreen({super.key});

  @override
  State<DietSelectorScreen> createState() => _DietSelectorScreenState();
}

class _DietSelectorScreenState extends State<DietSelectorScreen> {
  List<MealPlan> mealPlans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMealPlans();
  }

  Future<void> _fetchMealPlans() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('mealPlans').get();
    final plans =
        snapshot.docs.map((doc) => MealPlan.fromJson(doc.data())).toList();
    setState(() {
      mealPlans = plans;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        "MEAL PLANS",
                        style: GoogleFonts.oswald(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: mealPlans.length,
                          itemBuilder: (context, index) {
                            return _buildMealPlanCard(
                              context,
                              mealPlans[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMealPlanCard(BuildContext context, MealPlan plan) {
    return GestureDetector(
      onTap: () => _navigateToPlan(context, plan),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      ? plan.days.first.breakfast?.meal.image ?? ''
                      : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(90),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plan.planName.toUpperCase(),
                style: GoogleFonts.oswald(
                  color: Colors.white70,
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
          label.toUpperCase(),
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
