import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/exercise.dart';
import '../../models/workout_exercise.dart';
import '../../data/workout_exercise_data.dart';

class AdminWorkoutExerciseManagementScreen extends StatefulWidget {
  const AdminWorkoutExerciseManagementScreen({super.key});

  @override
  State<AdminWorkoutExerciseManagementScreen> createState() =>
      _AdminWorkoutExerciseManagementScreenState();
}

class _AdminWorkoutExerciseManagementScreenState
    extends State<AdminWorkoutExerciseManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<Exercise> exercises = [];
  List<WorkoutExercise> workoutExercises = [];

  String? selectedWorkoutExerciseId;
  String? selectedExerciseId;
  int? sets;
  String? reps;

  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadExercises();
    loadWorkoutExercises();
  }

  Future<void> loadExercises() async {
    final snapshot = await firestore.collection('exercises').get();
    setState(() {
      exercises =
          snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
    });
  }

  Future<void> loadWorkoutExercises() async {
    final snapshot = await firestore.collection('workoutExercises').get();
    setState(() {
      workoutExercises =
          snapshot.docs
              .map((doc) => WorkoutExercise.fromMap(doc.id, doc.data()))
              .toList();
    });
  }

  Future<void> createOrEditWorkoutExercise({
    String? workoutExerciseId,
    required String exerciseId,
    required int sets,
    required String reps,
  }) async {
    final exercise = exercises.firstWhere((e) => e.id == exerciseId);
    final sanitizedExerciseName =
        exercise.name.replaceAll(' ', '_').toLowerCase();
    final id =
        workoutExerciseId ?? '${sanitizedExerciseName}_sets_${sets}_reps_$reps';

    await firestore.collection('workoutExercises').doc(id).set({
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
    });

    await loadWorkoutExercises();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Workout Exercise saved!')));
  }

  Future<void> deleteWorkoutExercise(String workoutExerciseId) async {
    await firestore
        .collection('workoutExercises')
        .doc(workoutExerciseId)
        .delete();
    setState(() {
      workoutExercises.removeWhere((we) => we.id == workoutExerciseId);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Workout Exercise deleted!')),
    );
  }

  Future<void> uploadWorkoutExercisesFromLocal() async {
    for (final workoutEx in workoutExerciseLibrary) {
      await firestore
          .collection('workoutExercises')
          .doc(workoutEx.id)
          .set(workoutEx.toMap());
    }
    await loadWorkoutExercises();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📦 Local Workout Exercises Uploaded!')),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Workout Exercise Manager'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ➕ Add New Workout Exercise
            const Text(
              "➕ Add New Workout Exercise",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 1) Dropdown for exercise selection
            DropdownButtonFormField<String>(
              value: selectedExerciseId,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Select Exercise"),
              items:
                  exercises.map((e) {
                    return DropdownMenuItem(value: e.id, child: Text(e.name));
                  }).toList(),
              onChanged: (val) => setState(() => selectedExerciseId = val),
            ),
            const SizedBox(height: 12),

            // Sets
            TextField(
              decoration: _inputDecoration('Sets'),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => sets = int.tryParse(val),
            ),
            const SizedBox(height: 12),

            // Reps (as a string)
            TextField(
              decoration: _inputDecoration('Reps'),
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => reps = val.trim(),
            ),
            const SizedBox(height: 16),

            // Create button
            ElevatedButton(
              onPressed: () async {
                if (selectedExerciseId != null &&
                    sets != null &&
                    reps != null &&
                    reps!.isNotEmpty) {
                  await createOrEditWorkoutExercise(
                    exerciseId: selectedExerciseId!,
                    sets: sets!,
                    reps: reps!,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('💾 Save Workout Exercise'),
            ),

            // Divider
            const Divider(height: 40, color: Colors.white30),

            // ✏️ Edit Existing Workout Exercise
            const Text(
              "✏️ Edit Existing Workout Exercise",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 2) Dropdown for existing workoutEx selection
            DropdownButtonFormField<String>(
              value: selectedWorkoutExerciseId,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Select Workout Exercise"),
              items:
                  workoutExercises.map((we) {
                    return DropdownMenuItem(value: we.id, child: Text(we.id));
                  }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedWorkoutExerciseId = val;
                  if (val != null) {
                    final we = workoutExercises.firstWhere((w) => w.id == val);
                    selectedExerciseId = we.exerciseId;
                    sets = we.sets;
                    reps = we.reps;
                    setsController.text = sets.toString();
                    repsController.text = we.reps;
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // Edit sets
            TextField(
              controller: setsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Sets'),
              keyboardType: TextInputType.number,
              onChanged: (val) => sets = int.tryParse(val),
            ),
            const SizedBox(height: 12),

            // Edit reps (as a string)
            TextField(
              controller: repsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Reps'),
              keyboardType: TextInputType.number,
              onChanged: (val) => reps = val.trim(),
            ),
            const SizedBox(height: 16),

            // Save changes
            ElevatedButton(
              onPressed: () async {
                if (selectedWorkoutExerciseId != null &&
                    sets != null &&
                    reps != null &&
                    reps!.isNotEmpty) {
                  await createOrEditWorkoutExercise(
                    workoutExerciseId: selectedWorkoutExerciseId,
                    exerciseId: selectedExerciseId!,
                    sets: sets!,
                    reps: reps!,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('💾 Save Changes'),
            ),
            const SizedBox(height: 12),

            // Delete
            ElevatedButton(
              onPressed: () async {
                if (selectedWorkoutExerciseId != null) {
                  await deleteWorkoutExercise(selectedWorkoutExerciseId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('🗑 Delete Selected Workout Exercise'),
            ),

            // Divider
            const Divider(height: 40, color: Colors.white30),

            // Upload from Local
            ElevatedButton(
              onPressed: uploadWorkoutExercisesFromLocal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('⬆ Upload Workout Exercises from Local'),
            ),
          ],
        ),
      ),
    );
  }
}
