import 'meal.dart';

class MealPortion {
  final Meal meal;
  final double portionMultiplier;

  MealPortion({required this.meal, required this.portionMultiplier});

  /// 🔢 Dynamically calculated nutrients based on portion multiplier
  int get adjustedCalories => (meal.calories * portionMultiplier).round();
  double get adjustedProtein => meal.protein * portionMultiplier;
  double get adjustedCarbs => meal.carbs * portionMultiplier;
  double get adjustedFat => meal.fat * portionMultiplier;
  double get adjustedFiber => meal.fiber * portionMultiplier;
  double get adjustedVitaminC => meal.vitaminC * portionMultiplier;
  double get adajustedIron => meal.iron * portionMultiplier;
  double get adjustedVitaminA => meal.vitaminA * portionMultiplier;
  double get adjustedMagnesium => meal.magnesium * portionMultiplier;
  double get adjustedSodium => meal.sodium * portionMultiplier;
  double get adjustedZinc => meal.zinc * portionMultiplier;

  /// 🔄 Convert to Firestore-friendly map
  Map<String, dynamic> toJson() => {
    'meal': meal.toJson(), // Embedded full meal object
    'portionMultiplier': portionMultiplier,
  };

  /// 🧩 Rebuild from Firestore map
  factory MealPortion.fromJson(Map<String, dynamic> json) {
    return MealPortion(
      meal: Meal.fromJson(json['meal']),
      portionMultiplier: (json['portionMultiplier'] ?? 1.0).toDouble(),
    );
  }

  /// 🪄 Clone & modify
  MealPortion copyWith({Meal? meal, double? portionMultiplier}) {
    return MealPortion(
      meal: meal ?? this.meal,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
    );
  }
}
