import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_ingredient.dart';

class AdminCreateMealScreen extends StatefulWidget {
  const AdminCreateMealScreen({super.key});

  @override
  State<AdminCreateMealScreen> createState() => _AdminCreateMealScreenState();
}

class _AdminCreateMealScreenState extends State<AdminCreateMealScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();
  Meal? selectedMeal;
  List<Meal> meals = [];
  final List<String> instructions = [];
  final List<MealIngredient> mealIngredients = [];

  final List<String> allDiets = [
    "Vegan",
    "Vegetarian",
    "Pescatarian",
    "Keto",
    "Mediterranean",
    "Balanced",
    "Paleo",
    "Gluten-Free",
    "Dairy-Free",
    "Nut-Free",
    "Soy-Free",
    "Low Glycemic / Blood Sugar Friendly",
    "Low Sugar",
    "Low Sodium / Heart Healthy",
    "Anti-Inflammatory",
    "Low Fat",
    "Low Calorie",
    "High Fiber",
    "High Protein",
    "Low Carb",
    "Whole30",
    "FODMAP Friendly",
  ];
  final List<String> selectedDiets = [];

  final List<String> allAllergies = [
    "Gluten",
    "Dairy",
    "Peanuts",
    "Shellfish",
    "Soy",
    "Eggs",
  ];
  final List<String> selectedAllergies = [];

  List<Ingredient> allIngredients = [];

  String category = 'Breakfast';
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _loadMeals();
  }

  Future<void> _loadIngredients() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('ingredients').get();
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      allIngredients =
          snapshot.docs.map((doc) => Ingredient.fromMap(doc.data())).toList();
    });
  }

  Future<void> _loadMeals() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('meals').get();
      if (!mounted) return; // Ensure the widget is still mounted
      setState(() {
        meals = snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
      });
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load meals: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _loadMealData(Meal meal) {
    setState(() {
      nameController.text = meal.name;
      instructions.clear();
      instructions.addAll(meal.instructions);
      selectedDiets.clear();
      selectedDiets.addAll(meal.diets);
      selectedAllergies.clear();
      selectedAllergies.addAll(meal.allergies);
      mealIngredients.clear();
      mealIngredients.addAll(meal.ingredients);
      category = meal.category;
      _selectedImage = null; // Reset image selection
    });
  }

  void _addInstruction() {
    if (instructionController.text.isNotEmpty) {
      setState(() {
        instructions.add(instructionController.text.trim());
        instructionController.clear();
      });
    }
  }

  void _addIngredient(Ingredient ingredient, double quantity) {
    setState(() {
      mealIngredients.add(
        MealIngredient(ingredient: ingredient, quantity: quantity),
      );
    });
  }

  Future<XFile?> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked;
  }

  Future<String> _uploadImage(XFile image) async {
    final fileName =
        'meals/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putFile(File(image.path));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    // Store ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_selectedImage == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("⚠ Please select an image"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    String mealId;
    final sanitizedName = nameController.text.trim().replaceAll(' ', '_');
    if (selectedMeal != null) {
      mealId = selectedMeal!.id; // Use existing meal ID if editing
    } else {
      final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      mealId = '${sanitizedName}_$nowStr'; // New meal ID
    }

    final uploadedUrl = await _uploadImage(_selectedImage!);

    final newMeal = Meal(
      id: mealId,
      name: nameController.text.trim(),
      image: uploadedUrl,
      ingredients: mealIngredients,
      instructions: instructions,
      diets: selectedDiets,
      category: category,
      allergies: selectedAllergies,
      prepTime: 0,
    );

    try {
      if (selectedMeal != null) {
        await FirebaseFirestore.instance
            .collection('meals')
            .doc(mealId)
            .update(newMeal.toMap());
        if (!mounted) return; // Ensure the widget is still mounted
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("✅ Meal updated successfully"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('meals')
            .doc(mealId)
            .set(newMeal.toMap());
        if (!mounted) return; // Ensure the widget is still mounted
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("✅ New meal saved to database"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("⚠️ Error saving meal: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (!mounted) return; // Ensure the widget is still mounted
    setState(() {
      nameController.clear();
      instructionController.clear();
      instructions.clear();
      mealIngredients.clear();
      selectedDiets.clear();
      selectedAllergies.clear();
      _selectedImage = null;
      selectedMeal = null;
    });
  }

  Future<void> _uploadSampleMeals() async {
    // Store ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Note: mealData is not available since we removed meal_data.dart dependency
    // This method will need to be updated or removed if sample meals are no longer needed
    // For now, we'll keep it as a placeholder with a warning
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          "⚠ Sample meals upload not implemented (meal_data.dart removed)",
        ),
      ),
    );
  }

  Future<void> _editMeal(Meal meal) async {
    if (!_formKey.currentState!.validate()) return;

    final updatedMeal = Meal(
      id: meal.id,
      name: nameController.text.trim(),
      instructions: instructions,
      diets: selectedDiets,
      allergies: selectedAllergies,
      ingredients: mealIngredients,
      category: category,
      image: meal.image,
      prepTime: meal.prepTime, // Added required parameter
      cookTime: meal.cookTime,
      video: meal.video,
      tags: meal.tags,
      difficulty: meal.difficulty,
    );

    try {
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(meal.id)
          .update(updatedMeal.toMap());

      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal updated successfully!')),
      );

      _loadMeals();
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update meal: $e')),
      );
    }
  }

  Future<void> _assignMealToDay(String day, Meal meal) async {
    try {
      final dayRef = FirebaseFirestore.instance.collection('mealDays').doc(day);
      final dayData = await dayRef.get();

      if (dayData.exists) {
        await dayRef.update({
          'meals': FieldValue.arrayUnion([meal.id]),
        });
      } else {
        await dayRef.set({
          'meals': [meal.id],
        });
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal assigned to $day successfully!')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign meal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create or Edit Meal'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<Meal>(
                hint: const Text('Select a Meal to Edit'),
                value: selectedMeal,
                items: meals.map((meal) {
                  return DropdownMenuItem<Meal>(
                    value: meal,
                    child: Text(meal.name),
                  );
                }).toList(),
                onChanged: (meal) {
                  if (meal != null) {
                    setState(() {
                      selectedMeal = meal;
                    });
                    _loadMealData(meal);
                  }
                },
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Meal Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a meal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: instructionController,
                decoration: const InputDecoration(labelText: 'Add Instruction'),
              ),
              ElevatedButton(
                onPressed: _addInstruction,
                child: const Text('Add Instruction'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final image = await _pickImage();
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (selectedMeal != null) {
                    await _editMeal(selectedMeal!);
                  } else {
                    await _saveMeal();
                  }
                },
                child: const Text('Save or Edit Meal'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  await _uploadSampleMeals();
                },
                child: const Text('Upload Sample Meals'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (selectedMeal != null) {
                    await _assignMealToDay('Monday', selectedMeal!);
                  }
                },
                child: const Text('Assign Meal to Monday'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  final ingredient = Ingredient(
                    id: 'sample_id',
                    name: 'Sample Ingredient',
                    calories: 50.0,
                    protein: 2.0,
                    carbs: 10.0,
                    fat: 1.0,
                    fiber: 1.0,
                    sugar: 0.0,
                    saturatedFat: 0.0,
                    cholesterol: 0.0,
                    vitaminA: 0.0,
                    vitaminC: 0.0,
                    vitaminD: 0.0,
                    vitaminK: 0.0,
                    vitaminB12: 0.0,
                    iron: 0.0,
                    calcium: 0.0,
                    potassium: 0.0,
                    magnesium: 0.0,
                    sodium: 0.0,
                    zinc: 0.0,
                    glycemicIndex: null,
                  );
                  _addIngredient(ingredient, 1.0);
                },
                child: const Text('Add Ingredient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
