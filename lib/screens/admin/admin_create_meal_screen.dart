import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For name + date doc IDs

import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_ingredient.dart';
import '../../data/meal_data.dart';

class AdminCreateMealScreen extends StatefulWidget {
  const AdminCreateMealScreen({super.key});

  @override
  State<AdminCreateMealScreen> createState() => _AdminCreateMealScreenState();
}

class _AdminCreateMealScreenState extends State<AdminCreateMealScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();

  final List<String> instructions = [];
  final List<MealIngredient> mealIngredients = [];

  // Updated lists
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
  }

  Future<void> _loadIngredients() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('ingredients').get();
    setState(() {
      allIngredients =
          snapshot.docs.map((doc) => Ingredient.fromJson(doc.data())).toList();
    });
  }

  /// Add typed instruction to the list
  void _addInstruction() {
    if (instructionController.text.isNotEmpty) {
      setState(() {
        instructions.add(instructionController.text.trim());
        instructionController.clear();
      });
    }
  }

  /// Add chosen ingredient + quantity
  void _addIngredient(Ingredient ingredient, double quantity) {
    setState(() {
      mealIngredients.add(
        MealIngredient(ingredient: ingredient, quantity: quantity),
      );
    });
  }

  /// Pick an image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  /// Upload picked image to Firebase Storage
  Future<String> _uploadImage(XFile image) async {
    final fileName =
        'meals/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putFile(File(image.path));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Build doc ID from meal name + date/time, then save doc
  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠ Please select an image")));
      return;
    }

    // 1) Build doc ID from name + date
    final sanitizedName = nameController.text.trim().replaceAll(' ', '_');
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final mealId = '${sanitizedName}_$nowStr';

    // 2) Upload the image
    final uploadedUrl = await _uploadImage(_selectedImage!);

    // 3) Construct the Meal object
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

    // 4) Save doc(mealId).set(...)
    await FirebaseFirestore.instance
        .collection('meals')
        .doc(newMeal.id)
        .set(newMeal.toJson());

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Meal saved to database")));
    Navigator.pop(context);
  }

  /// Use doc(meal.id).set(...) so Firestore ID matches meal.id
  Future<void> _uploadSampleMeals() async {
    for (final meal in mealData) {
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(meal.id)
          .set(meal.toJson());
    }
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Sample meals uploaded")));
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey[900],
    labelStyle: const TextStyle(color: Colors.white70),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Create Meal"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Name
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Meal Name'),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField(
                value: category,
                isExpanded: true, // fix overflow
                decoration: _inputDecoration("Category"),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items:
                    ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                onChanged: (value) {
                  setState(() => category = value as String);
                },
              ),
              const SizedBox(height: 16),

              // Diets
              const Text("Diets", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    allDiets.map((diet) {
                      return FilterChip(
                        label: Text(diet),
                        selected: selectedDiets.contains(diet),
                        labelStyle: const TextStyle(color: Colors.white),
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey[800],
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedDiets.add(diet);
                            } else {
                              selectedDiets.remove(diet);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Allergies
              const Text("Allergies", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    allAllergies.map((allergy) {
                      return FilterChip(
                        label: Text(allergy),
                        selected: selectedAllergies.contains(allergy),
                        labelStyle: const TextStyle(color: Colors.white),
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey[800],
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedAllergies.add(allergy);
                            } else {
                              selectedAllergies.remove(allergy);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Pick Image
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Choose Image"),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Image.file(File(_selectedImage!.path), height: 150),
                ),

              const SizedBox(height: 12),

              // Ingredients
              const Text(
                "Ingredients",
                style: TextStyle(color: Colors.white70),
              ),
              ...mealIngredients.map(
                (mi) => Text(
                  "- ${mi.ingredient.name} (${mi.quantity}g)",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),

              // Add Ingredient
              DropdownButtonFormField<Ingredient>(
                isExpanded: true, // fix overflow
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Add Ingredient"),
                items:
                    allIngredients.map((ing) {
                      return DropdownMenuItem(
                        value: ing,
                        child: Text(ing.name),
                      );
                    }).toList(),
                onChanged: (ingredient) {
                  if (ingredient != null) {
                    final qtyController = TextEditingController();
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: Text(
                              "Quantity for ${ingredient.name}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration("grams"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  final qty =
                                      double.tryParse(qtyController.text) ??
                                      0.0;
                                  _addIngredient(ingredient, qty);
                                  Navigator.pop(ctx);
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Instructions
              const Text(
                "Instructions",
                style: TextStyle(color: Colors.white70),
              ),
              ...instructions.map(
                (i) =>
                    Text("• $i", style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: instructionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("New instruction"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addInstruction,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save
              ElevatedButton(
                onPressed: _saveMeal,
                child: const Text("Save Meal"),
              ),
              const SizedBox(height: 12),

              // Upload Sample
              ElevatedButton.icon(
                onPressed: _uploadSampleMeals,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Sample Meals"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
