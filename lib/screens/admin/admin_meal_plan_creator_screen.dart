import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../models/meal_portion.dart';
import '../../data/meal_plan_data.dart'; // ✅ actual plan data

class AdminCreateMealPlanScreen extends StatefulWidget {
  const AdminCreateMealPlanScreen({super.key});

  @override
  State<AdminCreateMealPlanScreen> createState() =>
      _AdminCreateMealPlanScreenState();
}

class _AdminCreateMealPlanScreenState extends State<AdminCreateMealPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<Meal> allMeals = [];
  List<MealDay> mealDays = [];

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    final snapshot = await FirebaseFirestore.instance.collection('meals').get();
    setState(() {
      allMeals = snapshot.docs.map((doc) => Meal.fromJson(doc.data())).toList();
    });
  }

  void _addNewDay() {
    setState(() {
      mealDays.add(MealDay(dayNumber: mealDays.length + 1));
    });
  }

  void _setMealForDay(int dayIndex, String mealType, Meal meal) {
    final updatedDay = mealDays[dayIndex].swapMeal(mealType, meal, 1.0);
    setState(() {
      mealDays[dayIndex] = updatedDay;
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate() || mealDays.isEmpty) return;

    final plan = MealPlan(
      id: "plan_${Random().nextInt(999999)}",
      planName: _nameController.text,
      description: _descController.text,
      days: mealDays,
    );

    await FirebaseFirestore.instance
        .collection("mealPlans")
        .doc(plan.id)
        .set(plan.toJson());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Meal Plan Saved!")));

    Navigator.pop(context);
  }

  Future<void> _uploadSampleMealPlans() async {
    for (final plan in mealPlanData) {
      await FirebaseFirestore.instance
          .collection("mealPlans")
          .doc(plan.id)
          .set(plan.toJson());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Sample Meal Plans Uploaded!")),
    );
  }

  Widget _mealDropdown(int dayIndex, String mealType, MealPortion? selected) {
    return DropdownButtonFormField<Meal>(
      value: selected?.meal,
      isExpanded: true,
      dropdownColor: Colors.black, // Dropdown background
      decoration: InputDecoration(
        labelText: mealType,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.amber),
        ),
      ),
      style: const TextStyle(color: Colors.white70), // Selected item style
      hint: Text(mealType, style: const TextStyle(color: Colors.white38)),
      items:
          allMeals
              .map(
                (meal) => DropdownMenuItem<Meal>(
                  value: meal,
                  child: Text(
                    meal.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
      onChanged: (meal) {
        if (meal != null) {
          _setMealForDay(dayIndex, mealType.toLowerCase(), meal);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Meal Plan"),
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Plan Name'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addNewDay,
                icon: const Icon(Icons.calendar_today),
                label: const Text("Add Day"),
              ),
              const SizedBox(height: 16),
              ...mealDays.map((day) {
                final i = mealDays.indexOf(day);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Day ${day.dayNumber}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _mealDropdown(i, "Breakfast", day.breakfast),
                        _mealDropdown(i, "Snack1", day.snack1),
                        _mealDropdown(i, "Lunch", day.lunch),
                        _mealDropdown(i, "Snack2", day.snack2),
                        _mealDropdown(i, "Dinner", day.dinner),
                        _mealDropdown(i, "Snack3", day.snack3),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Save Meal Plan"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _uploadSampleMealPlans,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Sample Meal Plans"),
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
