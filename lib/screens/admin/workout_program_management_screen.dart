import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/workout_exercise.dart';
import '../../models/workout_program.dart';
import '../../data/workout_program_data.dart'; // local samples

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

  // For selecting existing program or creating a new one
  WorkoutProgram? selectedProgram;

  String? imageUrl;
  Map<String, List<String>> workoutExerciseIdsPerDay = {};

  // Basic form fields
  final List<String> levels = ["Beginner", "Intermediate", "Advanced"];
  final TextEditingController createTitleController = TextEditingController();
  final TextEditingController createDescriptionController =
      TextEditingController();
  final TextEditingController createDayInputController =
      TextEditingController();
  String? createLevel;

  // For adding day -> workout exercises
  String? selectedWorkoutExerciseId;
  int dayCounter = 1;

  @override
  void initState() {
    super.initState();
    loadWorkoutPrograms();
    loadWorkoutExercises();
  }

  /// Load existing workout programs from Firestore
  Future<void> loadWorkoutPrograms() async {
    final snapshot = await firestore.collection('workoutPrograms').get();
    setState(() {
      workoutPrograms =
          snapshot.docs
              .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
              .toList();
    });
  }

  /// Load existing workout exercises from Firestore
  Future<void> loadWorkoutExercises() async {
    final snapshot = await firestore.collection('workoutExercises').get();
    setState(() {
      workoutExercises =
          snapshot.docs
              .map((doc) => WorkoutExercise.fromMap(doc.id, doc.data()))
              .toList();
    });
  }

  /// If we are editing existing, we show the doc's data
  void _populateForm(WorkoutProgram program) {
    // Store the program in selectedProgram
    selectedProgram = program;

    // Populate text fields
    createTitleController.text = program.title;
    createDescriptionController.text = program.description;
    createLevel = program.level;
    imageUrl = program.image;

    // Build the workoutExerciseIdsPerDay map from program.days
    workoutExerciseIdsPerDay = {};
    program.days.forEach((dayKey, exercises) {
      workoutExerciseIdsPerDay[dayKey] = List<String>.from(exercises);
    });

    // Set dayCounter so new days don't clash
    // e.g. if program has days 1..5, set dayCounter = 6
    final existingDays = program.days.keys.map(int.parse).toList()..sort();
    dayCounter = existingDays.isEmpty ? 1 : (existingDays.last + 1);
    setState(() {});
  }

  /// Clears the form for a new program
  void _clearFormForNewProgram() {
    selectedProgram = null;
    createTitleController.clear();
    createDescriptionController.clear();
    createLevel = null;
    imageUrl = null;
    workoutExerciseIdsPerDay.clear();
    dayCounter = 1;
    setState(() {});
  }

  /// Upload an image to Firebase Storage
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

  /// Create a brand-new workout program in Firestore (with doc ID = title+timestamp)
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

    // Build doc ID from "title + timestamp"
    final sanitizedTitle = title.replaceAll(' ', '_');
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final docId = '${sanitizedTitle}_$nowStr';

    // Save in Firestore
    await firestore.collection('workoutPrograms').doc(docId).set({
      'title': title,
      'image': imageUrl,
      'days': workoutExerciseIdsPerDay,
      'level': createLevel,
      'description': desc,
    });

    // Reload & reset
    await loadWorkoutPrograms();
    _clearFormForNewProgram();

    if (!mounted) return;
    showError('✅ Workout Program created!');
  }

  /// Update an existing workout program's doc
  Future<void> updateExistingProgram() async {
    if (selectedProgram == null) {
      showError("No existing program selected.");
      return;
    }

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

    // Use the doc ID from selectedProgram!.id
    final docId = selectedProgram!.id;

    await firestore.collection('workoutPrograms').doc(docId).update({
      'title': title,
      'image': imageUrl,
      'days': workoutExerciseIdsPerDay,
      'level': createLevel,
      'description': desc,
    });

    await loadWorkoutPrograms();
    if (!mounted) return;
    showError('✅ Workout Program updated!');
  }

  /// Add a new day to the schedule
  void addNewDay() {
    workoutExerciseIdsPerDay[dayCounter.toString()] = [];
    dayCounter++;
    setState(() {});
  }

  /// Add a workout exercise ID to a specified day
  void addWorkoutExerciseToDay(String dayInput) {
    final day = int.tryParse(dayInput);
    if (day == null || selectedWorkoutExerciseId == null) {
      showError("Please select a valid day and exercise.");
      return;
    }
    final dayKey = day.toString();
    workoutExerciseIdsPerDay.putIfAbsent(dayKey, () => []);
    workoutExerciseIdsPerDay[dayKey]!.add(selectedWorkoutExerciseId!);
    setState(() {});
  }

  /// Upload local sample programs
  Future<void> _uploadSampleWorkoutPrograms() async {
    for (final program in workoutProgramSamples) {
      await firestore
          .collection('workoutPrograms')
          .doc(program.id)
          .set(program.toMap());
    }
    if (!mounted) return;
    showError('✅ Sample workout programs uploaded!');
    await loadWorkoutPrograms();
  }

  /// Build the UI for each day
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
              onPressed: () {
                workoutExerciseIdsPerDay.remove(day);
                setState(() {});
              },
              child: const Text(
                'Remove Day',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
        ...items.map((id) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  id,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  workoutExerciseIdsPerDay[day]?.remove(id);
                  setState(() {});
                },
              ),
            ],
          );
        }),
        const Divider(color: Colors.white24),
      ],
    );
  }

  /// Standard input decoration
  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Section title
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
            // (NEW) Dropdown to select an existing program or "New Program"
            DropdownButtonFormField<WorkoutProgram?>(
              value: selectedProgram,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Select or Edit Program"),
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    "New Program",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ...workoutPrograms.map((wp) {
                  return DropdownMenuItem(
                    value: wp,
                    child: Text(
                      wp.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                if (val == null) {
                  // "New Program" => clear form
                  _clearFormForNewProgram();
                } else {
                  // Existing => populate form
                  _populateForm(val);
                }
              },
            ),
            const SizedBox(height: 16),

            sectionTitle(
              selectedProgram == null
                  ? 'Create Program'
                  : 'Edit Program: ${selectedProgram!.title}',
            ),

            // Title
            TextField(
              controller: createTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Title *'),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: createDescriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description *'),
            ),
            const SizedBox(height: 12),

            // Level
            DropdownButtonFormField<String>(
              value: createLevel,
              isExpanded: true,
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

            // Image preview & upload
            if (imageUrl != null) Image.network(imageUrl!, height: 100),
            ElevatedButton(
              onPressed: pickAndUploadImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 12),

            // Add Day
            ElevatedButton(onPressed: addNewDay, child: const Text('Add Day')),
            const SizedBox(height: 12),

            // Dropdown for selecting which workout exercise ID to add
            DropdownButtonFormField<String>(
              value: selectedWorkoutExerciseId,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Workout Exercise ID'),
              items:
                  workoutExercises.map((we) {
                    return DropdownMenuItem(
                      value: we.id,
                      child: Text(
                        we.id,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged:
                  (val) => setState(() => selectedWorkoutExerciseId = val),
            ),
            const SizedBox(height: 12),

            // Day number input
            TextField(
              controller: createDayInputController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Day Number'),
            ),
            const SizedBox(height: 12),

            // Add selected exercise to the given day
            ElevatedButton(
              onPressed:
                  () => addWorkoutExerciseToDay(createDayInputController.text),
              child: const Text('Add to Day'),
            ),

            // Render day sections
            ...workoutExerciseIdsPerDay.keys.map(buildDaySection),

            const SizedBox(height: 20),

            // If selectedProgram == null => "Create Program"
            // else => "Update Program"
            if (selectedProgram == null) ...[
              ElevatedButton(
                onPressed: createWorkoutProgram,
                child: const Text('Create Program'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: updateExistingProgram,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Update Program'),
              ),
            ],
            const SizedBox(height: 20),

            // Button to upload sample workouts from local data
            ElevatedButton(
              onPressed: _uploadSampleWorkoutPrograms,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: const Text('Upload Sample Workout Programs'),
            ),
          ],
        ),
      ),
    );
  }
}
