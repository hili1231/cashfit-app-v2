// ... all imports unchanged
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_program.dart';

class AdminWorkoutProgramManagementScreen extends StatefulWidget {
  const AdminWorkoutProgramManagementScreen({super.key});

  @override
  State<AdminWorkoutProgramManagementScreen> createState() =>
      _AdminWorkoutProgramManagementScreenState();
}

class _AdminWorkoutProgramManagementScreenState
    extends State<AdminWorkoutProgramManagementScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<WorkoutProgram> workoutPrograms = [];
  List<WorkoutExercise> workoutExercises = [];

  String? selectedWorkoutExerciseId;
  String? imageUrl;
  Map<String, List<String>> workoutExerciseIdsPerDay = {};
  int dayCounter = 1;
  final List<String> levels = ["Beginner", "Intermediate", "Advanced"];

  final TextEditingController createTitleController = TextEditingController();
  final TextEditingController createDescriptionController =
      TextEditingController();
  final TextEditingController createDayInputController =
      TextEditingController();
  String? createLevel;

  @override
  void initState() {
    super.initState();
    loadWorkoutPrograms();
    loadWorkoutExercises();
  }

  Future<void> loadWorkoutPrograms() async {
    final snapshot = await firestore.collection('workoutPrograms').get();
    setState(() {
      workoutPrograms =
          snapshot.docs
              .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
              .toList();
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

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final ref = storage.ref().child('uploads/${pickedFile.name}');
      final uploadTask = ref.putFile(File(pickedFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() => imageUrl = downloadUrl);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> createWorkoutProgram() async {
    final title = createTitleController.text.trim();
    final desc = createDescriptionController.text.trim();

    if (title.isEmpty) {
      showError("Title is required.");
      return;
    }
    if (desc.isEmpty) {
      showError("Description is required.");
      return;
    }
    if (createLevel == null || createLevel!.isEmpty) {
      showError("Level is required.");
      return;
    }
    if (workoutExerciseIdsPerDay.isEmpty) {
      showError("Please add at least one day with exercises.");
      return;
    }
    if (imageUrl == null || imageUrl!.isEmpty) {
      showError("Please upload an image.");
      return;
    }

    final docId = firestore.collection('workoutPrograms').doc().id;

    await firestore.collection('workoutPrograms').doc(docId).set({
      'title': title,
      'image': imageUrl,
      'days': workoutExerciseIdsPerDay,
      'level': createLevel,
      'description': desc,
    });

    resetForm();
    await loadWorkoutPrograms();

    if (!mounted) return;
    showError('✅ Workout Program created!');
  }

  void resetForm() {
    createTitleController.clear();
    createDescriptionController.clear();
    createDayInputController.clear();
    createLevel = null;
    workoutExerciseIdsPerDay.clear();
    selectedWorkoutExerciseId = null;
    imageUrl = null;
    dayCounter = 1;
  }

  void addNewDay() {
    setState(() {
      workoutExerciseIdsPerDay[dayCounter.toString()] = [];
      dayCounter++;
    });
  }

  void addWorkoutExerciseToDay(String dayInput) {
    final day = int.tryParse(dayInput);
    if (day != null && selectedWorkoutExerciseId != null) {
      final key = day.toString();
      setState(() {
        workoutExerciseIdsPerDay.putIfAbsent(key, () => []);
        workoutExerciseIdsPerDay[key]!.add(selectedWorkoutExerciseId!);
      });
    } else {
      showError("Please select a valid day and exercise.");
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget buildDaySection(String day) {
    final items = workoutExerciseIdsPerDay[day] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day $day',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed:
                  () => setState(() => workoutExerciseIdsPerDay.remove(day)),
              child: const Text(
                'Remove Day',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
        ...items.map(
          (id) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(color: Colors.white70)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () => setState(
                      () => workoutExerciseIdsPerDay[day]?.remove(id),
                    ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Program Manager'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Create Program'),
            TextField(
              controller: createTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: createDescriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: createLevel,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Level *'),
              items:
                  levels
                      .map(
                        (lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => createLevel = val),
            ),
            const SizedBox(height: 12),
            if (imageUrl != null) Image.network(imageUrl!, height: 100),
            ElevatedButton(
              onPressed: pickAndUploadImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: addNewDay, child: const Text('Add Day')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedWorkoutExerciseId,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Workout Exercise ID'),
              items:
                  workoutExercises
                      .map(
                        (we) =>
                            DropdownMenuItem(value: we.id, child: Text(we.id)),
                      )
                      .toList(),
              onChanged:
                  (val) => setState(() => selectedWorkoutExerciseId = val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: createDayInputController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Day Number'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => addWorkoutExerciseToDay(createDayInputController.text),
              child: const Text('Add to Day'),
            ),
            ...workoutExerciseIdsPerDay.keys.map(buildDaySection),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createWorkoutProgram,
              child: const Text('Create Program'),
            ),
          ],
        ),
      ),
    );
  }
}
