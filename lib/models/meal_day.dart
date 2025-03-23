import 'meal.dart';

class MealDay {
  final int dayNumber;
  Meal? breakfast;
  Meal? snack1;
  Meal? lunch;
  Meal? snack2;
  Meal? dinner;
  Meal? snack3;

  MealDay({
    required this.dayNumber,
    this.breakfast,
    this.snack1,
    this.lunch,
    this.snack2,
    this.dinner,
    this.snack3,
  });

  /// ✅ Swap a meal dynamically
  void swapMeal(String mealType, Meal newMeal) {
    switch (mealType) {
      case "breakfast":
        breakfast = newMeal;
        break;
      case "snack1":
        snack1 = newMeal;
        break;
      case "lunch":
        lunch = newMeal;
        break;
      case "snack2":
        snack2 = newMeal;
        break;
      case "dinner":
        dinner = newMeal;
        break;
      case "snack3":
        snack3 = newMeal;
        break;
      default:
        throw ArgumentError("Invalid meal type: $mealType");
    }
  }

  /// ✅ Convert MealDay to JSON (for database storage)
  Map<String, dynamic> toJson() => {
    "dayNumber": dayNumber,
    "breakfast": breakfast?.toJson(),
    "snack1": snack1?.toJson(),
    "lunch": lunch?.toJson(),
    "snack2": snack2?.toJson(),
    "dinner": dinner?.toJson(),
    "snack3": snack3?.toJson(),
  };

  /// ✅ Convert JSON back into a MealDay object
  factory MealDay.fromJson(Map<String, dynamic> json) {
    return MealDay(
      dayNumber: json["dayNumber"],
      breakfast:
          json["breakfast"] != null ? Meal.fromJson(json["breakfast"]) : null,
      snack1: json["snack1"] != null ? Meal.fromJson(json["snack1"]) : null,
      lunch: json["lunch"] != null ? Meal.fromJson(json["lunch"]) : null,
      snack2: json["snack2"] != null ? Meal.fromJson(json["snack2"]) : null,
      dinner: json["dinner"] != null ? Meal.fromJson(json["dinner"]) : null,
      snack3: json["snack3"] != null ? Meal.fromJson(json["snack3"]) : null,
    );
  }
}
