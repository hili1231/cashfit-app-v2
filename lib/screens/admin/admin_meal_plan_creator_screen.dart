import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../models/meal_portion.dart';
import '../../data/meal_plan_data.dart';

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
  List<MealPlan> existingMealPlans = [];
  MealPlan? selectedMealPlan;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
    _fetchExistingMealPlans();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeals() async {
    final snapshot = await FirebaseFirestore.instance.collection('meals').get();
    setState(() {
      allMeals = snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
      debugPrint('Fetched meals: ${allMeals.length}');
    });
  }

  Future<void> _fetchExistingMealPlans() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('mealPlans').get();
    setState(() {
      existingMealPlans =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Ensure ID is set
            final mealPlan = MealPlan.fromMap(data);
            debugPrint(
              'Fetched meal plan: ${mealPlan.planName}, ID: ${mealPlan.id}',
            );
            return mealPlan;
          }).toList();
      debugPrint('Total existing meal plans: ${existingMealPlans.length}');
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

  void _selectMealPlan(MealPlan? plan) {
    setState(() {
      selectedMealPlan = plan;
      if (plan != null) {
        _nameController.text = plan.planName;
        _descController.text = plan.description;
        mealDays =
            plan.days
                .map(
                  (day) => MealDay(
                    dayNumber: day.dayNumber,
                    breakfast: day.breakfast,
                    snack1: day.snack1,
                    lunch: day.lunch,
                    snack2: day.snack2,
                    dinner: day.dinner,
                    snack3: day.snack3,
                  ),
                )
                .toList();
        debugPrint(
          'Selected meal plan: ${plan.planName}, Days: ${mealDays.length}',
        );
      } else {
        _nameController.clear();
        _descController.clear();
        mealDays = [];
        debugPrint('Cleared meal plan selection');
      }
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate() || mealDays.isEmpty) return;

    final plan = MealPlan(
      id: selectedMealPlan?.id ?? "plan_${Random().nextInt(999999)}",
      planName: _nameController.text,
      description: _descController.text,
      days: mealDays,
      userId: selectedMealPlan?.userId,
      type: selectedMealPlan?.type,
    );

    await FirebaseFirestore.instance
        .collection("mealPlans")
        .doc(plan.id)
        .set(plan.toMap());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedMealPlan == null
              ? "✅ Meal Plan Saved!"
              : "✅ Meal Plan Updated!",
        ),
      ),
    );

    // Reset form after saving/updating
    setState(() {
      selectedMealPlan = null;
      _nameController.clear();
      _descController.clear();
      mealDays = [];
    });

    // Refresh the list of existing meal plans
    await _fetchExistingMealPlans();
  }

  Future<void> _uploadSampleMealPlans() async {
    for (final plan in mealPlanData) {
      await FirebaseFirestore.instance
          .collection("mealPlans")
          .doc(plan.id)
          .set(plan.toMap());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Sample Meal Plans Uploaded!")),
    );

    // Refresh the list of existing meal plans
    await _fetchExistingMealPlans();
  }

  Widget _mealDropdown(int dayIndex, String mealType, MealPortion? selected) {
    return DropdownButtonFormField<Meal>(
      value: selected?.meal,
      isExpanded: true,
      dropdownColor: Colors.black,
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
      style: const TextStyle(color: Colors.white70),
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
              // Dropdown to select existing meal plan
              DropdownButtonFormField<MealPlan?>(
                value: selectedMealPlan,
                isExpanded: true,
                dropdownColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'Select Existing Meal Plan (Optional)',
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
                style: const TextStyle(color: Colors.white70),
                hint: const Text(
                  'Select a meal plan to edit',
                  style: TextStyle(color: Colors.white38),
                ),
                items: <DropdownMenuItem<MealPlan?>>[
                  const DropdownMenuItem<MealPlan?>(
                    value: null,
                    child: Text(
                      'Create New Plan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ...existingMealPlans.map(
                    (plan) => DropdownMenuItem<MealPlan?>(
                      value: plan,
                      child: Text(
                        plan.planName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                onChanged: _selectMealPlan,
              ),
              const SizedBox(height: 16),
              if (selectedMealPlan != null)
                ElevatedButton.icon(
                  onPressed: () => _selectMealPlan(null),
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear Selection"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              const SizedBox(height: 16),
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
                child: Text(
                  selectedMealPlan == null
                      ? "Save Meal Plan"
                      : "Update Meal Plan",
                ),
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
