import '../models/meal_portion.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../data/meal_data.dart';

/// ✅ Default portion multiplier
const defaultPortion = 1.0;

/// ✅ Manually defined meal plan
final List<MealPlan> mealPlanData = [
  MealPlan(
    id: 'balanced_plan_1',
    planName: '3-Day Balanced Meal Plan',
    description:
        'A simple 3-day balanced meal plan with nutrient-rich options.',
    days: [
      MealDay(
        dayNumber: 1,
        breakfast: MealPortion(
          meal: mealData.firstWhere((m) => m.category == "Breakfast"),
          portionMultiplier: defaultPortion,
        ),
        snack1: MealPortion(
          meal: mealData.firstWhere((m) => m.category == "Snack"),
          portionMultiplier: defaultPortion,
        ),
        lunch: MealPortion(
          meal: mealData.firstWhere((m) => m.category == "Lunch"),
          portionMultiplier: defaultPortion,
        ),
        snack2: MealPortion(
          meal: mealData.firstWhere(
            (m) => m.category == "Snack",
            orElse: () => mealData[0],
          ),
          portionMultiplier: defaultPortion,
        ),
        dinner: MealPortion(
          meal: mealData.firstWhere((m) => m.category == "Dinner"),
          portionMultiplier: defaultPortion,
        ),
        snack3: MealPortion(
          meal: mealData.firstWhere(
            (m) => m.category == "Snack",
            orElse: () => mealData[0],
          ),
          portionMultiplier: defaultPortion,
        ),
      ),
      MealDay(
        dayNumber: 2,
        breakfast: MealPortion(
          meal: mealData[1 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack1: MealPortion(
          meal: mealData[2 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        lunch: MealPortion(
          meal: mealData[3 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack2: MealPortion(
          meal: mealData[4 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        dinner: MealPortion(
          meal: mealData[5 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack3: MealPortion(
          meal: mealData[6 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
      ),
      MealDay(
        dayNumber: 3,
        breakfast: MealPortion(
          meal: mealData[7 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack1: MealPortion(
          meal: mealData[8 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        lunch: MealPortion(
          meal: mealData[9 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack2: MealPortion(
          meal: mealData[10 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        dinner: MealPortion(
          meal: mealData[11 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
        snack3: MealPortion(
          meal: mealData[12 % mealData.length],
          portionMultiplier: defaultPortion,
        ),
      ),
    ],
  ),
];
