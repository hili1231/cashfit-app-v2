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

  /// 🧾 For Firestore/JSON
  Map<String, dynamic> toJson() => {
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

  /// 🔄 From Firestore/JSON
  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'],
    name: json['name'],
    calories: (json['calories'] ?? 0).toDouble(),
    protein: (json['protein'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    fat: (json['fat'] ?? 0).toDouble(),
    fiber: (json['fiber'] ?? 0).toDouble(),
    sugar: (json['sugar'] ?? 0).toDouble(),
    saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
    cholesterol: (json['cholesterol'] ?? 0).toDouble(),
    vitaminA: (json['vitaminA'] ?? 0).toDouble(),
    vitaminC: (json['vitaminC'] ?? 0).toDouble(),
    vitaminD: (json['vitaminD'] ?? 0).toDouble(),
    vitaminK: (json['vitaminK'] ?? 0).toDouble(),
    vitaminB12: (json['vitaminB12'] ?? 0).toDouble(),
    iron: (json['iron'] ?? 0).toDouble(),
    calcium: (json['calcium'] ?? 0).toDouble(),
    potassium: (json['potassium'] ?? 0).toDouble(),
    magnesium: (json['magnesium'] ?? 0).toDouble(),
    sodium: (json['sodium'] ?? 0).toDouble(),
    zinc: (json['zinc'] ?? 0).toDouble(),
    glycemicIndex: json['glycemicIndex'],
  );
}
