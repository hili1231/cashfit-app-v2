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
  Map<String, dynamic> toMap() => {
    'dietName': dietName,
    'image': image,
    'plans': plans.map((plan) => plan.toMap()).toList(),
  };

  /// Deserialize from Firebase
  factory DietCategory.fromMap(Map<String, dynamic> map) => DietCategory(
    dietName: map['dietName'] ?? '',
    image: map['image'] ?? '',
    plans:
        (map['plans'] as List<dynamic>? ?? [])
            .map((planMap) => MealPlan.fromMap(planMap as Map<String, dynamic>))
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
