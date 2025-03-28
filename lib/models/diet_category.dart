import 'meal_plan.dart';

/// Represents a category of diets (e.g., Keto, Vegan, Balanced, Mediterranean).
class DietCategory {
  final String dietName; // e.g., "Balanced", "Keto", etc.
  final String image; // Image URL or asset path
  final List<MealPlan> plans; // Meal plans in this category

  DietCategory({
    required this.dietName,
    required this.image,
    required this.plans,
  });

  /// Serialize for Firebase
  Map<String, dynamic> toJson() => {
    'dietName': dietName,
    'image': image,
    'plans': plans.map((plan) => plan.toJson()).toList(),
  };

  /// Deserialize from Firebase
  factory DietCategory.fromJson(Map<String, dynamic> json) => DietCategory(
    dietName: json['dietName'] ?? '',
    image: json['image'] ?? '',
    plans:
        (json['plans'] as List<dynamic>? ?? [])
            .map((planJson) => MealPlan.fromJson(planJson))
            .toList(),
  );

  /// Optional: copyWith for immutability
  DietCategory copyWith({
    String? dietName,
    String? image,
    List<MealPlan>? plans,
  }) {
    return DietCategory(
      dietName: dietName ?? this.dietName,
      image: image ?? this.image,
      plans: plans ?? this.plans,
    );
  }
}
