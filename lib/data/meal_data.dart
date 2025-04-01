import '../../data/mock_ingredients.dart';
import '../models/meal.dart';
import '../models/meal_ingredient.dart';

final List<Meal> mealData = [
  // 1) Spicy Tofu Stir-Fry (Dinner)
  Meal(
    id: "spicy_tofu_stirfry",
    name: "Spicy Tofu Stir-Fry",
    image: "assets/images/spicy_tofu_stirfry.jpg",
    instructions: [
      "Press and cube tofu, then stir-fry with broccoli and red bell pepper.",
      "Add minced garlic, ginger, a splash of soy sauce, and a drizzle of sesame oil.",
      "Finish with a sprinkle of chili flakes and serve hot."
    ],
    diets: ["Vegan", "Gluten-Free", "High Protein"],
    allergies: ["Soy"],
    category: "Dinner",
    prepTime: 25,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tofu"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "broccoli"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "bell_pepper"),
        quantity: 60,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "garlic"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "ginger"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "soy_sauce"),
        quantity: 10,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "sesame_oil"),
        quantity: 5,
      ),
    ],
  ),

  // 2) Herbed Avocado Toast Deluxe (Breakfast)
  Meal(
    id: "herbed_avocado_toast_deluxe",
    name: "Herbed Avocado Toast Deluxe",
    image: "assets/images/herbed_avocado_toast_deluxe.jpg",
    instructions: [
      "Toast slices of whole grain bread until crisp.",
      "Spread mashed avocado mixed with lemon juice, salt, and pepper.",
      "Top with a poached egg and garnish with microgreens."
    ],
    diets: ["Vegetarian", "High Protein"],
    allergies: [],
    category: "Breakfast",
    prepTime: 12,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "whole_grain_bread"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "avocado"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "egg"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "microgreens"),
        quantity: 10,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // 3) Banana Walnut Smoothie Bowl (Breakfast)
  Meal(
    id: "banana_walnut_smoothie_bowl",
    name: "Banana Walnut Smoothie Bowl",
    image: "assets/images/banana_walnut_smoothie_bowl.jpg",
    instructions: [
      "Blend banana with almond milk until smooth.",
      "Pour into a bowl and top with rolled oats, chopped walnuts, honey, and fresh berries.",
      "Serve immediately for a filling breakfast."
    ],
    diets: ["Vegetarian", "Gluten-Free", "High Fiber"],
    allergies: ["Nuts"],
    category: "Breakfast",
    prepTime: 10,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "banana"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "almond_milk"),
        quantity: 200,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "rolled_oats"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "walnuts"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "honey"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "berries"),
        quantity: 50,
      ),
    ],
  ),

  // 4) Quinoa & Black Bean Stuffed Bell Peppers (Dinner)
  Meal(
    id: "quinoa_blackbean_stuffed_peppers",
    name: "Quinoa & Black Bean Stuffed Peppers",
    image: "assets/images/quinoa_blackbean_stuffed_peppers.jpg",
    instructions: [
      "Halve bell peppers and remove seeds.",
      "Mix cooked quinoa with black beans, diced tomato, cumin, and cilantro.",
      "Stuff peppers with the mixture and bake at 180°C for 20 minutes."
    ],
    diets: ["Vegan", "Gluten-Free", "High Fiber"],
    allergies: [],
    category: "Dinner",
    prepTime: 35,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "bell_pepper"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "quinoa"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "black_beans"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cumin"),
        quantity: 3,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cilantro"),
        quantity: 10,
      ),
    ],
  ),

  // 5) Miso Glazed Cod (Dinner)
  Meal(
    id: "miso_glazed_cod",
    name: "Miso Glazed Cod",
    image: "assets/images/miso_glazed_cod.jpg",
    instructions: [
      "Brush cod fillets with a mixture of miso paste and soy sauce.",
      "Bake until the fish is just cooked through.",
      "Serve over jasmine rice and garnish with sliced green onions."
    ],
    diets: ["Pescatarian", "Gluten-Free", "High Protein"],
    allergies: ["Fish", "Soy"],
    category: "Dinner",
    prepTime: 30,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cod"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "miso_paste"),
        quantity: 20,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "soy_sauce"),
        quantity: 10,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "jasmine_rice"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "green_onion"),
        quantity: 10,
      ),
    ],
  ),

  // 6) Falafel Wrap with Tahini Sauce (Lunch)
  Meal(
    id: "falafel_wrap_tahini",
    name: "Falafel Wrap with Tahini Sauce",
    image: "assets/images/falafel_wrap_tahini.jpg",
    instructions: [
      "Prepare falafel from blended chickpeas and spices, and fry until crispy.",
      "Fill pita bread with falafel, lettuce, tomato, and cucumber.",
      "Drizzle generously with tahini sauce and a squeeze of lemon."
    ],
    diets: ["Vegan", "Gluten-Free", "High Protein"],
    allergies: [],
    category: "Lunch",
    prepTime: 25,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chickpeas"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tahini"),
        quantity: 20,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "pita_bread"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lettuce"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cucumber"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // 7) Grilled Chicken Caesar Salad (Lunch)
  Meal(
    id: "grilled_chicken_caesar_salad",
    name: "Grilled Chicken Caesar Salad",
    image: "assets/images/grilled_chicken_caesar_salad.jpg",
    instructions: [
      "Grill chicken breast until charred and slice thinly.",
      "Toss romaine lettuce with a light Caesar dressing and top with chicken and shaved parmesan.",
      "Finish with gluten-free croutons and a squeeze of lemon."
    ],
    diets: ["High Protein", "Gluten-Free"],
    allergies: ["Dairy"],
    category: "Lunch",
    prepTime: 20,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chicken_breast"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "romaine_lettuce"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "caesar_dressing"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "parmesan"),
        quantity: 40,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "croutons"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // 8) Shrimp & Avocado Salad (Lunch)
  Meal(
    id: "shrimp_avocado_salad",
    name: "Shrimp & Avocado Salad",
    image: "assets/images/shrimp_avocado_salad.jpg",
    instructions: [
      "Grill shrimp until pink and cooked through.",
      "Toss mixed greens with sliced avocado, cherry tomatoes, and cucumber.",
      "Drizzle with olive oil and lemon juice, then top with shrimp."
    ],
    diets: ["Pescatarian", "Gluten-Free", "High Protein"],
    allergies: ["Fish"],
    category: "Lunch",
    prepTime: 15,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "shrimp"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "mixed_greens"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "avocado"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cherry_tomatoes"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cucumber"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 10,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // 9) Vegetable Paella (Dinner)
  Meal(
    id: "vegetable_paella",
    name: "Vegetable Paella",
    image: "assets/images/vegetable_paella.jpg",
    instructions: [
      "Sauté onions, garlic, and bell pepper in olive oil.",
      "Add short-grain rice, diced tomatoes, saffron, and vegetable broth; simmer until rice is tender.",
      "Mix in peas and artichoke hearts and garnish with parsley."
    ],
    diets: ["Vegan", "Gluten-Free", "High Fiber"],
    allergies: [],
    category: "Dinner",
    prepTime: 40,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "short_grain_rice"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "onion"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "garlic"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "bell_pepper"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "saffron"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "vegetable_broth"),
        quantity: 250,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "peas"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "artichoke_hearts"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "parsley"),
        quantity: 5,
      ),
    ],
  ),

  // 10) Healthy Chia Pudding with Mixed Berries (Snack)
  Meal(
    id: "chia_pudding_mixed_berries",
    name: "Healthy Chia Pudding with Mixed Berries",
    image: "assets/images/chia_pudding_mixed_berries.jpg",
    instructions: [
      "Mix chia seeds with almond milk and a little honey, and refrigerate overnight.",
      "Top with a mixture of fresh berries and a dash of vanilla extract before serving."
    ],
    diets: ["Vegan", "Gluten-Free", "High Fiber"],
    allergies: ["Nuts"],
    category: "Snack",
    prepTime: 10,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chia_seeds"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "almond_milk"),
        quantity: 200,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "honey"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "berries"),
        quantity: 50,
      ),
      // Optionally, add vanilla if defined
    ],
  ),
];