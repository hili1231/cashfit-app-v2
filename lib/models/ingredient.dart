class Ingredient {
  final String id;
  final String name;

  // Macronutrients per 100g or standard unit
  final double calories; // kcal
  final double protein; // g
  final double carbs; // g
  final double fat; // g

  // Additional macros and fiber
  final double fiber; // g
  final double sugar; // g
  final double saturatedFat; // g
  final double cholesterol; // mg

  // Vitamins (in mg or mcg)
  final double vitaminA; // mcg
  final double vitaminC; // mg
  final double vitaminD; // mcg
  final double vitaminK; // mcg
  final double vitaminB12; // mcg

  // Minerals (in mg)
  final double iron; // mg
  final double calcium; // mg
  final double potassium; // mg
  final double magnesium; // mg
  final double sodium; // mg
  final double zinc; // mg

  // Glycemic Index (0-100), optional
  final int? glycemicIndex;

  Ingredient({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
    this.cholesterol = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.vitaminK = 0,
    this.vitaminB12 = 0,
    this.iron = 0,
    this.calcium = 0,
    this.potassium = 0,
    this.magnesium = 0,
    this.sodium = 0,
    this.zinc = 0,
    this.glycemicIndex,
  });

  /// 🧾 For Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'saturatedFat': saturatedFat,
    'cholesterol': cholesterol,
    'vitaminA': vitaminA,
    'vitaminC': vitaminC,
    'vitaminD': vitaminD,
    'vitaminK': vitaminK,
    'vitaminB12': vitaminB12,
    'iron': iron,
    'calcium': calcium,
    'potassium': potassium,
    'magnesium': magnesium,
    'sodium': sodium,
    'zinc': zinc,
    if (glycemicIndex != null) 'glycemicIndex': glycemicIndex,
  };

  /// 🔄 From Firestore
  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
    protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
    carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
    fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
    fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
    sugar: (map['sugar'] as num?)?.toDouble() ?? 0.0,
    saturatedFat: (map['saturatedFat'] as num?)?.toDouble() ?? 0.0,
    cholesterol: (map['cholesterol'] as num?)?.toDouble() ?? 0.0,
    vitaminA: (map['vitaminA'] as num?)?.toDouble() ?? 0.0,
    vitaminC: (map['vitaminC'] as num?)?.toDouble() ?? 0.0,
    vitaminD: (map['vitaminD'] as num?)?.toDouble() ?? 0.0,
    vitaminK: (map['vitaminK'] as num?)?.toDouble() ?? 0.0,
    vitaminB12: (map['vitaminB12'] as num?)?.toDouble() ?? 0.0,
    iron: (map['iron'] as num?)?.toDouble() ?? 0.0,
    calcium: (map['calcium'] as num?)?.toDouble() ?? 0.0,
    potassium: (map['potassium'] as num?)?.toDouble() ?? 0.0,
    magnesium: (map['magnesium'] as num?)?.toDouble() ?? 0.0,
    sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
    zinc: (map['zinc'] as num?)?.toDouble() ?? 0.0,
    glycemicIndex: (map['glycemicIndex'] as num?)?.toInt(),
  );
}
