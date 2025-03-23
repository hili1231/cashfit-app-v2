import 'meal_day.dart';
import 'meal.dart';

class MealPlan {
  final String id;
  final String planName;
  final String description; // ✅ Added description
  List<MealDay> days; // ✅ User can modify days
  bool isCustom; // ✅ Tracks if user modified the plan

  MealPlan({
    required this.id,
    required this.planName,
    required this.description, // ✅ New field
    required this.days,
    this.isCustom = false,
  });

  /// ✅ Swap a meal inside the meal plan
  void swapMeal(int dayIndex, String mealType, Meal newMeal) {
    if (dayIndex >= 0 && dayIndex < days.length) {
      days[dayIndex].swapMeal(mealType, newMeal);
      isCustom = true; // ✅ Mark plan as modified
    }
  }

  /// ✅ Convert MealPlan to JSON for future database storage
  Map<String, dynamic> toJson() => {
    "id": id,
    "planName": planName,
    "description": description, // ✅ Include description
    "isCustom": isCustom,
    "days": days.map((day) => day.toJson()).toList(),
  };

  /// ✅ Convert JSON back into a MealPlan object (for database retrieval)
  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json["id"],
      planName: json["planName"],
      description: json["description"] ?? "", // ✅ Load description
      isCustom: json["isCustom"] ?? false,
      days: (json["days"] as List).map((day) => MealDay.fromJson(day)).toList(),
    );
  }
}
