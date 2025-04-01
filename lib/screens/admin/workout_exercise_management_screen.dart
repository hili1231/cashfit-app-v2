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
    try {
      final snapshot = await firestore.collection('exercises').get();
      setState(() {
        exercises =
            snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
      });
    } catch (e) {
      debugPrint("Error loading exercises: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading exercises: $e")));
    }
  }

  Future<void> loadWorkoutExercises() async {
    try {
      final snapshot = await firestore.collection('workoutExercises').get();
      setState(() {
        workoutExercises =
            snapshot.docs
                .map((doc) => WorkoutExercise.fromMap(doc.id, doc.data()))
                .toList();
      });
    } catch (e) {
      debugPrint("Error loading workout exercises: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading workout exercises: $e")),
      );
    }
  }

  Future<void> createOrEditWorkoutExercise({
    String? workoutExerciseId,
    required String exerciseId,
    required int sets,
    required String reps,
  }) async {
    try {
      // Use orElse to prevent no element exception
      final exercise = exercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => throw Exception('Exercise not found'),
      );

      final sanitizedExerciseName =
          exercise.name.replaceAll(' ', '_').toLowerCase();
      final id =
          workoutExerciseId ??
          '${sanitizedExerciseName}_sets_${sets}_reps_$reps';

      await firestore.collection('workoutExercises').doc(id).set({
        'exerciseId': exerciseId,
        'sets': sets,
        'reps': reps,
      });

      await loadWorkoutExercises();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Workout Exercise saved!')),
      );
    } catch (e) {
      debugPrint("Error creating/editing workout exercise: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteWorkoutExercise(String workoutExerciseId) async {
    try {
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
    } catch (e) {
      debugPrint("Error deleting workout exercise: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting workout exercise: $e")),
      );
    }
  }

  Future<void> uploadWorkoutExercisesFromLocal() async {
    try {
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
    } catch (e) {
      debugPrint("Error uploading local workout exercises: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading local workout exercises: $e")),
      );
    }
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
            // Dropdown for exercise selection
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
              onChanged: (val) {
                setState(() {
                  selectedExerciseId = val;
                });
              },
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
            // Dropdown for existing workout exercise selection
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
                try {
                  setState(() {
                    selectedWorkoutExerciseId = val;
                  });
                  if (val != null) {
                    // Use a fallback via orElse to avoid exceptions
                    final we = workoutExercises.firstWhere(
                      (w) => w.id == val,
                      orElse: () => workoutExercises.first,
                    );
                    setState(() {
                      selectedExerciseId = we.exerciseId;
                      sets = we.sets;
                      reps = we.reps;
                      setsController.text = sets?.toString() ?? "";
                      repsController.text = we.reps;
                    });
                  }
                } catch (e) {
                  debugPrint("Error in dropdown selection: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error selecting workout exercise: $e"),
                    ),
                  );
                }
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
            // Edit reps
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
