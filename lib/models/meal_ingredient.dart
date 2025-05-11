import 'ingredient.dart';

class MealIngredient {
  final Ingredient ingredient;
  final double quantity; // numeric value (e.g., 100)
  final String unit; // unit of measure (e.g., "g", "ml", "tbsp")

  MealIngredient({
    required this.ingredient,
    required this.quantity,
    this.unit = 'g', // default to grams
  });

  /// Scales nutrients per 100g/ml/etc.
  double _scale(double value) => (value * quantity) / 100;

  double get calories => _scale(ingredient.calories);
  double get protein => _scale(ingredient.protein);
  double get carbs => _scale(ingredient.carbs);
  double get fat => _scale(ingredient.fat);
  double get fiber => _scale(ingredient.fiber);
  double get sugar => _scale(ingredient.sugar);
  double get saturatedFat => _scale(ingredient.saturatedFat);
  double get vitaminA => _scale(ingredient.vitaminA);
  double get vitaminC => _scale(ingredient.vitaminC);
  double get vitaminD => _scale(ingredient.vitaminD);
  double get vitaminK => _scale(ingredient.vitaminK);
  double get vitaminB12 => _scale(ingredient.vitaminB12);
  double get iron => _scale(ingredient.iron);
  double get calcium => _scale(ingredient.calcium);
  double get potassium => _scale(ingredient.potassium);
  double get magnesium => _scale(ingredient.magnesium);
  double get sodium => _scale(ingredient.sodium);
  double get zinc => _scale(ingredient.zinc);

  Map<String, dynamic> toMap() => {
    'ingredient': ingredient.toMap(),
    'quantity': quantity,
    'unit': unit,
  };

  Map<String, dynamic> toJson() => {
    'ingredient': ingredient.toMap(),
    'quantity': quantity,
    'unit': unit,
  };

  factory MealIngredient.fromMap(Map<String, dynamic> map) {
    return MealIngredient(
      ingredient: Ingredient.fromMap(map['ingredient'] as Map<String, dynamic>),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'g',
    );
  }
}
