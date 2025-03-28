// Same imports...
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  final List<String> selectedDiets = [];
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

  void _addInstruction() {
    if (instructionController.text.isNotEmpty) {
      setState(() {
        instructions.add(instructionController.text);
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

    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠ Please select an image")));
      return;
    }

    final id = "meal_${Random().nextInt(999999)}";
    final uploadedUrl = await _uploadImage(_selectedImage!);

    final newMeal = Meal(
      id: id,
      name: nameController.text,
      image: uploadedUrl,
      ingredients: mealIngredients,
      instructions: instructions,
      diets: selectedDiets,
      category: category,
      allergies: selectedAllergies,
      prepTime: 0,
    );

    await FirebaseFirestore.instance
        .collection('meals')
        .doc(newMeal.id)
        .set(newMeal.toJson());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Meal saved to database")));
    Navigator.pop(context);
  }

  Future<void> _uploadSampleMeals() async {
    for (final meal in mealData) {
      await FirebaseFirestore.instance.collection('meals').add(meal.toJson());
    }

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
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Meal Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: category,
                decoration: _inputDecoration("Category"),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items:
                    ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 16),

              const Text("Diets", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    ["Vegan", "Keto", "Mediterranean", "Balanced", "Paleo"]
                        .map(
                          (diet) => FilterChip(
                            label: Text(diet),
                            selected: selectedDiets.contains(diet),
                            selectedColor: Colors.green,
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.grey[800],
                            onSelected: (selected) {
                              setState(() {
                                selected
                                    ? selectedDiets.add(diet)
                                    : selectedDiets.remove(diet);
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),

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
              DropdownButtonFormField<Ingredient>(
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Add Ingredient"),
                items:
                    allIngredients
                        .map(
                          (ing) => DropdownMenuItem(
                            value: ing,
                            child: Text(ing.name),
                          ),
                        )
                        .toList(),
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
                                  Navigator.pop(context);
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

              ElevatedButton(
                onPressed: _saveMeal,
                child: const Text("Save Meal"),
              ),
              const SizedBox(height: 12),
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
