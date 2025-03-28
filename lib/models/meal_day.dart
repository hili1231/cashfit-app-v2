import 'meal_portion.dart';
import 'meal.dart';

class MealDay {
  final int dayNumber;
  final MealPortion? breakfast;
  final MealPortion? snack1;
  final MealPortion? lunch;
  final MealPortion? snack2;
  final MealPortion? dinner;
  final MealPortion? snack3;

  MealDay({
    required this.dayNumber,
    this.breakfast,
    this.snack1,
    this.lunch,
    this.snack2,
    this.dinner,
    this.snack3,
  });

  /// Swap one of the meals with a new one
  MealDay swapMeal(String mealType, Meal newMeal, double portionMultiplier) {
    final updatedPortion = MealPortion(
      meal: newMeal,
      portionMultiplier: portionMultiplier,
    );

    return copyWith(
      breakfast: mealType == "breakfast" ? updatedPortion : breakfast,
      snack1: mealType == "snack1" ? updatedPortion : snack1,
      lunch: mealType == "lunch" ? updatedPortion : lunch,
      snack2: mealType == "snack2" ? updatedPortion : snack2,
      dinner: mealType == "dinner" ? updatedPortion : dinner,
      snack3: mealType == "snack3" ? updatedPortion : snack3,
    );
  }

  /// Convert to Firebase-compatible Map
  Map<String, dynamic> toJson() => {
    "dayNumber": dayNumber,
    "breakfast": breakfast?.toJson(),
    "snack1": snack1?.toJson(),
    "lunch": lunch?.toJson(),
    "snack2": snack2?.toJson(),
    "dinner": dinner?.toJson(),
    "snack3": snack3?.toJson(),
  };

  /// Create from Firebase snapshot
  factory MealDay.fromJson(Map<String, dynamic> json) {
    return MealDay(
      dayNumber: json["dayNumber"] ?? 1,
      breakfast:
          json["breakfast"] != null
              ? MealPortion.fromJson(json["breakfast"])
              : null,
      snack1:
          json["snack1"] != null ? MealPortion.fromJson(json["snack1"]) : null,
      lunch: json["lunch"] != null ? MealPortion.fromJson(json["lunch"]) : null,
      snack2:
          json["snack2"] != null ? MealPortion.fromJson(json["snack2"]) : null,
      dinner:
          json["dinner"] != null ? MealPortion.fromJson(json["dinner"]) : null,
      snack3:
          json["snack3"] != null ? MealPortion.fromJson(json["snack3"]) : null,
    );
  }

  /// For programmatic updates
  MealDay copyWith({
    int? dayNumber,
    MealPortion? breakfast,
    MealPortion? snack1,
    MealPortion? lunch,
    MealPortion? snack2,
    MealPortion? dinner,
    MealPortion? snack3,
  }) {
    return MealDay(
      dayNumber: dayNumber ?? this.dayNumber,
      breakfast: breakfast ?? this.breakfast,
      snack1: snack1 ?? this.snack1,
      lunch: lunch ?? this.lunch,
      snack2: snack2 ?? this.snack2,
      dinner: dinner ?? this.dinner,
      snack3: snack3 ?? this.snack3,
    );
  }
}
