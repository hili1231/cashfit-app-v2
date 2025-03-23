class Meal {
  final String id;
  final String name;
  final String image;
  final int calories;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> diets; // ✅ Assignable diet categories (Keto, Vegan, etc.)
  final String
  category; // ✅ Defines if it is "breakfast", "lunch", "dinner", etc.

  Meal({
    required this.id,
    required this.name,
    required this.image,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    required this.diets,
    required this.category,
  });

  /// ✅ Convert Meal to JSON (for database storage)
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "calories": calories,
    "ingredients": ingredients,
    "instructions": instructions,
    "diets": diets,
    "category": category,
  };

  /// ✅ Convert JSON to Meal (for retrieval from database)
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json["id"],
      name: json["name"],
      image: json["image"],
      calories: json["calories"],
      ingredients: List<String>.from(json["ingredients"]),
      instructions: List<String>.from(json["instructions"]),
      diets: List<String>.from(json["diets"]),
      category: json["category"],
    );
  }
}
