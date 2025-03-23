import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/diet_category.dart';
import '../data/meal_data.dart';

/// ✅ Get meals for a specific diet & meal type
List<Meal> getMealsForDietAndType(String diet, String mealType) {
  return mealData
      .where((meal) => meal.category == mealType && meal.diets.contains(diet))
      .toList();
}

/// ✅ Generate a Meal Plan (Users Can Modify & Save)
MealPlan generateMealPlan(
  String planId,
  String planName,
  String description, // ✅ Add description parameter
  List<String> diets,
) {
  List<Meal> breakfastMeals = [];
  List<Meal> snackMeals = [];
  List<Meal> lunchMeals = [];
  List<Meal> dinnerMeals = [];

  // ✅ Cycle through available diets and collect meals
  for (var diet in diets) {
    breakfastMeals.addAll(getMealsForDietAndType(diet, "Breakfast"));
    snackMeals.addAll(getMealsForDietAndType(diet, "Snack"));
    lunchMeals.addAll(getMealsForDietAndType(diet, "Lunch"));
    dinnerMeals.addAll(getMealsForDietAndType(diet, "Dinner"));
  }

  // ✅ Ensure we have at least 1 meal for each category
  if (breakfastMeals.isEmpty ||
      snackMeals.isEmpty ||
      lunchMeals.isEmpty ||
      dinnerMeals.isEmpty) {
    throw Exception("Not enough meals for diet: $planName");
  }

  List<MealDay> mealDays = List.generate(7, (index) {
    return MealDay(
      dayNumber: index + 1,
      breakfast: breakfastMeals[index % breakfastMeals.length],
      snack1: snackMeals[index % snackMeals.length],
      lunch: lunchMeals[index % lunchMeals.length],
      snack2: snackMeals[(index + 1) % snackMeals.length],
      dinner: dinnerMeals[index % dinnerMeals.length],
      snack3: snackMeals[(index + 2) % snackMeals.length],
    );
  });

  return MealPlan(
    id: planId,
    planName: planName,
    description: description, // ✅ Assign description
    days: mealDays,
  );
}

/// ✅ Sample Plans (Can Be Modified & Stored)
final MealPlan ketoPlan1 = generateMealPlan(
  "keto-plan-1",
  "Keto Plan A",
  "A structured low-carb meal plan designed for ketosis optimization.",
  ["Keto"],
);

final MealPlan ketoPlan2 = generateMealPlan(
  "keto-plan-2",
  "Keto Plan B",
  "A blend of keto and paleo meals focusing on high protein and healthy fats.",
  ["Keto", "Paleo"],
);

final MealPlan veganPlan1 = generateMealPlan(
  "vegan-plan-1",
  "Vegan Plan A",
  "A plant-based meal plan packed with essential nutrients and protein alternatives.",
  ["Vegan"],
);

final MealPlan mediterraneanPlan = generateMealPlan(
  "mediterranean-plan",
  "Mediterranean Plan",
  "A heart-healthy meal plan rich in whole grains, lean proteins, and olive oil.",
  ["Mediterranean"],
);

/// ✅ Store Multiple Meal Plans
List<DietCategory> allDiets = [
  DietCategory(
    dietName: "Keto",
    image: "assets/images/keto_diet.jpg",
    plans: [ketoPlan1, ketoPlan2],
  ),
  DietCategory(
    dietName: "Vegan",
    image: "assets/images/vegan_diet.jpg",
    plans: [veganPlan1],
  ),
  DietCategory(
    dietName: "Mediterranean",
    image: "assets/images/mediterranean_diet.jpg",
    plans: [mediterraneanPlan],
  ),
];

/// ✅ Convert MealPlan to JSON (For Database Storage)
List<Map<String, dynamic>> mealPlansToJson(List<MealPlan> plans) {
  return plans.map((plan) => plan.toJson()).toList();
}

/// ✅ Convert JSON back to MealPlan (When Loading From Database)
List<MealPlan> mealPlansFromJson(List<Map<String, dynamic>> jsonList) {
  return jsonList.map((json) => MealPlan.fromJson(json)).toList();
}
