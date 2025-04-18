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
  Map<String, dynamic> toMap() => {
    "dayNumber": dayNumber,
    if (breakfast != null) "breakfast": breakfast!.toMap(),
    if (snack1 != null) "snack1": snack1!.toMap(),
    if (lunch != null) "lunch": lunch!.toMap(),
    if (snack2 != null) "snack2": snack2!.toMap(),
    if (dinner != null) "dinner": dinner!.toMap(),
    if (snack3 != null) "snack3": snack3!.toMap(),
  };

  /// Create from Firebase snapshot
  factory MealDay.fromMap(Map<String, dynamic> map) {
    return MealDay(
      dayNumber: map["dayNumber"] ?? 1,
      breakfast:
          map["breakfast"] != null
              ? MealPortion.fromMap(map["breakfast"] as Map<String, dynamic>)
              : null,
      snack1:
          map["snack1"] != null
              ? MealPortion.fromMap(map["snack1"] as Map<String, dynamic>)
              : null,
      lunch:
          map["lunch"] != null
              ? MealPortion.fromMap(map["lunch"] as Map<String, dynamic>)
              : null,
      snack2:
          map["snack2"] != null
              ? MealPortion.fromMap(map["snack2"] as Map<String, dynamic>)
              : null,
      dinner:
          map["dinner"] != null
              ? MealPortion.fromMap(map["dinner"] as Map<String, dynamic>)
              : null,
      snack3:
          map["snack3"] != null
              ? MealPortion.fromMap(map["snack3"] as Map<String, dynamic>)
              : null,
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
