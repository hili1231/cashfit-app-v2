import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/meal_portion.dart';
import '../models/diet_category.dart';
import '../data/meal_data.dart';

/// ✅ Get meals for a specific diet & meal type
List<Meal> getMealsForDietAndType(String diet, String mealType) {
  return mealData
      .where((meal) => meal.category == mealType && meal.diets.contains(diet))
      .toList();
}

/// ✅ Default portion multiplier (can be customized per user later)
const defaultPortion = 1.0;

/// ✅ Generate a Meal Plan (with MealPortions)
MealPlan generateMealPlan(
  String planId,
  String planName,
  String description,
  List<String> diets,
) {
  List<Meal> breakfastMeals = [];
  List<Meal> snackMeals = [];
  List<Meal> lunchMeals = [];
  List<Meal> dinnerMeals = [];

  // ✅ Collect meals from all provided diets
  for (var diet in diets) {
    breakfastMeals.addAll(getMealsForDietAndType(diet, "Breakfast"));
    snackMeals.addAll(getMealsForDietAndType(diet, "Snack"));
    lunchMeals.addAll(getMealsForDietAndType(diet, "Lunch"));
    dinnerMeals.addAll(getMealsForDietAndType(diet, "Dinner"));
  }

  if (breakfastMeals.isEmpty ||
      snackMeals.isEmpty ||
      lunchMeals.isEmpty ||
      dinnerMeals.isEmpty) {
    throw Exception("Not enough meals found for: $planName");
  }

  // ✅ Generate 7 days of meals
  List<MealDay> mealDays = List.generate(7, (index) {
    return MealDay(
      dayNumber: index + 1,
      breakfast: MealPortion(
        meal: breakfastMeals[index % breakfastMeals.length],
        portionMultiplier: defaultPortion,
      ),
      snack1: MealPortion(
        meal: snackMeals[index % snackMeals.length],
        portionMultiplier: defaultPortion,
      ),
      lunch: MealPortion(
        meal: lunchMeals[index % lunchMeals.length],
        portionMultiplier: defaultPortion,
      ),
      snack2: MealPortion(
        meal: snackMeals[(index + 1) % snackMeals.length],
        portionMultiplier: defaultPortion,
      ),
      dinner: MealPortion(
        meal: dinnerMeals[index % dinnerMeals.length],
        portionMultiplier: defaultPortion,
      ),
      snack3: MealPortion(
        meal: snackMeals[(index + 2) % snackMeals.length],
        portionMultiplier: defaultPortion,
      ),
    );
  });

  return MealPlan(
    id: planId,
    planName: planName,
    description: description,
    days: mealDays,
    userId: null, // ✅ null means it's a shared/default plan, not user-specific
  );
}

/// ✅ Sample Meal Plans
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

/// ✅ Categorize all plans under their respective diets
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

/// ✅ Serialize MealPlans for Firestore or local storage
List<Map<String, dynamic>> mealPlansToJson(List<MealPlan> plans) {
  return plans.map((plan) => plan.toJson()).toList();
}

/// ✅ Deserialize MealPlans from Firestore or local storage
List<MealPlan> mealPlansFromJson(List<Map<String, dynamic>> jsonList) {
  return jsonList.map((json) => MealPlan.fromJson(json)).toList();
}
