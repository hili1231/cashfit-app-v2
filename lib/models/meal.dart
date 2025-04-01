import 'meal_ingredient.dart';

class Meal {
  final String id;
  final String name;
  final String image;
  final List<MealIngredient> ingredients;
  final List<String> instructions;
  final List<String> diets;
  final String category;
  final List<String> allergies;
  final int prepTime;
  final int? cookTime;
  final String? video;
  final List<String>? tags; // ✅ new
  final String? difficulty; // ✅ new

  Meal({
    required this.id,
    required this.name,
    required this.image,
    required this.ingredients,
    required this.instructions,
    required this.diets,
    required this.category,
    required this.allergies,
    required this.prepTime,
    this.cookTime,
    this.video,
    this.tags,
    this.difficulty,
  });

  /// 🔢 Aggregated nutrients from ingredients
  double get calories => ingredients.fold(0.0, (sum, i) => sum + i.calories);
  double get protein => ingredients.fold(0.0, (sum, i) => sum + i.protein);
  double get carbs => ingredients.fold(0.0, (sum, i) => sum + i.carbs);
  double get fat => ingredients.fold(0.0, (sum, i) => sum + i.fat);
  double get fiber => ingredients.fold(0.0, (sum, i) => sum + i.fiber);
  double get vitaminC => ingredients.fold(0.0, (sum, i) => sum + i.vitaminC);
  double get vitaminA => ingredients.fold(0.0, (sum, i) => sum + i.vitaminA);
  double get iron => ingredients.fold(0.0, (sum, i) => sum + i.iron);
  double get magnesium => ingredients.fold(0.0, (sum, i) => sum + i.magnesium);
  double get sodium => ingredients.fold(0.0, (sum, i) => sum + i.sodium);
  double get zinc => ingredients.fold(0.0, (sum, i) => sum + i.zinc);

  double get saturatedFat =>
      ingredients.fold(0.0, (sum, i) => sum + i.ingredient.saturatedFat);
  double get sugar =>
      ingredients.fold(0.0, (sum, i) => sum + i.ingredient.sugar);
  double get cholesterol =>
      ingredients.fold(0.0, (sum, i) => sum + i.ingredient.cholesterol);

  int? get glycemicIndex {
    final valid =
        ingredients
            .map((i) => i.ingredient.glycemicIndex)
            .whereType<int>()
            .toList();
    if (valid.isEmpty) return null;
    return (valid.reduce((a, b) => a + b) / valid.length).round();
  }

  int get totalTime => prepTime + (cookTime ?? 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'instructions': instructions,
    'diets': diets,
    'category': category,
    'allergies': allergies,
    'prepTime': prepTime,
    if (cookTime != null) 'cookTime': cookTime,
    if (video != null) 'video': video,
    if (tags != null) 'tags': tags,
    if (difficulty != null) 'difficulty': difficulty,
  };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    image: json['image'] ?? '',
    ingredients:
        (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => MealIngredient.fromJson(e))
            .toList(),
    instructions: List<String>.from(json['instructions'] ?? []),
    diets: List<String>.from(json['diets'] ?? []),
    category: json['category'] ?? '',
    allergies: List<String>.from(json['allergies'] ?? []),
    prepTime: json['prepTime'] ?? 0,
    cookTime: json['cookTime'],
    video: json['video'],
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    difficulty: json['difficulty'],
  );

  Meal scaledToCalories(double targetCalories) {
    final currentCalories = calories;

    if (currentCalories == 0) return this;

    final scaleFactor = targetCalories / currentCalories;

    final scaledIngredients =
        ingredients.map((i) {
          return MealIngredient(
            ingredient: i.ingredient,
            quantity: i.quantity * scaleFactor,
            unit: i.unit,
          );
        }).toList();

    return Meal(
      id: id,
      name: name,
      image: image,
      ingredients: scaledIngredients,
      instructions: instructions,
      diets: diets,
      category: category,
      allergies: allergies,
      prepTime: prepTime,
      cookTime: cookTime,
      video: video,
      tags: tags,
      difficulty: difficulty,
    );
  }
}
