import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../models/diet_category.dart';
import '../data/meal_data.dart';

/// ✅ Get meals for a specific diet & meal type
List<Meal> getMealsForDietAndType(String diet, String mealType) {
  final filteredMeals =
      mealData
          .where(
            (meal) => meal.diets.contains(diet) && meal.category == mealType,
          )
          .toList();

  return filteredMeals.isNotEmpty
      ? filteredMeals
      : mealData.where((meal) => meal.category == mealType).toList();
}

/// ✅ Generate a Meal Plan (Repeats Meals if Needed)
MealPlan generateMealPlan(
  String planId,
  String planName,
  String diet,
  String description,
) {
  final breakfastMeals = getMealsForDietAndType(diet, "Breakfast");
  final snackMeals = getMealsForDietAndType(diet, "Snack");
  final lunchMeals = getMealsForDietAndType(diet, "Lunch");
  final dinnerMeals = getMealsForDietAndType(diet, "Dinner");

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
    description: description, // ✅ Added description
    days: mealDays,
  );
}

/// ✅ Hardcoded Meal Plans with Descriptions
final MealPlan ketoPlanA = MealPlan(
  id: "keto-plan-a",
  planName: "Keto Plan A",
  description:
      "A high-fat, low-carb diet designed to promote ketosis and boost fat burning.",
  days: [
    MealDay(
      dayNumber: 1,
      breakfast: mealData.firstWhere((meal) => meal.name == "Cheese Omelette"),
      snack1: mealData.firstWhere((meal) => meal.name == "Protein Bar"),
      lunch: mealData.firstWhere((meal) => meal.name == "Steak & Broccoli"),
      snack2: mealData.firstWhere((meal) => meal.name == "Protein Smoothie"),
      dinner: mealData.firstWhere((meal) => meal.name == "Bacon & Avocado Salad",),
      snack3: mealData.firstWhere((meal) => meal.name == "Greek Salad"),
    ),
        MealDay(
      dayNumber: 1,
      breakfast: mealData.firstWhere((meal) => meal.name == "Cheese Omelette"),
      snack1: mealData.firstWhere((meal) => meal.name == "Protein Bar"),
      lunch: mealData.firstWhere((meal) => meal.name == "Steak & Broccoli"),
      snack2: mealData.firstWhere((meal) => meal.name == "Protein Smoothie"),
      dinner: mealData.firstWhere((meal) => meal.name == "Bacon & Avocado Salad",),
      snack3: mealData.firstWhere((meal) => meal.name == "Greek Salad"),
    ),
  ],
);

/// ✅ Auto-Generated Meal Plans with Descriptions
final MealPlan ketoPlanB = generateMealPlan(
  "keto-plan-b",
  "Keto Plan B",
  "Keto",
  "A structured keto plan with balanced meals to sustain energy and reduce cravings.",
);

final MealPlan ketoPlanC = generateMealPlan(
  "keto-plan-c",
  "Keto Plan C",
  "Keto",
  "A high-protein, high-fat meal plan with essential micronutrients for a well-rounded keto diet.",
);

final MealPlan veganPlanA = generateMealPlan(
  "vegan-plan-a",
  "Vegan Plan A",
  "Vegan",
  "A plant-based meal plan rich in whole foods, vitamins, and sustainable protein sources.",
);

final MealPlan veganPlanB = generateMealPlan(
  "vegan-plan-b",
  "Vegan Plan B",
  "Vegan",
  "A well-balanced vegan diet focused on nutrient-dense, natural plant ingredients.",
);

final MealPlan veganPlanC = generateMealPlan(
  "vegan-plan-c",
  "Vegan Plan C",
  "Vegan",
  "A creative vegan meal plan designed for optimal digestion and energy levels.",
);

final MealPlan mediterraneanPlanA = generateMealPlan(
  "mediterranean-plan-a",
  "Mediterranean Plan A",
  "Mediterranean",
  "A heart-healthy meal plan inspired by Mediterranean cuisine, focusing on fresh vegetables, healthy fats, and lean proteins.",
);

final MealPlan mediterraneanPlanB = generateMealPlan(
  "mediterranean-plan-b",
  "Mediterranean Plan B",
  "Mediterranean",
  "A diverse Mediterranean meal plan including a variety of whole grains, lean meats, and antioxidant-rich foods.",
);

final MealPlan mediterraneanPlanC = generateMealPlan(
  "mediterranean-plan-c",
  "Mediterranean Plan C",
  "Mediterranean",
  "A carefully crafted Mediterranean diet rich in olive oil, seafood, and colorful fruits and vegetables.",
);

/// ✅ Store Multiple Meal Plans for Each Diet Category (3 Each)
List<DietCategory> allDiets = [
  DietCategory(
    dietName: "Balanced",
    image: "assets/images/balanced_diet.jpg",
    plans: [
      generateMealPlan(
        "balanced-plan-a",
        "Balanced Plan A",
        "Balanced",
        "A well-balanced meal plan designed for optimal nutrition and energy levels.",
      ),
      generateMealPlan(
        "balanced-plan-b",
        "Balanced Plan B",
        "Balanced",
        "A balanced diet focusing on lean proteins, whole grains, and essential nutrients.",
      ),
      generateMealPlan(
        "balanced-plan-c",
        "Balanced Plan C",
        "Balanced",
        "A varied meal plan ensuring a mix of macronutrients for overall health.",
      ),
    ],
  ),
  DietCategory(
    dietName: "Keto",
    image: "assets/images/keto_diet.jpg",
    plans: [ketoPlanA, ketoPlanB, ketoPlanC],
  ),
  DietCategory(
    dietName: "Vegan",
    image: "assets/images/vegan_diet.jpg",
    plans: [veganPlanA, veganPlanB, veganPlanC],
  ),
  DietCategory(
    dietName: "Mediterranean",
    image: "assets/images/mediterranean_diet.jpg",
    plans: [mediterraneanPlanA, mediterraneanPlanB, mediterraneanPlanC],
  ),
  DietCategory(
    dietName: "Paleo",
    image: "assets/images/paleo_diet.jpg",
    plans: [
      generateMealPlan(
        "paleo-plan-a",
        "Paleo Plan A",
        "Paleo",
        "A nutrient-dense diet mimicking the eating habits of our ancestors, with a focus on meats, nuts, and fresh vegetables.",
      ),
      generateMealPlan(
        "paleo-plan-b",
        "Paleo Plan B",
        "Paleo",
        "A balanced paleo diet rich in organic ingredients, healthy fats, and unprocessed foods.",
      ),
      generateMealPlan(
        "paleo-plan-c",
        "Paleo Plan C",
        "Paleo",
        "A high-protein paleo plan with an emphasis on lean meats and healthy oils.",
      ),
    ],
  ),
  DietCategory(
    dietName: "High-Protein",
    image: "assets/images/high_protein_diet.jpg",
    plans: [
      generateMealPlan(
        "high-protein-plan-a",
        "High-Protein Plan A",
        "High-Protein",
        "A muscle-building high-protein plan that includes lean meats, dairy, and plant-based protein sources.",
      ),
      generateMealPlan(
        "high-protein-plan-b",
        "High-Protein Plan B",
        "High-Protein",
        "An optimized high-protein diet focusing on muscle repair, recovery, and growth.",
      ),
      generateMealPlan(
        "high-protein-plan-c",
        "High-Protein Plan C",
        "High-Protein",
        "A well-structured high-protein meal plan ideal for active individuals and athletes.",
      ),
    ],
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
