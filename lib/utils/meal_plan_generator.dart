import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/meal_portion.dart';
import '../models/active_diet_plan.dart';
import '../providers/user_provider.dart';

class MealGenerator {
  /// Calculate daily calorie needs using the Mifflin-St Jeor Equation.
  static double _calculateDailyCalories({
    required String weight,
    required String height,
    required String gender,
    required String age,
    required String activityLevel,
  }) {
    double weightValue = double.tryParse(weight) ?? 70.0; // kg
    double heightValue = double.tryParse(height) ?? 170.0; // cm
    int ageValue = int.tryParse(age) ?? 30;
    String genderLower = gender.toLowerCase();

    // Convert units if necessary
    if (height.contains("in")) heightValue *= 2.54; // Convert inches to cm
    if (weight.contains("lbs")) weightValue *= 0.453592; // Convert lbs to kg

    // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
    double bmr =
        genderLower == "male"
            ? 10 * weightValue + 6.25 * heightValue - 5 * ageValue + 5
            : 10 * weightValue + 6.25 * heightValue - 5 * ageValue - 161;

    // Adjust for activity level
    double activityMultiplier;
    switch (activityLevel) {
      case "Sedentary":
        activityMultiplier = 1.2;
        break;
      case "Lightly Active":
        activityMultiplier = 1.375;
        break;
      case "Moderately Active":
        activityMultiplier = 1.55;
        break;
      case "Very Active":
        activityMultiplier = 1.725;
        break;
      default:
        activityMultiplier = 1.2;
    }

    double calories = bmr * activityMultiplier;
    return calories;
  }

  /// Fetch a random meal by category and preference from Firestore.
  static Future<Meal?> getMealByCategory(
    String category,
    String preference,
  ) async {
    try {
      Query<Map<String, dynamic>> mealQuery = FirebaseFirestore.instance
          .collection('meals')
          .where('category', isEqualTo: category)
          .where('diets', arrayContains: preference)
          .limit(10);

      final mealSnapshot = await mealQuery.get();
      List<Meal> matchingMeals =
          mealSnapshot.docs
              .map((doc) => Meal.fromMap(doc.data()..['id'] = doc.id))
              .toList();

      if (matchingMeals.isEmpty) return null;

      matchingMeals.shuffle(); // Add randomness
      return matchingMeals.first;
    } catch (e) {
      throw Exception(
        "Failed to fetch meal for category '$category' and preference '$preference': $e",
      );
    }
  }

  /// Generate a personalized Meal Plan using MealPortions.
  static Future<MealPlan> generatePersonalizedMealPlan({
    required BuildContext context,
    required int days,
    required int mealFrequency,
    required List<String> mealTimes,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Calculate daily calorie needs
      double dailyCalories = _calculateDailyCalories(
        weight: user.weight,
        height: user.height,
        gender: user.gender,
        age: user.age,
        activityLevel: user.activityLevel,
      );

      // Adjust for diet goal
      switch (user.dietGoal) {
        case "Lose Fat":
          dailyCalories *= 0.8; // 20% calorie deficit
          break;
        case "Build Muscle":
          dailyCalories *= 1.1; // 10% calorie surplus
          break;
        case "Lose Fat & Build Muscle":
          dailyCalories *= 0.95; // Slight deficit
          break;
        case "Maintain Weight":
        default:
          break;
      }

      // Calculate calories per meal
      double caloriesPerMeal = dailyCalories / mealFrequency;

      // Generate meal days
      List<MealDay> generatedDays = [];
      for (int day = 1; day <= days; day++) {
        Map<String, MealPortion?> mealsForDay = {
          'breakfast': null,
          'snack1': null,
          'lunch': null,
          'snack2': null,
          'dinner': null,
          'snack3': null,
        };

        // Define meal types based on frequency
        List<String> mealTypes;
        switch (mealFrequency) {
          case 2:
            mealTypes = ['lunch', 'dinner'];
            break;
          case 3:
            mealTypes = ['breakfast', 'lunch', 'dinner'];
            break;
          case 4:
            mealTypes = ['breakfast', 'snack1', 'lunch', 'dinner'];
            break;
          case 5:
            mealTypes = ['breakfast', 'snack1', 'lunch', 'snack2', 'dinner'];
            break;
          case 6:
            mealTypes = [
              'breakfast',
              'snack1',
              'lunch',
              'snack2',
              'dinner',
              'snack3',
            ];
            break;
          default:
            mealTypes = ['lunch', 'dinner']; // Fallback
        }

        for (int mealIndex = 0; mealIndex < mealFrequency; mealIndex++) {
          String mealType = mealTypes[mealIndex];
          String mealCategory =
              mealType == 'breakfast'
                  ? 'Breakfast'
                  : mealType.contains('snack')
                  ? 'Snack'
                  : mealType == 'lunch'
                  ? 'Lunch'
                  : 'Dinner';

          // Fetch and scale meal
          Meal? selectedMeal = await getMealByCategory(
            mealCategory,
            user.dietPreference,
          );
          selectedMeal ??= await getMealByCategory(mealCategory, "Balanced");
          if (selectedMeal == null) {
            throw Exception("No meals available for category '$mealCategory'.");
          }

          // Scale meal to target calories per meal
          Meal scaledMeal = selectedMeal.scaledToCalories(caloriesPerMeal);
          MealPortion mealPortion = MealPortion(
            meal: scaledMeal,
            portionMultiplier: 1.0, // No additional scaling needed
          );

          mealsForDay[mealType] = mealPortion;
        }

        MealDay mealDay = MealDay(
          dayNumber: day,
          breakfast: mealsForDay['breakfast'],
          snack1: mealsForDay['snack1'],
          lunch: mealsForDay['lunch'],
          snack2: mealsForDay['snack2'],
          dinner: mealsForDay['dinner'],
          snack3: mealsForDay['snack3'],
        );
        generatedDays.add(mealDay);
      }

      // Create and save MealPlan as a single document
      MealPlan mealPlan = MealPlan(
        id: const Uuid().v4(),
        planName: "${user.dietPreference} Personalized Plan",
        description: "A $days-day diet plan tailored for your goals.",
        days: generatedDays,
        userId: user.id,
        type: user.dietPreference,
      );

      await FirebaseFirestore.instance
          .collection('mealPlans')
          .doc(mealPlan.id)
          .set(mealPlan.toMap());

      // Update user's active diet plans via UserProvider
      ActiveDietPlan newActiveDietPlan = ActiveDietPlan(
        dietPlanId: mealPlan.id,
        startDate: DateTime.now(),
        currentDay: 1,
        isCompleted: false,
        completedDays: const [],
      );

      List<ActiveDietPlan> updatedDietPlans = [
        ...user.activeDietPlans,
        newActiveDietPlan,
      ];
      await userProvider.updateUserFields({
        'activeDietPlans':
            updatedDietPlans.map((plan) => plan.toMap()).toList(),
      });

      return mealPlan;
    } catch (e) {
      throw Exception("Failed to generate personalized meal plan: $e");
    }
  }
}
