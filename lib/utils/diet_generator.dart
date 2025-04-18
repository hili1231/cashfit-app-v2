import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/meal_portion.dart';
import '../models/active_diet_plan.dart';
import '../providers/user_provider.dart';

class DietGenerator {
  /// Calculate daily calorie needs using the Mifflin-St Jeor Equation.
  static double _calculateDailyCalories(AppUser user) {
    double weight = double.tryParse(user.weight) ?? 70.0; // kg
    double height = double.tryParse(user.height) ?? 170.0; // cm
    int age = int.tryParse(user.age) ?? 30;
    String gender = user.gender.toLowerCase();

    // Convert units if necessary
    if (user.height.contains("in")) height *= 2.54; // Convert inches to cm
    if (user.weight.contains("lbs")) weight *= 0.453592; // Convert lbs to kg

    // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
    double bmr = gender == "male"
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    // Adjust for activity level
    double activityMultiplier;
    switch (user.activityLevel) {
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

    // Adjust for diet goal
    switch (user.dietGoal) {
      case "Lose Fat":
        calories *= 0.8; // 20% calorie deficit
        break;
      case "Build Muscle":
        calories *= 1.1; // 10% calorie surplus
        break;
      case "Lose Fat & Build Muscle":
        calories *= 0.95; // Slight deficit
        break;
      case "Maintain Weight":
      default:
        break;
    }

    return calories;
  }

  /// Calculate macro targets (protein, carbs, fat) based on diet preference.
  static Map<String, double> _calculateMacroTargets(
    AppUser user,
    double dailyCalories,
  ) {
    double proteinPercentage, carbsPercentage, fatPercentage;

    switch (user.dietPreference) {
      case "Keto":
        proteinPercentage = 0.25;
        carbsPercentage = 0.05;
        fatPercentage = 0.70;
        break;
      case "High Protein":
        proteinPercentage = 0.40;
        carbsPercentage = 0.35;
        fatPercentage = 0.25;
        break;
      case "Low Carb":
        proteinPercentage = 0.35;
        carbsPercentage = 0.20;
        fatPercentage = 0.45;
        break;
      case "Vegan":
      case "Vegetarian":
        proteinPercentage = 0.25;
        carbsPercentage = 0.50;
        fatPercentage = 0.25;
        break;
      case "Balanced":
      default:
        proteinPercentage = 0.30;
        carbsPercentage = 0.40;
        fatPercentage = 0.30;
        break;
    }

    double proteinGrams = (dailyCalories * proteinPercentage) / 4;
    double carbsGrams = (dailyCalories * carbsPercentage) / 4;
    double fatGrams = (dailyCalories * fatPercentage) / 9;

    return {
      'calories': dailyCalories,
      'protein': proteinGrams,
      'carbs': carbsGrams,
      'fat': fatGrams,
    };
  }

  /// Generate a diet plan for the user based on their preferences.
  static Future<MealPlan> generateDietPlan({
    required BuildContext context, // Add context to access UserProvider
    required int totalDays,
    required int mealFrequency,
    required List<String> mealTimes, required AppUser user,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Calculate calorie and macro targets
      double dailyCalories = _calculateDailyCalories(user);
      Map<String, double> macroTargets = _calculateMacroTargets(user, dailyCalories);

      // Update user macro targets via UserProvider
      await userProvider.updateUserFields({
        'dailyCalorieTarget': macroTargets['calories'],
        'dailyProteinTarget': macroTargets['protein'],
        'dailyCarbsTarget': macroTargets['carbs'],
        'dailyFatTarget': macroTargets['fat'],
      });

      // Initialize macro intake history
      List<Map<String, dynamic>> macroIntakeHistory = [];
      for (int i = 1; i <= totalDays; i++) {
        DateTime date = DateTime.now().add(Duration(days: i - 1));
        String formattedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        macroIntakeHistory.add({
          'date': formattedDate,
          'calories': 0.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        });
      }
      await userProvider.updateUserFields({
        'macroIntakeHistory': macroIntakeHistory,
      });

      // Fetch available meals
      Query<Map<String, dynamic>> mealQuery = FirebaseFirestore.instance
          .collection('meals')
          .where('diets', arrayContains: user.dietPreference)
          .limit(50);

      if (user.dietaryRestrictions.isNotEmpty) {
        for (String restriction in user.dietaryRestrictions) {
          mealQuery = mealQuery.where(
            'allergies',
            arrayContains: restriction,
            isEqualTo: false,
          );
        }
      }

      final mealSnapshot = await mealQuery.get();
      List<Meal> availableMeals =
          mealSnapshot.docs.map((doc) => Meal.fromMap(doc.data()..['id'] = doc.id)).toList();

      if (availableMeals.isEmpty) {
        throw Exception("No meals available for the given dietary preferences and restrictions.");
      }

      // Calculate calories per meal
      double caloriesPerMeal = dailyCalories / mealFrequency;

      // Generate meal days
      List<MealDay> mealDays = [];
      for (int day = 1; day <= totalDays; day++) {
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
            mealTypes = ['breakfast', 'snack1', 'lunch', 'snack2', 'dinner', 'snack3'];
            break;
          default:
            mealTypes = ['lunch', 'dinner']; // Fallback
        }

        for (int mealIndex = 0; mealIndex < mealFrequency; mealIndex++) {
          String mealType = mealTypes[mealIndex];
          String mealCategory = mealType == 'breakfast'
              ? 'Breakfast'
              : mealType.contains('snack')
                  ? 'Snack'
                  : mealType == 'lunch'
                      ? 'Lunch'
                      : 'Dinner';

          // Select and scale meal
          List<Meal> matchingMeals =
              availableMeals.where((meal) => meal.category == mealCategory).toList();
          if (matchingMeals.isEmpty) matchingMeals = availableMeals;

          matchingMeals.shuffle();
          Meal selectedMeal = matchingMeals.first;

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
        mealDays.add(mealDay);
      }

      // Create and save MealPlan as a single document
      MealPlan mealPlan = MealPlan(
        id: const Uuid().v4(),
        planName: "${user.dietPreference} Diet Plan",
        description: "A $totalDays-day diet plan tailored for your goals.",
        days: mealDays,
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
        'activeDietPlans': updatedDietPlans.map((plan) => plan.toMap()).toList(),
      });

      return mealPlan;
    } catch (e) {
      throw Exception("Failed to generate diet plan: ${e.toString()}");
    }
  }
}