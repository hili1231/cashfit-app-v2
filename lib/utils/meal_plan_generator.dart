import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../data/meal_data.dart';

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

  matches.shuffle(); // randomize a bit
  return matches.first;
}

MealPlan generatePersonalizedMealPlan({
  required String dietGoal,
  required String dietPreference,
  required String activityLevel,
  required String weight,
  required String height,
  int days = 3,
}) {
  final List<MealDay> generatedDays = [];

  for (int i = 0; i < days; i++) {
    final day = MealDay(
      dayNumber: i + 1,
      breakfast: getMealByCategory("Breakfast", dietPreference),
      lunch: getMealByCategory("Lunch", dietPreference),
      dinner: getMealByCategory("Dinner", dietPreference),
      snack1: getMealByCategory("Snack", dietPreference),
    );

    generatedDays.add(day);
  }

  return MealPlan(
    id: "generated_meal_${DateTime.now().millisecondsSinceEpoch}",
    planName: "$dietGoal Plan",
    description:
        "Personalized for your goal to $dietGoal with a $dietPreference preference.",
    days: generatedDays,
    isCustom: true,
  );
}
