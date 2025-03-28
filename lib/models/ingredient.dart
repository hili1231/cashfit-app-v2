class Ingredient {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  final double fiber;
  final double sugar;
  final double saturatedFat;

  final double vitaminA; // mcg
  final double vitaminC; // mg
  final double vitaminD; // mcg
  final double vitaminK; // mcg
  final double vitaminB12; // mcg

  final double iron; // mg
  final double calcium; // mg
  final double potassium; // mg
  final double magnesium; // mg
  final double sodium; // mg
  final double zinc; // mg

  final double cholesterol; // ✅ in mg
  final int? glycemicIndex; // ✅ optional (0–100)

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
    this.cholesterol = 0,
    this.glycemicIndex,
  });

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
    cholesterol: (json['cholesterol'] ?? 0).toDouble(),
    glycemicIndex: json['glycemicIndex'],
  );

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
    'cholesterol': cholesterol,
    if (glycemicIndex != null) 'glycemicIndex': glycemicIndex,
  };
}
