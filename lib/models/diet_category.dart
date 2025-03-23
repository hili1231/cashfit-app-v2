import 'meal_plan.dart';

/// Represents a category of diets (e.g., Keto, Vegan, Balanced, Mediterranean).
class DietCategory {
  final String dietName; // "Balanced", "Keto", "Vegan", "Mediterranean", etc.
  final String image; // Image for the diet card (optional)
  final List<MealPlan> plans; // A list of meal plans under this diet

  DietCategory({
    required this.dietName,
    required this.image,
    required this.plans,
  });
}
