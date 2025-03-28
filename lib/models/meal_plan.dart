import 'meal_day.dart';
import 'meal.dart';

class MealPlan {
  final String id;
  final String planName;
  final String description;
  final List<MealDay> days;
  final String? userId; // null = global/public plan, otherwise custom
  final String? type; // ✅ NEW: optional type/category

  MealPlan({
    required this.id,
    required this.planName,
    required this.description,
    required this.days,
    this.userId,
    this.type,
  });

  /// 🔁 Swap meal by type and day
  void swapMeal(
    int dayIndex,
    String mealType,
    Meal newMeal,
    double portionMultiplier,
  ) {
    if (dayIndex >= 0 && dayIndex < days.length) {
      days[dayIndex] = days[dayIndex].swapMeal(
        mealType,
        newMeal,
        portionMultiplier,
      );
    }
  }

  /// 🧾 Serialize for Firestore
  Map<String, dynamic> toJson() => {
    'id': id,
    'planName': planName,
    'description': description,
    'userId': userId,
    'type': type,
    'days': days.map((day) => day.toJson()).toList(),
  };

  /// 🔄 Deserialize from Firestore
  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] ?? '',
      planName: json['planName'] ?? '',
      description: json['description'] ?? '',
      userId: json['userId'],
      type: json['type'],
      days:
          (json['days'] as List)
              .map((dayJson) => MealDay.fromJson(dayJson))
              .toList(),
    );
  }

  /// 🪄 Clone with overrides
  MealPlan copyWith({
    String? id,
    String? planName,
    String? description,
    List<MealDay>? days,
    String? userId,
    String? type,
  }) {
    return MealPlan(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      days: days ?? this.days,
      userId: userId ?? this.userId,
      type: type ?? this.type,
    );
  }
}
