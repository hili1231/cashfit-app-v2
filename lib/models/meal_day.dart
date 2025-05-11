import 'meal.dart';
import 'meal_portion.dart';

class MealDay {
  final int dayNumber;
  final MealPortion? breakfast;
  final MealPortion? snack1;
  final MealPortion? lunch;
  final MealPortion? snack2;
  final MealPortion? dinner;
  final MealPortion? snack3;
  final bool isFasting; // New flag for fasting days

  MealDay({
    required this.dayNumber,
    this.breakfast,
    this.snack1,
    this.lunch,
    this.snack2,
    this.dinner,
    this.snack3,
    this.isFasting = false,
  });

  MealDay swapMeal(String mealType, Meal newMeal, double portionMultiplier) {
    return MealDay(
      dayNumber: dayNumber,
      breakfast:
          mealType == 'Breakfast'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : breakfast,
      snack1:
          mealType == 'Snack1'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : snack1,
      lunch:
          mealType == 'Lunch'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : lunch,
      snack2:
          mealType == 'Snack2'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : snack2,
      dinner:
          mealType == 'Dinner'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : dinner,
      snack3:
          mealType == 'Snack3'
              ? MealPortion(meal: newMeal, portionMultiplier: portionMultiplier)
              : snack3,
      isFasting: isFasting,
    );
  }

  MealDay copyWith({
    int? dayNumber,
    MealPortion? breakfast,
    MealPortion? snack1,
    MealPortion? lunch,
    MealPortion? snack2,
    MealPortion? dinner,
    MealPortion? snack3,
    bool? isFasting,
  }) {
    return MealDay(
      dayNumber: dayNumber ?? this.dayNumber,
      breakfast: breakfast ?? this.breakfast,
      snack1: snack1 ?? this.snack1,
      lunch: lunch ?? this.lunch,
      snack2: snack2 ?? this.snack2,
      dinner: dinner ?? this.dinner,
      snack3: snack3 ?? this.snack3,
      isFasting: isFasting ?? this.isFasting,
    );
  }

  Map<String, dynamic> toMap() => {
    'dayNumber': dayNumber,
    if (breakfast != null) 'breakfast': breakfast!.toMap(),
    if (snack1 != null) 'snack1': snack1!.toMap(),
    if (lunch != null) 'lunch': lunch!.toMap(),
    if (snack2 != null) 'snack2': snack2!.toMap(),
    if (dinner != null) 'dinner': dinner!.toMap(),
    if (snack3 != null) 'snack3': snack3!.toMap(),
    'isFasting': isFasting,
  };

  factory MealDay.fromMap(Map<String, dynamic> map) {
    return MealDay(
      dayNumber: map['dayNumber'] ?? 1,
      breakfast:
          map['breakfast'] != null
              ? MealPortion.fromMap(map['breakfast'] as Map<String, dynamic>)
              : null,
      snack1:
          map['snack1'] != null
              ? MealPortion.fromMap(map['snack1'] as Map<String, dynamic>)
              : null,
      lunch:
          map['lunch'] != null
              ? MealPortion.fromMap(map['lunch'] as Map<String, dynamic>)
              : null,
      snack2:
          map['snack2'] != null
              ? MealPortion.fromMap(map['snack2'] as Map<String, dynamic>)
              : null,
      dinner:
          map['dinner'] != null
              ? MealPortion.fromMap(map['dinner'] as Map<String, dynamic>)
              : null,
      snack3:
          map['snack3'] != null
              ? MealPortion.fromMap(map['snack3'] as Map<String, dynamic>)
              : null,
      isFasting: map['isFasting'] ?? false,
    );
  }
}
