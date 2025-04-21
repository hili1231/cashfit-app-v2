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
  /// Estimate lean body mass (LBM) using the Boer formula.
  static double _estimateLeanBodyMass(AppUser user) {
    double weight = double.tryParse(user.weight) ?? 70.0; // kg
    double height = double.tryParse(user.height) ?? 170.0; // cm
    String gender = user.gender.toLowerCase();

    // Convert units if necessary
    if (user.height.contains("in")) height *= 2.54; // Convert inches to cm
    if (user.weight.contains("lbs")) weight *= 0.453592; // Convert lbs to kg

    // Boer formula for LBM
    if (gender == "male") {
      return 0.407 * weight + 0.267 * height - 19.2;
    } else {
      return 0.252 * weight + 0.473 * height - 48.3;
    }
  }

  /// Calculate daily calorie needs using Katch-McArdle (if LBM available) or Mifflin-St Jeor.
  static Map<String, double> _calculateDailyCalories(AppUser user) {
    double weight = double.tryParse(user.weight) ?? 70.0; // kg
    double height = double.tryParse(user.height) ?? 170.0; // cm
    int age = int.tryParse(user.age) ?? 30;
    String gender = user.gender.toLowerCase();

    // Convert units if necessary
    if (user.height.contains("in")) height *= 2.54; // Convert inches to cm
    if (user.weight.contains("lbs")) weight *= 0.453592; // Convert lbs to kg

    // Estimate LBM
    double lbm = _estimateLeanBodyMass(user);

    // Calculate BMR using Katch-McArdle (preferred) or Mifflin-St Jeor
    double bmr;
    if (lbm > 0) {
      // Katch-McArdle: BMR = 370 + (21.6 * LBM)
      bmr = 370 + (21.6 * lbm);
    } else {
      // Fall back to Mifflin-St Jeor
      bmr =
          gender == "male"
              ? 10 * weight + 6.25 * height - 5 * age + 5
              : 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Adjust for activity level, workout frequency, and intensity
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

    // Adjust activity multiplier based on workout frequency and intensity
    double frequencyAdjustment = user.workoutFrequency / 7.0; // Scale 1-7 days
    double intensityAdjustment;
    switch (user.intensity?.toLowerCase()) {
      case "low":
        intensityAdjustment = 0.05;
        break;
      case "moderate":
        intensityAdjustment = 0.1;
        break;
      case "high":
        intensityAdjustment = 0.15;
        break;
      default:
        intensityAdjustment = 0.0;
    }
    activityMultiplier += frequencyAdjustment * intensityAdjustment;

    // Calculate TDEE for workout and rest days
    double workoutDayCalories =
        bmr * (activityMultiplier + 0.1); // Extra for workout
    double restDayCalories = bmr * activityMultiplier;

    // Adjust for diet goal
    double deficitOrSurplus;
    switch (user.dietGoal) {
      case "Lose Fat":
        deficitOrSurplus = -0.15; // 15% deficit
        break;
      case "Build Muscle":
        deficitOrSurplus = 0.1; // 10% surplus
        break;
      case "Lose Fat & Build Muscle":
        deficitOrSurplus = -0.05; // 5% deficit
        break;
      case "Maintain Weight":
      default:
        deficitOrSurplus = 0.0;
    }

    workoutDayCalories *= (1 + deficitOrSurplus);
    restDayCalories *= (1 + deficitOrSurplus);

    return {'workoutDay': workoutDayCalories, 'restDay': restDayCalories};
  }

  /// Calculate macro targets (protein, carbs, fat) based on diet preference and day type.
  static Map<String, Map<String, double>> _calculateMacroTargets(
    AppUser user,
    double workoutDayCalories,
    double restDayCalories,
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

    // Adjust for workout vs. rest days (e.g., more carbs on workout days)
    Map<String, Map<String, double>> macroTargets = {
      'workoutDay': {},
      'restDay': {},
    };

    // Workout day: Higher carbs, slightly lower fat
    double workoutCarbsPercentage = carbsPercentage + 0.05;
    double workoutFatPercentage = fatPercentage - 0.05;
    double workoutProteinGrams = (workoutDayCalories * proteinPercentage) / 4;
    double workoutCarbsGrams =
        (workoutDayCalories * workoutCarbsPercentage) / 4;
    double workoutFatGrams = (workoutDayCalories * workoutFatPercentage) / 9;

    macroTargets['workoutDay'] = {
      'calories': workoutDayCalories,
      'protein': workoutProteinGrams,
      'carbs': workoutCarbsGrams,
      'fat': workoutFatGrams,
    };

    // Rest day: Lower carbs, slightly higher fat
    double restCarbsPercentage = carbsPercentage - 0.05;
    double restFatPercentage = fatPercentage + 0.05;
    double restProteinGrams = (restDayCalories * proteinPercentage) / 4;
    double restCarbsGrams = (restDayCalories * restCarbsPercentage) / 4;
    double restFatGrams = (restDayCalories * restFatPercentage) / 9;

    macroTargets['restDay'] = {
      'calories': restDayCalories,
      'protein': restProteinGrams,
      'carbs': restCarbsGrams,
      'fat': restFatGrams,
    };

    return macroTargets;
  }

  /// Generate a diet plan for the user based on their preferences.
  static Future<MealPlan> generateDietPlan({
    required BuildContext context,
    required int totalDays,
    required int mealFrequency,
    required List<String> mealTimes,
    required AppUser user,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Calculate calorie and macro targets
      Map<String, double> calorieTargets = _calculateDailyCalories(user);
      Map<String, Map<String, double>> macroTargets = _calculateMacroTargets(
        user,
        calorieTargets['workoutDay']!,
        calorieTargets['restDay']!,
      );

      // Update user macro targets via UserProvider (use workout day as default)
      await userProvider.updateUserFields({
        'dailyCalorieTarget': macroTargets['workoutDay']!['calories'],
        'dailyProteinTarget': macroTargets['workoutDay']!['protein'],
        'dailyCarbsTarget': macroTargets['workoutDay']!['carbs'],
        'dailyFatTarget': macroTargets['workoutDay']!['fat'],
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
          .where('diets', arrayContains: user.dietPreference);

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
          mealSnapshot.docs
              .map((doc) => Meal.fromMap(doc.data()..['id'] = doc.id))
              .toList();

      if (availableMeals.isEmpty) {
        throw Exception(
          "No meals available for the given dietary preferences and restrictions.",
        );
      }

      // Organize meals by category
      Map<String, List<Meal>> mealsByCategory = {
        'Breakfast': [],
        'Snack': [],
        'Lunch': [],
        'Dinner': [],
      };

      for (var meal in availableMeals) {
        if (mealsByCategory.containsKey(meal.category)) {
          mealsByCategory[meal.category]!.add(meal);
        }
      }

      // Track used meals to prevent repetition
      Map<String, List<String>> usedMealIdsByType = {
        'breakfast': [],
        'snack1': [],
        'lunch': [],
        'snack2': [],
        'dinner': [],
        'snack3': [],
      };

      // Determine training days based on user's schedule
      List<String> trainingDays =
          user.availableDays.isNotEmpty
              ? user.availableDays.take(user.workoutFrequency).toList()
              : [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
              ].take(user.workoutFrequency).toList();

      // Generate meal days
      List<MealDay> mealDays = [];
      for (int day = 1; day <= totalDays; day++) {
        DateTime date = DateTime.now().add(Duration(days: day - 1));
        String dayOfWeek =
            [
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday",
              "Saturday",
              "Sunday",
            ][date.weekday - 1];
        bool isWorkoutDay = trainingDays.contains(dayOfWeek);

        // Use appropriate calorie target for the day
        double dailyCalories =
            isWorkoutDay
                ? macroTargets['workoutDay']!['calories']!
                : macroTargets['restDay']!['calories']!;
        double caloriesPerMeal = dailyCalories / mealFrequency;

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

          // Get available meals for this category
          List<Meal> matchingMeals = mealsByCategory[mealCategory]!;
          if (matchingMeals.isEmpty) {
            // Fallback to any available meal if category is empty
            matchingMeals = availableMeals;
            mealCategory = matchingMeals.first.category;
          }

          // Exclude meals already used for this meal type
          List<Meal> unusedMeals =
              matchingMeals
                  .where(
                    (meal) => !usedMealIdsByType[mealType]!.contains(meal.id),
                  )
                  .toList();

          if (unusedMeals.isEmpty) {
            // Reset used meals if we've cycled through all options
            usedMealIdsByType[mealType]!.clear();
            unusedMeals = matchingMeals;
          }

          // Select a random meal from unused meals
          unusedMeals.shuffle();
          Meal selectedMeal = unusedMeals.first;

          // Add to used meals
          usedMealIdsByType[mealType]!.add(selectedMeal.id);

          // Scale meal to target calories per meal
          Meal scaledMeal = selectedMeal.scaledToCalories(caloriesPerMeal);
          MealPortion mealPortion = MealPortion(
            meal: scaledMeal,
            portionMultiplier: 1.0,
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
        'activeDietPlans':
            updatedDietPlans.map((plan) => plan.toMap()).toList(),
      });

      return mealPlan;
    } catch (e) {
      throw Exception("Failed to generate diet plan: ${e.toString()}");
    }
  }
}
