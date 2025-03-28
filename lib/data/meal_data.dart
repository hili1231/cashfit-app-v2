import 'package:cashfit/data/mock_ingredients.dart';
import '../models/meal.dart';
import '../models/meal_ingredient.dart';

final List<Meal> mealData = [
  // 🍳 Breakfast
  Meal(
    id: "1",
    name: "Eggs and Avocado Toast",
    image: "assets/images/avocado_toast.jpg",
    instructions: ["Toast bread", "Mash avocado", "Fry eggs", "Place on toast"],
    diets: ["Balanced", "Mediterranean", "High-Protein"],
    allergies: ["Eggs"],
    category: "Breakfast",
    prepTime: 10,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "egg"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "avocado"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere(
          (i) => i.id == "whole_grain_bread",
        ),
        quantity: 2,
      ),
    ],
  ),

  // 🍌 Snack
  Meal(
    id: "2",
    name: "Greek Yogurt with Banana",
    image: "assets/images/yogurt_banana.jpg",
    instructions: ["Scoop yogurt", "Slice banana", "Mix and serve"],
    diets: ["Balanced", "High-Protein"],
    allergies: [],
    category: "Snack",
    prepTime: 5,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "greek_yogurt"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "banana"),
        quantity: 1,
      ),
    ],
  ),

  // 🍗 Lunch
  Meal(
    id: "3",
    name: "Grilled Chicken with Sweet Potato",
    image: "assets/images/grilled_chicken.jpg",
    instructions: [
      "Grill chicken breast",
      "Boil sweet potato",
      "Serve together",
    ],
    diets: ["Balanced", "High-Protein"],
    allergies: [],
    category: "Lunch",
    prepTime: 20,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chicken_breast"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "sweet_potato"),
        quantity: 200,
      ),
    ],
  ),

  // 🥜 Snack 2
  Meal(
    id: "4",
    name: "Almond Snack Pack",
    image: "assets/images/almond_snack.jpg",
    instructions: ["Portion almonds into container", "Serve"],
    diets: ["Balanced", "Keto"],
    allergies: ["Nuts"],
    category: "Snack",
    prepTime: 2,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "almonds"),
        quantity: 30,
      ),
    ],
  ),

  // 🍚 Dinner
  Meal(
    id: "5",
    name: "Chicken, Rice and Broccoli",
    image: "assets/images/chicken_rice_broccoli.jpg",
    instructions: [
      "Grill chicken",
      "Cook brown rice",
      "Steam broccoli",
      "Serve together",
    ],
    diets: ["Balanced", "High-Protein"],
    allergies: [],
    category: "Dinner",
    prepTime: 25,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chicken_breast"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "brown_rice"),
        quantity: 100,
      ),
    ],
  ),
];
