class NutritionCalculator {
  static double calculateBMR({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
  }) {
    if (gender.toLowerCase() == "male") {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
  }

  static double activityMultiplier(String level) {
    switch (level.toLowerCase()) {
      case "sedentary":
        return 1.2;
      case "lightly active":
        return 1.375;
      case "moderately active":
        return 1.55;
      case "very active":
        return 1.725;
      default:
        return 1.2;
    }
  }

  static double adjustForGoal(String goal, double calories) {
    switch (goal.toLowerCase()) {
      case "build muscle":
        return calories + 500;
      case "lose fat":
        return calories - 500;
      case "maintain weight":
      default:
        return calories;
    }
  }

  static Map<String, double> calculateMealBreakdown(double totalCalories) {
    return {
      "breakfast": totalCalories * 0.25,
      "lunch": totalCalories * 0.30,
      "dinner": totalCalories * 0.30,
      "snacks": totalCalories * 0.15,
    };
  }

  static double calculateDailyCalories({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) {
    final bmr = calculateBMR(
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
    );

    final tdee = bmr * activityMultiplier(activityLevel);
    return adjustForGoal(goal, tdee);
  }
}
