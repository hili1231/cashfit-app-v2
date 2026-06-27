import '../models/app_user.dart';

class TDEECalculator {
  /// Calculates total daily calories and macros tailored for weight loss or weight maintenance.
  static Map<String, int> calculateTargets(AppUser? user) {
    if (user == null) {
      return {'calories': 2000, 'protein': 150, 'carbs': 200, 'fat': 60};
    }

    double weightKg = double.tryParse(user.weight) ?? 75.0;
    double heightCm = double.tryParse(user.height) ?? 175.0;
    int age = int.tryParse(user.age) ?? 25;
    bool isMale = user.gender.toLowerCase() == 'male';

    // Mifflin-St Jeor Equation for BMR
    double bmr;
    if (isMale) {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    // Activity Multiplier
    double activityMultiplier = 1.375; // Light activity default
    switch (user.activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly active':
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderately active':
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'very active':
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'extra active':
        activityMultiplier = 1.9;
        break;
    }

    double tdee = bmr * activityMultiplier;

    // Weight loss deficit target (500 kcal deficit per day for ~0.5kg/week loss)
    double targetCalories = tdee - 500;
    if (targetCalories < 1200) targetCalories = 1200; // Safe minimum

    // Weight loss macronutrient split: High Protein (35%), Moderate Carbs (40%), Healthy Fats (25%)
    int proteinGrams = ((targetCalories * 0.35) / 4).round();
    int carbsGrams = ((targetCalories * 0.40) / 4).round();
    int fatGrams = ((targetCalories * 0.25) / 9).round();

    return {
      'calories': targetCalories.round(),
      'protein': proteinGrams,
      'carbs': carbsGrams,
      'fat': fatGrams,
    };
  }
}
