import '../../data/mock_ingredients.dart';
import '../models/meal.dart';
import '../models/meal_ingredient.dart';

const String sampleCookingVideo = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";

final List<Meal> mealData = [
  // 1) Spicy Tofu Stir-Fry (Dinner)
  Meal(
    id: "spicy_tofu_stirfry",
    name: "Spicy Tofu Stir-Fry",
    image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Press and cube tofu, then stir-fry with broccoli and red bell pepper.",
      "Add minced garlic, ginger, a splash of soy sauce, and a drizzle of sesame oil.",
      "Finish with a sprinkle of chili flakes and serve hot over brown rice."
    ],
    diets: ["Vegan", "Gluten-Free", "High Protein"],
    allergies: ["Soy"],
    category: "Dinner",
    prepTime: 25,
    video: sampleCookingVideo,
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
    image: "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Toast slices of whole grain artisan bread until golden crisp.",
      "Spread thick mashed ripe avocado mixed with lemon juice, salt, and black pepper.",
      "Top with a warm poached egg and garnish with fresh microgreens."
    ],
    diets: ["Vegetarian", "High Protein"],
    allergies: [],
    category: "Breakfast",
    prepTime: 12,
    video: sampleCookingVideo,
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
    image: "https://images.unsplash.com/photo-1590301157890-4810ed352733?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Blend frozen banana slices with almond milk until creamy and thick.",
      "Pour into a chilled bowl and top with rolled oats, chopped walnuts, honey, and fresh berries.",
      "Serve immediately for an energizing breakfast."
    ],
    diets: ["Vegetarian", "Gluten-Free", "High Fiber"],
    allergies: ["Nuts"],
    category: "Breakfast",
    prepTime: 10,
    video: sampleCookingVideo,
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
    image: "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Halve large bell peppers and remove seeds.",
      "Mix fluffy cooked quinoa with black beans, diced tomatoes, ground cumin, and fresh cilantro.",
      "Stuff peppers with the mixture and bake at 180°C for 20 minutes until tender."
    ],
    diets: ["Vegan", "Gluten-Free", "High Fiber"],
    allergies: [],
    category: "Dinner",
    prepTime: 35,
    video: sampleCookingVideo,
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
    image: "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Brush tender cod fillets generously with a mixture of white miso paste and low-sodium soy sauce.",
      "Broil or bake until fish flakes easily with a fork.",
      "Serve hot over warm jasmine rice garnished with sliced green onions."
    ],
    diets: ["Pescatarian", "Gluten-Free", "High Protein"],
    allergies: ["Fish", "Soy"],
    category: "Dinner",
    prepTime: 30,
    video: sampleCookingVideo,
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
    image: "https://images.unsplash.com/photo-1561651823-34feb02250e4?auto=format&fit=crop&w=800&q=80",
    instructions: [
      "Prepare golden falafel balls from spiced blended chickpeas and fry until crispy.",
      "Fill warm pita pockets with crunchy lettuce, ripe tomatoes, cucumbers, and falafel.",
      "Drizzle generously with smooth tahini sauce and freshly squeezed lemon juice."
    ],
    diets: ["Vegan", "Gluten-Free", "High Protein"],
    allergies: [],
    category: "Lunch",
    prepTime: 25,
    video: sampleCookingVideo,
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
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),
];