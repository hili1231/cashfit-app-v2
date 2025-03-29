import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/exercise.dart';
import '../../data/exercise_data.dart';

class AdminExerciseManagementScreen extends StatefulWidget {
  const AdminExerciseManagementScreen({super.key});

  @override
  AdminExerciseManagementScreenState createState() =>
      AdminExerciseManagementScreenState();
}

class AdminExerciseManagementScreenState
    extends State<AdminExerciseManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<Exercise> exercises = [];
  List<Exercise> filteredExercises = []; // <--- New: for search filtering

  String? selectedExerciseId;
  String? imageUrl, videoUrl, category;

  List<String> muscleGroups = [];
  List<String> injuryRisks = [];

  final nameController = TextEditingController();
  final instructionsController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<String> allCategories = [
    'Gym',
    'Bodyweight',
    'Cardio',
    'dumbbells',
    'Rest',
  ];

  final List<String> allMuscleGroups = [
    'Upper Chest',
    'Middle Chest',
    'Lower Chest',
    'Chest',
    'Upper Back',
    'Middle Back',
    'Lower Back',
    'Back,',
    'Lats',
    'Front Delt',
    'Side Delt',
    'Rear Delt',
    'Shoulders',
    'Rotator Cuff',
    'Arms',
    'Short Head Biceps',
    'Long Head Biceps',
    'Forearm Flexors',
    'Forearm Extensors',
    'Long Head Triceps',
    'Lateral Head Triceps',
    'Medial Head Triceps',
    'Upper Abs',
    'Lower Abs',
    'Obliques',
    'Glutes',
    'Outer Quad',
    'Legs',
    'Inner Quad',
    'Hamstring Long Head',
    'Hamstring Short Head',
    'Semitendinosus',
    'Semimembranosus',
    'Calves',
    'Hip Flexors',
    'Hip Abductors',
    'Hip Adductors',
    'Rest',
  ];

  final List<String> allInjuries = [
    'Knee',
    'Shoulder',
    'Back',
    'Wrist',
    'Ankle',
    'Rest',
  ];

  @override
  void initState() {
    super.initState();
    loadExercises();
    // Whenever the search field changes, we’ll update the filtered list
    searchController.addListener(_updateFilteredExercises);
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredExercises);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadExercises() async {
    final snapshot = await firestore.collection('exercises').get();
    if (!mounted) return;
    setState(() {
      exercises =
          snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
      // By default, filtered list = full list
      filteredExercises = [...exercises];
    });
  }

  // <--- Called whenever user types in search box
  void _updateFilteredExercises() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // No search? Show all
        filteredExercises = exercises;
      } else {
        // Filter by name containing the query
        filteredExercises =
            exercises.where((ex) {
              return ex.name.toLowerCase().contains(query);
            }).toList();
      }

      // If the currently selected exercise is no longer in the filtered list,
      // we can clear it or keep it as-is
      if (selectedExerciseId != null) {
        final stillExists = filteredExercises.any(
          (e) => e.id == selectedExerciseId,
        );
        if (!stillExists) {
          selectedExerciseId = null;
        }
      }
    });
  }

  Future<String?> uploadFile(XFile file) async {
    try {
      String fileName = file.name;
      Reference storageRef = storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(file.path));
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> createOrEditExercise({String? exerciseId}) async {
    final name = nameController.text.trim();
    final instructions = instructionsController.text.trim();

    if (name.isEmpty ||
        instructions.isEmpty ||
        category == null ||
        muscleGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    // Generate a slug-like ID from the name
    final normalizedId = name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');

    // Check for duplicates only when creating
    if (exerciseId == null) {
      final existing =
          await firestore.collection('exercises').doc(normalizedId).get();

      if (!mounted) return; // ✅ Ensure context is still valid

      if (existing.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An exercise with this name already exists."),
          ),
        );
        return;
      }
    }

    final docId = exerciseId ?? normalizedId;

    await firestore.collection('exercises').doc(docId).set({
      'name': name,
      'instructions': instructions,
      'image': imageUrl,
      'videoUrl': videoUrl,
      'category': category,
      'muscleGroups': muscleGroups,
      'injuryRisks': injuryRisks,
    });

    if (!mounted) return;
    await loadExercises();
    nameController.clear();
    instructionsController.clear();
    setState(() {
      selectedExerciseId = null;
      category = null;
      muscleGroups = [];
      injuryRisks = [];
      imageUrl = null;
    });
    if (!mounted) return; // ✅ Safe use of context

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise saved successfully!')),
    );
  }

  Future<void> deleteExercise(String exerciseId) async {
    await firestore.collection('exercises').doc(exerciseId).delete();
    if (!mounted) return;
    setState(() {
      exercises.removeWhere((exercise) => exercise.id == exerciseId);
      filteredExercises.removeWhere((exercise) => exercise.id == exerciseId);
      selectedExerciseId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise deleted successfully!')),
    );
  }

  Future<void> uploadExercisesFromLocal() async {
    for (final ex in exerciseLibrary) {
      await firestore.collection('exercises').doc(ex.id).set(ex.toMap());
    }
    if (!mounted) return;
    await loadExercises();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercises uploaded from local data')),
    );
  }

  Future<void> pickAndUploadImageOrVideo() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final url = await uploadFile(pickedFile);
      if (url != null) {
        setState(() => imageUrl = url);
      }
    }
  }

  Widget _buildChips(
    List<String> options,
    List<String> selectedList,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              options.map((item) {
                final selected = selectedList.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      selected
                          ? selectedList.remove(item)
                          : selectedList.add(item);
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Exercise Management'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Add/Edit Exercise', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Exercise Name *'),
            ),
            TextField(
              controller: instructionsController,
              decoration: const InputDecoration(labelText: 'Instructions *'),
            ),
            DropdownButtonFormField<String>(
              value: allCategories.contains(category) ? category : null,
              items:
                  allCategories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => category = val),
              decoration: const InputDecoration(labelText: 'Category *'),
            ),

            const SizedBox(height: 10),
            _buildChips(
              allMuscleGroups,
              muscleGroups,
              "Select Muscle Groups *",
            ),
            const SizedBox(height: 10),
            _buildChips(allInjuries, injuryRisks, "Injury Risks (Optional)"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickAndUploadImageOrVideo,
              child: const Text('Upload Image/Video'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async => await createOrEditExercise(),
              child: const Text('Save New Exercise'),
            ),

            const Divider(height: 40),
            const Text(
              'Edit Existing Exercise',
              style: TextStyle(fontSize: 20),
            ),

            // <--- New: Search box to filter the dropdown
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),

            DropdownButton<String>(
              hint: const Text("Select Exercise to Edit"),
              value: selectedExerciseId,
              isExpanded: true, // Let it expand horizontally
              onChanged: (newValue) {
                setState(() {
                  selectedExerciseId = newValue;
                  if (newValue != null) {
                    final ex = filteredExercises.firstWhere(
                      (e) => e.id == newValue,
                    );
                    nameController.text = ex.name;
                    instructionsController.text = ex.instructions;
                    imageUrl = ex.image;
                    videoUrl = ex.videoUrl;
                    category = ex.category;
                    muscleGroups = List.from(ex.muscleGroups);
                    injuryRisks = List.from(ex.injuryRisks);
                  }
                });
              },
              items:
                  filteredExercises.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.id,
                      child: Text(e.name),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (selectedExerciseId != null) {
                  await createOrEditExercise(exerciseId: selectedExerciseId);
                }
              },
              child: const Text('Save Edited Exercise'),
            ),
            const Divider(height: 40),

            const Text('Delete Exercise', style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () async {
                if (selectedExerciseId != null) {
                  await deleteExercise(selectedExerciseId!);
                }
              },
              child: const Text('Delete Selected Exercise'),
            ),
            const Divider(height: 40),

            ElevatedButton(
              onPressed: uploadExercisesFromLocal,
              child: const Text('Upload Exercises from Local Data'),
            ),
          ],
        ),
      ),
    );
  }
}
