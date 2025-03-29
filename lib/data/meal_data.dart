import '../../data/mock_ingredients.dart';
import '../models/meal.dart';
import '../models/meal_ingredient.dart';

final List<Meal> mealData = [
  // ----------------------------------------------------
  // 5 BREAKFASTS
  // ----------------------------------------------------

  // 1) Vegan Overnight Oats (Breakfast)
  Meal(
    id: "vegan_overnight_oats",
    name: "Vegan Overnight Oats",
    image: "assets/images/overnight_oats.jpg",
    instructions: [
      "Combine rolled oats, plant-based milk, and chia seeds in a jar.",
      "Refrigerate overnight.",
      "Top with mixed berries and a sprinkle of cinnamon before serving.",
    ],
    diets: [
      "Vegan",
      "Dairy-Free",
      "Nut-Free",
      "High Fiber",
      "Low Fat",
      "Low Sugar",
      "FODMAP Friendly",
      "Gluten-Free",
    ],
    allergies: [],
    category: "Breakfast",
    prepTime: 5,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "rolled_oats"),
        quantity: 50,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "plant_milk"),
        quantity: 200,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chia_seeds"),
        quantity: 10,
      ),
      MealIngredient(
        // Assuming you added a "berries" ingredient in your mockIngredients file
        ingredient: mockIngredients.firstWhere((i) => i.id == "berries"),
        quantity: 50,
      ),
    ],
  ),

  // 2) Mediterranean Avocado Toast (Breakfast)
  Meal(
    id: "mediterranean_avocado_toast",
    name: "Mediterranean Avocado Toast",
    image: "assets/images/avocado_toast.jpg",
    instructions: [
      "Toast whole grain bread.",
      "Mash avocado with lemon juice, salt, and pepper.",
      "Top with diced tomato and drizzle olive oil.",
    ],
    diets: [
      "Vegan",
      "Vegetarian",
      "Mediterranean",
      "Balanced",
      "Low Sugar",
      "High Fiber",
      "Gluten-Free", // if using GF bread variant
    ],
    allergies: [],
    category: "Breakfast",
    prepTime: 10,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere(
          (i) => i.id == "whole_grain_bread",
        ),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "avocado"),
        quantity: 1,
      ),
      MealIngredient(
        // Assuming tomato exists
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 5, // in ml
      ),
    ],
  ),

  // 3) Egg & Spinach Scramble (Breakfast)
  Meal(
    id: "egg_spinach_scramble",
    name: "Egg & Spinach Scramble",
    image: "assets/images/egg_scramble.jpg",
    instructions: [
      "Whisk eggs with salt and pepper.",
      "Sauté spinach in a non-stick pan.",
      "Pour eggs over spinach and scramble until fluffy.",
    ],
    diets: [
      "Balanced",
      "High Protein",
      "Low Carb",
      "Nut-Free",
      "Vegetarian", // if eggs are acceptable for vegetarians
    ],
    allergies: ["Eggs"],
    category: "Breakfast",
    prepTime: 8,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "egg"),
        quantity: 2,
      ),
      MealIngredient(
        // Assuming spinach exists in your mockIngredients
        ingredient: mockIngredients.firstWhere((i) => i.id == "spinach"),
        quantity: 50,
      ),
    ],
  ),

  // 4) Keto Almond Pancakes (Breakfast)
  Meal(
    id: "keto_almond_pancakes",
    name: "Keto Almond Pancakes",
    image: "assets/images/keto_almond_pancakes.jpg",
    instructions: [
      "Mix almond flour, egg, baking powder, and a pinch of salt.",
      "Cook on a skillet with coconut oil until golden.",
      "Serve with a sugar-free syrup.",
    ],
    diets: [
      "Keto",
      "Gluten-Free",
      "Low Carb",
      "Dairy-Free",
      "Paleo",
      "High Protein",
    ],
    allergies: ["Nuts", "Eggs"],
    category: "Breakfast",
    prepTime: 10,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "almond_flour"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "egg"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "baking_powder"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "coconut_oil"),
        quantity: 5,
      ),
    ],
  ),

  // 5) Paleo Sweet Potato Hash (Breakfast)
  Meal(
    id: "paleo_sweet_potato_hash",
    name: "Paleo Sweet Potato Hash",
    image: "assets/images/paleo_sweetpotato_hash.jpg",
    instructions: [
      "Dice sweet potatoes, bell peppers, and onions.",
      "Sauté in olive oil until tender and slightly crispy.",
      "Season with pepper and fresh herbs.",
    ],
    diets: [
      "Paleo",
      "Gluten-Free",
      "Nut-Free",
      "Low Glycemic / Blood Sugar Friendly",
      "Vegetarian",
    ],
    allergies: [],
    category: "Breakfast",
    prepTime: 15,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "sweet_potato"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "bell_pepper"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "onion"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 5,
      ),
    ],
  ),

  // ----------------------------------------------------
  // 5 LUNCHES
  // ----------------------------------------------------

  // 1) Pescatarian Salmon Salad (Lunch)
  Meal(
    id: "pescatarian_salmon_salad",
    name: "Pescatarian Salmon Salad",
    image: "assets/images/salmon_salad.jpg",
    instructions: [
      "Grill salmon fillet with herbs.",
      "Toss mixed greens, spinach, cucumber, and cherry tomatoes.",
      "Top salad with salmon and a light vinaigrette.",
    ],
    diets: [
      "Pescatarian",
      "Low Sugar",
      "High Protein",
      "Gluten-Free",
      "Mediterranean",
    ],
    allergies: ["Fish"],
    category: "Lunch",
    prepTime: 15,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "salmon"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "spinach"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cucumber"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "vinaigrette"),
        quantity: 10,
      ),
    ],
  ),

  // 2) Vegan Lentil & Veggie Bowl (Lunch)
  Meal(
    id: "vegan_lentil_veggie_bowl",
    name: "Vegan Lentil & Veggie Bowl",
    image: "assets/images/vegan_lentil_bowl.jpg",
    instructions: [
      "Cook lentils in vegetable broth.",
      "Sauté mixed veggies (zucchini, carrots).",
      "Combine and season with herbs and lemon juice.",
    ],
    diets: [
      "Vegan",
      "High Fiber",
      "Low Fat",
      "Anti-Inflammatory",
      "Gluten-Free",
    ],
    allergies: [],
    category: "Lunch",
    prepTime: 20,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lentils"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "zucchini"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "carrots"),
        quantity: 80,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 5,
      ),
    ],
  ),

  // 3) Gluten-Free Turkey Wrap (Lunch)
  Meal(
    id: "glutenfree_turkey_wrap",
    name: "Gluten-Free Turkey Wrap",
    image: "assets/images/glutenfree_turkey_wrap.jpg",
    instructions: [
      "Use a gluten-free tortilla.",
      "Layer turkey slices, lettuce, and tomato.",
      "Roll and slice into wraps.",
    ],
    diets: ["Gluten-Free", "Low Calorie", "Dairy-Free", "High Protein"],
    allergies: [],
    category: "Lunch",
    prepTime: 8,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "gf_tortilla"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "turkey_slices"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lettuce"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 1,
      ),
    ],
  ),

  // 4) Low Sodium Chicken & Veggies (Lunch)
  Meal(
    id: "lowsodium_chicken_veggies",
    name: "Low Sodium Chicken & Veggies",
    image: "assets/images/chicken_veggies.jpg",
    instructions: [
      "Season chicken breast with herbs (no salt).",
      "Bake with mixed veggies (broccoli, carrots).",
      "Serve with a squeeze of lemon.",
    ],
    diets: [
      "Low Sodium / Heart Healthy",
      "Balanced",
      "High Protein",
      "Gluten-Free",
    ],
    allergies: [],
    category: "Lunch",
    prepTime: 25,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "chicken_breast"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "broccoli"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "carrots"),
        quantity: 80,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // 5) Whole30 Zucchini Noodles (Lunch)
  Meal(
    id: "whole30_zucchini_noodles",
    name: "Whole30 Zucchini Noodles",
    image: "assets/images/whole30_zoodles.jpg",
    instructions: [
      "Spiralize zucchini into noodles.",
      "Sauté with olive oil, garlic, and cherry tomatoes.",
      "Serve with a squeeze of lemon.",
    ],
    diets: ["Whole30", "Low Carb", "Dairy-Free", "Nut-Free", "High Fiber"],
    allergies: [],
    category: "Lunch",
    prepTime: 15,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "zucchini"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "garlic"),
        quantity: 5,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
    ],
  ),

  // ----------------------------------------------------
  // 5 DINNERS
  // ----------------------------------------------------

  // 1) Keto Cauliflower Fried Rice (Dinner)
  Meal(
    id: "keto_cauliflower_fried_rice",
    name: "Keto Cauliflower Fried Rice",
    image: "assets/images/keto_cauliflower_rice.jpg",
    instructions: [
      "Pulse cauliflower into rice.",
      "Stir-fry with scrambled egg and mixed low-carb veggies.",
      "Season with coconut aminos and pepper.",
    ],
    diets: ["Keto", "Low Carb", "Soy-Free", "Nut-Free", "High Protein"],
    allergies: ["Eggs"],
    category: "Dinner",
    prepTime: 15,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cauliflower"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "egg"),
        quantity: 1,
      ),
      MealIngredient(
        // Assuming mixed low-carb veggies include broccoli and carrots
        ingredient: mockIngredients.firstWhere((i) => i.id == "broccoli"),
        quantity: 80,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "coconut_amino"),
        quantity: 5,
      ),
    ],
  ),

  // 2) Salmon & Asparagus (Dinner)
  Meal(
    id: "salmon_asparagus",
    name: "Salmon & Asparagus",
    image: "assets/images/salmon_asparagus.jpg",
    instructions: [
      "Season salmon with herbs and lemon.",
      "Bake salmon with asparagus.",
      "Drizzle extra virgin olive oil before serving.",
    ],
    diets: [
      "Pescatarian",
      "Mediterranean",
      "Low Glycemic / Blood Sugar Friendly",
      "High Protein",
    ],
    allergies: ["Fish"],
    category: "Dinner",
    prepTime: 20,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "salmon"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "asparagus"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lemon"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "olive_oil"),
        quantity: 5,
      ),
    ],
  ),

  // 3) Dairy-Free Turkey Chili (Dinner)
  Meal(
    id: "dairyfree_turkey_chili",
    name: "Dairy-Free Turkey Chili",
    image: "assets/images/turkey_chili.jpg",
    instructions: [
      "Brown ground turkey with diced onions.",
      "Add tomatoes, beans, and chili spices.",
      "Simmer until the flavors meld.",
    ],
    diets: ["Low Fat", "High Protein", "Dairy-Free", "Gluten-Free"],
    allergies: [],
    category: "Dinner",
    prepTime: 25,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "turkey_slices"),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "onion"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "beans"),
        quantity: 100,
      ),
    ],
  ),

  // 4) Vegan Portobello Fajitas (Dinner)
  Meal(
    id: "vegan_portobello_fajitas",
    name: "Vegan Portobello Fajitas",
    image: "assets/images/vegan_portobello_fajitas.jpg",
    instructions: [
      "Slice portobello mushrooms, onions, and bell peppers.",
      "Sauté with fajita seasoning until tender.",
      "Serve in corn tortillas with avocado slices.",
    ],
    diets: ["Vegan", "Gluten-Free", "Nut-Free", "Low Calorie", "High Fiber"],
    allergies: [],
    category: "Dinner",
    prepTime: 20,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere(
          (i) => i.id == "portobello_mushrooms",
        ),
        quantity: 150,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "onion"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "bell_pepper"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "corn_tortillas"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "avocado"),
        quantity: 0.5,
      ),
    ],
  ),

  // 5) Low Glycemic Lentil Curry (Dinner)
  Meal(
    id: "lowglycemic_lentil_curry",
    name: "Low Glycemic Lentil Curry",
    image: "assets/images/lentil_curry.jpg",
    instructions: [
      "Sauté onions, garlic, and ginger.",
      "Add lentils, diced tomatoes, and curry powder.",
      "Simmer until lentils are soft and flavorful.",
    ],
    diets: [
      "Low Glycemic / Blood Sugar Friendly",
      "Vegan",
      "High Fiber",
      "Anti-Inflammatory",
      "Gluten-Free",
    ],
    allergies: [],
    category: "Dinner",
    prepTime: 30,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "lentils"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "onion"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tomato"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "curry_powder"),
        quantity: 5,
      ),
    ],
  ),

  // ----------------------------------------------------
  // 5 SNACKS
  // ----------------------------------------------------

  // 1) Protein Shake (Snack)
  Meal(
    id: "protein_shake",
    name: "Protein Shake",
    image: "assets/images/protein_shake.jpg",
    instructions: [
      "Blend protein powder, water or plant milk, and ice.",
      "Optional: add banana for extra creaminess.",
    ],
    diets: ["High Protein", "Low Fat", "Nut-Free", "Low Carb"],
    allergies: [],
    category: "Snack",
    prepTime: 3,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "protein_powder"),
        quantity: 30,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "plant_milk"),
        quantity: 200,
      ),
    ],
  ),

  // 2) Paleo Apple Slices & Almond Butter (Snack)
  Meal(
    id: "paleo_apple_almond_butter",
    name: "Apple Slices & Almond Butter",
    image: "assets/images/apple_almond_butter.jpg",
    instructions: [
      "Slice an apple into wedges.",
      "Serve with a side of almond butter for dipping.",
    ],
    diets: [
      "Paleo",
      "Low Glycemic / Blood Sugar Friendly",
      "Dairy-Free",
      "Balanced",
    ],
    allergies: ["Nuts"],
    category: "Snack",
    prepTime: 5,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "apple"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "almond_butter"),
        quantity: 20,
      ),
    ],
  ),

  // 3) Low Calorie Veggie Sticks (Snack)
  Meal(
    id: "lowcal_veggie_sticks",
    name: "Veggie Sticks with Dip",
    image: "assets/images/veggie_sticks.jpg",
    instructions: [
      "Cut cucumbers, carrots, and celery into sticks.",
      "Serve with a side of low-fat hummus.",
    ],
    diets: ["Low Calorie", "Vegan", "Nut-Free", "Soy-Free", "High Fiber"],
    allergies: [],
    category: "Snack",
    prepTime: 5,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "cucumber"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "carrots"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "celery"),
        quantity: 1,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "hummus"),
        quantity: 50,
      ),
    ],
  ),

  // 4) FODMAP Friendly Rice Cakes (Snack)
  Meal(
    id: "fodmap_rice_cakes",
    name: "Rice Cakes with Peanut Butter",
    image: "assets/images/rice_cakes_pb.jpg",
    instructions: [
      "Spread a thin layer of peanut butter on rice cakes.",
      "Top with sliced strawberries if desired.",
    ],
    diets: ["FODMAP Friendly", "Vegetarian", "Low Calorie"],
    allergies: ["Nuts"],
    category: "Snack",
    prepTime: 2,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "rice_cakes"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "peanut_butter"),
        quantity: 15,
      ),
      // Optionally, you can add strawberries if defined
    ],
  ),

  // 5) Whole30 Celery & Tuna Boats (Snack)
  Meal(
    id: "whole30_celery_tuna",
    name: "Celery & Tuna Boats",
    image: "assets/images/celery_tuna.jpg",
    instructions: [
      "Mix tuna with Whole30-compliant mayo.",
      "Spoon mixture into celery stalks.",
    ],
    diets: ["Whole30", "Low Carb", "High Protein", "Gluten-Free"],
    allergies: ["Fish"],
    category: "Snack",
    prepTime: 5,
    video: null,
    ingredients: [
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "tuna"),
        quantity: 100,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "celery"),
        quantity: 2,
      ),
      MealIngredient(
        ingredient: mockIngredients.firstWhere((i) => i.id == "whole30_mayo"),
        quantity: 10,
      ),
    ],
  ),
];
