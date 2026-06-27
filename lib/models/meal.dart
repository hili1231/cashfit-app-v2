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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image': image,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
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

  factory Meal.fromMap(Map<String, dynamic> map) {
    String rawImg = map['image'] ?? map['imageUrl'] ?? '';
    if (rawImg.isEmpty || rawImg.startsWith('assets/') || rawImg.contains('firebasestorage.googleapis.com')) {
      final mealName = (map['name'] as String? ?? '').toLowerCase();
      if (mealName.contains('egg') || mealName.contains('scramble')) {
        rawImg = 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80';
      } else if (mealName.contains('chicken') || mealName.contains('salad')) {
        rawImg = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80';
      } else if (mealName.contains('oatmeal') || mealName.contains('berry')) {
        rawImg = 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?auto=format&fit=crop&w=600&q=80';
      } else if (mealName.contains('salmon') || mealName.contains('fish')) {
        rawImg = 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=600&q=80';
      } else {
        rawImg = 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80';
      }
    }
    return Meal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: rawImg,
      ingredients:
          (map['ingredients'] as List<dynamic>? ?? [])
              .map((e) => MealIngredient.fromMap(e as Map<String, dynamic>))
              .toList(),
      instructions: List<String>.from(map['instructions'] ?? []),
      diets: List<String>.from(map['diets'] ?? []),
      category: map['category'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      prepTime: (map['prepTime'] as num?)?.toInt() ?? 0,
      cookTime: (map['cookTime'] as num?)?.toInt(),
      video: map['video'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      difficulty: map['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'diets': diets,
      'category': category,
      'allergies': allergies,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'video': video,
      'tags': tags,
      'difficulty': difficulty,
    };
  }

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

  Meal copyWith({
    String? id,
    String? name,
    String? image,
    List<MealIngredient>? ingredients,
    List<String>? instructions,
    List<String>? diets,
    String? category,
    List<String>? allergies,
    int? prepTime,
    int? cookTime,
    String? video,
    List<String>? tags,
    String? difficulty,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      diets: diets ?? this.diets,
      category: category ?? this.category,
      allergies: allergies ?? this.allergies,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      video: video ?? this.video,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
