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
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        meals = snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
      });
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load meals: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _loadMealData(Meal meal) {
    nameController.text = meal.name;
    instructions.clear();
    instructions.addAll(meal.instructions);
    selectedDiets.clear();
    selectedDiets.addAll(meal.diets);
    selectedAllergies.clear();
    selectedAllergies.addAll(meal.allergies);
    mealIngredients.clear();
    mealIngredients.addAll(meal.ingredients);
    category = meal.category.isNotEmpty ? meal.category : 'Breakfast';
    setState(() {
      selectedMeal = meal;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return; // Check if the widget is still mounted
    if (image != null) {
      setState(() => _selectedImage = image);
    }
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
        if (!mounted) return; // Check if the widget is still mounted
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
        if (!mounted) return; // Check if the widget is still mounted
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("✅ New meal saved to database"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("⚠️ Error saving meal: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (!mounted) return; // Check if the widget is still mounted
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

  InputDecoration _inputDecoration(
    String label,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colorScheme.surfaceContainer,
    labelStyle: theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Edit Meal",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select Meal
              DropdownButtonFormField<Meal>(
                value: selectedMeal,
                decoration: _inputDecoration(
                  "Select Meal to Edit",
                  theme,
                  colorScheme,
                ),
                isExpanded: true,
                dropdownColor: colorScheme.surfaceContainer,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items:
                    meals.map((meal) {
                      return DropdownMenuItem(
                        value: meal,
                        child: Text(meal.name),
                      );
                    }).toList(),
                onChanged: (meal) {
                  if (meal != null) {
                    _loadMealData(meal);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Meal Name
              TextFormField(
                controller: nameController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Meal Name', theme, colorScheme),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField(
                value: category,
                isExpanded: true,
                decoration: _inputDecoration("Category", theme, colorScheme),
                dropdownColor: colorScheme.surfaceContainer,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
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
              Text(
                "Diets",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    allDiets.map((diet) {
                      return FilterChip(
                        label: Text(diet),
                        selected: selectedDiets.contains(diet),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainer,
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
              Text(
                "Allergies",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    allAllergies.map((allergy) {
                      return FilterChip(
                        label: Text(allergy),
                        selected: selectedAllergies.contains(allergy),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainer,
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
                icon: Icon(Icons.image, color: colorScheme.onPrimary),
                label: Text(
                  "Choose Image",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Image.file(File(_selectedImage!.path), height: 150),
                ),

              const SizedBox(height: 12),

              // Ingredients
              Text(
                "Ingredients",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              ...mealIngredients.map(
                (mi) => Text(
                  "- ${mi.ingredient.name} (${mi.quantity}g)",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Add Ingredient
              DropdownButtonFormField<Ingredient>(
                isExpanded: true,
                dropdownColor: colorScheme.surfaceContainer,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration(
                  "Add Ingredient",
                  theme,
                  colorScheme,
                ),
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
                            backgroundColor: colorScheme.surface,
                            title: Text(
                              "Quantity for ${ingredient.name}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            content: TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              decoration: _inputDecoration(
                                "grams",
                                theme,
                                colorScheme,
                              ),
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
                                child: Text(
                                  "Add",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Instructions
              Text(
                "Instructions",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              ...instructions.map(
                (i) => Text(
                  "• $i",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: instructionController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: _inputDecoration(
                        "New instruction",
                        theme,
                        colorScheme,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: colorScheme.onSurface),
                    onPressed: _addInstruction,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveMeal,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
                child: Text(
                  "Save Edited Meal",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Sample (Placeholder)
              ElevatedButton.icon(
                onPressed: _uploadSampleMeals,
                icon: Icon(Icons.upload_file, color: colorScheme.onSurface),
                label: Text(
                  "Upload Sample Meals",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainer,
                  ),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
