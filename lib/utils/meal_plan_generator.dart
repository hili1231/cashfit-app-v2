import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/meal_portion.dart';
import '../data/meal_data.dart';

/// ✅ Get a random meal by category and preference (diet)
Meal? getMealByCategory(String category, String preference) {
  final matches =
      mealData
          .where(
            (meal) =>
                meal.category.toLowerCase() == category.toLowerCase() &&
                meal.diets
                    .map((d) => d.toLowerCase())
                    .contains(preference.toLowerCase()),
          )
          .toList();

  if (matches.isEmpty) return null;

  matches.shuffle(); // ✅ Add randomness
  return matches.first;
}

/// ✅ Portion multiplier based on user data (static for now)
const defaultPortionMultiplier = 1.0;

/// ✅ Generate a personalized Meal Plan using MealPortions
MealPlan generatePersonalizedMealPlan({
  required String dietGoal,
  required String dietPreference,
  required String activityLevel,
  required String weight,
  required String height,
  required String? userId, // ✅ New field to indicate ownership
  int days = 3,
}) {
  final List<MealDay> generatedDays = [];

  for (int i = 0; i < days; i++) {
    MealPortion? wrap(String category) {
      final meal = getMealByCategory(category, dietPreference);
      return meal != null
          ? MealPortion(meal: meal, portionMultiplier: defaultPortionMultiplier)
          : null;
    }

    final day = MealDay(
      dayNumber: i + 1,
      breakfast: wrap("Breakfast"),
      snack1: wrap("Snack"),
      lunch: wrap("Lunch"),
      snack2: wrap("Snack"),
      dinner: wrap("Dinner"),
      snack3: wrap("Snack"),
    );

    generatedDays.add(day);
  }

  return MealPlan(
    id: "generated_meal_${DateTime.now().millisecondsSinceEpoch}",
    planName: "$dietGoal Plan",
    description:
        "Personalized for your goal to $dietGoal with a $dietPreference preference.",
    days: generatedDays,
    userId: userId, // ✅ Indicates this is a user-specific plan
  );
}
