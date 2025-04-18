import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart'; // For making API requests
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_ingredient.dart';

class AdminManageMealsScreen extends StatefulWidget {
  const AdminManageMealsScreen({super.key});

  @override
  AdminManageMealsScreenState createState() => AdminManageMealsScreenState();
}

class AdminManageMealsScreenState extends State<AdminManageMealsScreen> {
  final Dio _dio = Dio(); // Using Dio for API requests
  List<Meal> meals = [];

  @override
  void initState() {
    super.initState();
    fetchMeals();
  }

  // Fetch meals from Firestore
  Future<void> fetchMeals() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('meals').get();
      setState(() {
        meals = snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meals from Firestore: $e')),
      );
    }
  }

  // Fetch meals from the MealDB API
  Future<void> fetchMealsFromMealDB() async {
    try {
      final response = await _dio.get(
        'https://www.themealdb.com/api/json/v1/1/filter.php',
        queryParameters: {
          'i': 'chicken', // Search by ingredient (e.g., chicken)
        },
      );

      if (response.statusCode == 200) {
        List mealsData = response.data['meals'] ?? [];
        for (var mealData in mealsData) {
          // Fetch detailed meal info using the meal ID
          final mealDetailsResponse = await _dio.get(
            'https://www.themealdb.com/api/json/v1/1/lookup.php',
            queryParameters: {'i': mealData['idMeal']},
          );

          if (mealDetailsResponse.statusCode == 200) {
            var detailedMealData = mealDetailsResponse.data['meals']?[0];
            if (detailedMealData != null) {
              Meal newMeal = await _createMealFromMealDB(detailedMealData);
              await _addMealToFirestore(newMeal);
            }
          }
        }
        await fetchMeals(); // Refresh the meals list after adding new meals
      } else {
        throw Exception("Failed to load meals from MealDB API");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meals from MealDB API: $e')),
      );
    }
  }

  // Create a Meal object from MealDB API data
  Future<Meal> _createMealFromMealDB(dynamic mealData) async {
    // Create a list of MealIngredients
    List<MealIngredient> ingredients = [];

    // MealDB API provides up to 20 ingredients as strIngredient1, strIngredient2, etc.
    for (int i = 1; i <= 20; i++) {
      String? ingredientName = mealData['strIngredient$i'];
      String? measure = mealData['strMeasure$i'];

      if (ingredientName != null &&
          ingredientName.isNotEmpty &&
          measure != null &&
          measure.isNotEmpty) {
        // Check if the ingredient exists in Firestore
        Ingredient? existingIngredient;
        final ingredientSnapshot =
            await FirebaseFirestore.instance
                .collection('ingredients')
                .doc(ingredientName.toLowerCase())
                .get();
        if (ingredientSnapshot.exists) {
          existingIngredient = Ingredient.fromMap(ingredientSnapshot.data()!);
        } else {
          // If ingredient doesn't exist, create a placeholder and add to Firestore
          existingIngredient = Ingredient(
            id: ingredientName.toLowerCase(),
            name: ingredientName,
            calories: 0.0, // Placeholder; should be updated later
            protein: 0.0,
            carbs: 0.0,
            fat: 0.0,
          );
          await FirebaseFirestore.instance
              .collection('ingredients')
              .doc(existingIngredient.id)
              .set(existingIngredient.toMap());
        }

        // Parse the quantity from the measure (e.g., "2 cups" -> 2.0)
        double quantity = 0.0;
        try {
          final numberPart = measure.split(' ').first;
          quantity = double.tryParse(numberPart) ?? 0.0;
        } catch (e) {
          quantity = 0.0; // Default if parsing fails
        }

        // Create MealIngredient object
        ingredients.add(
          MealIngredient(
            ingredient: existingIngredient,
            quantity: quantity,
            unit: measure.contains(' ') ? measure.split(' ').last : 'unit',
          ),
        );
      }
    }

    // Create and return the Meal object
    return Meal(
      id: mealData['idMeal'] ?? mealData['strMeal']?.toLowerCase() ?? '',
      name: mealData['strMeal'] ?? '',
      image: mealData['strMealThumb'] ?? '',
      ingredients: ingredients,
      instructions:
          (mealData['strInstructions'] ?? '')
              .split('\n')
              .where((i) => i.isNotEmpty)
              .toList(),
      diets: [], // MealDB doesn't provide diets; can be added manually
      category: mealData['strCategory'] ?? 'Uncategorized',
      allergies: [], // MealDB doesn't provide allergies; can be added manually
      prepTime: 0, // MealDB doesn't provide prep time; can be added manually
      cookTime: null,
      video: mealData['strYoutube'],
      tags: mealData['strTags']?.split(',') ?? [],
      difficulty: 'Medium', // Default value; MealDB doesn't provide difficulty
    );
  }

  // Add new meal to Firestore
  Future<void> _addMealToFirestore(Meal meal) async {
    try {
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(meal.id)
          .set(meal.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meal added to Firestore: ${meal.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding meal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Meals"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: fetchMealsFromMealDB,
              icon: const Icon(Icons.download),
              label: const Text("Fetch Meals from MealDB API"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchMeals,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Meals from Firestore"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              "Meals in Firestore:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            meals.isEmpty
                ? const Text(
                  "No meals found.",
                  style: TextStyle(color: Colors.white54),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Card(
                      color: Colors.grey[850],
                      child: ListTile(
                        title: Text(
                          meal.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Category: ${meal.category} | Ingredients: ${meal.ingredients.length}",
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
