import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';

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
  List<Exercise> exercises = [];

  WorkoutProgram? selectedProgram;

  String? imageUrl;
  Map<String, List<Map<String, dynamic>>> workoutExercisesPerDay = {};

  final List<String> levels = ["Beginner", "Intermediate", "Advanced"];
  final TextEditingController createTitleController = TextEditingController();
  final TextEditingController createDescriptionController =
      TextEditingController();
  final TextEditingController createDayInputController =
      TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  String? createLevel;

  String? selectedExerciseId;
  int dayCounter = 1;

  @override
  void initState() {
    super.initState();
    loadWorkoutPrograms();
    loadExercises();
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

  Future<void> loadExercises() async {
    final snapshot = await firestore.collection('exercises').get();
    setState(() {
      exercises =
          snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
              .toList();
    });
  }

  void _populateForm(WorkoutProgram program) {
    selectedProgram = program;
    createTitleController.text = program.title;
    createDescriptionController.text = program.description;
    createLevel = program.level;
    imageUrl = program.image;
    workoutExercisesPerDay = Map.from(program.days);
    final existingDays =
        program.days.keys
            .map((k) => int.parse(k.replaceAll('Day ', '')))
            .toList()
          ..sort();
    dayCounter = existingDays.isEmpty ? 1 : (existingDays.last + 1);
    setState(() {});
  }

  void _clearFormForNewProgram() {
    selectedProgram = null;
    createTitleController.clear();
    createDescriptionController.clear();
    createLevel = null;
    imageUrl = null;
    workoutExercisesPerDay.clear();
    dayCounter = 1;
    setState(() {});
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

  Future<void> uploadCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      Map<String, WorkoutProgram> programsMap = {};

      // Parse CSV rows (skip header)
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final programId = row[0].toString();
        final programTitle = row[1].toString();
        final programImage = row[2].toString();
        final programLevel = row[3].toString();
        final programDescription = row[4].toString();
        final programUserId =
            row[5].toString().isEmpty ? null : row[5].toString();
        final dayStr = row[6].toString();
        final dayNumber =
            int.tryParse(dayStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final exerciseId = row[7].toString();
        final sets = int.tryParse(row[8].toString()) ?? 0;
        final reps = row[9].toString();

        // Initialize program if not already in map
        if (!programsMap.containsKey(programId)) {
          programsMap[programId] = WorkoutProgram(
            id: programId,
            title: programTitle,
            image: programImage,
            days: {},
            level: programLevel,
            description: programDescription,
            userId: programUserId,
          );
        }

        // Add exercise to day
        final dayKey = 'Day $dayNumber';
        programsMap[programId]!.days[dayKey] =
            programsMap[programId]!.days[dayKey] ?? [];
        programsMap[programId]!.days[dayKey]!.add({
          'exerciseId': exerciseId,
          'sets': sets,
          'reps': reps,
        });
      }

      // Process each program
      for (var program in programsMap.values) {
        final extendedDays = await _extendToOneMonth(
          program.title,
          program.days,
        );
        await firestore.collection('workoutPrograms').doc(program.id).set({
          'title': program.title,
          'image': program.image,
          'days': extendedDays,
          'level': program.level,
          'description': program.description,
          if (program.userId != null) 'userId': program.userId,
        }, SetOptions(merge: true));
      }

      await loadWorkoutPrograms();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ CSV Uploaded and Programs Processed!')),
      );
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _extendToOneMonth(
    String programTitle,
    Map<String, List<Map<String, dynamic>>> originalDays,
  ) async {
    final daysInMonth = 30;
    final RegExp numberRegExp = RegExp(r'\d+');
    final String? numberMatch = numberRegExp.firstMatch(programTitle)?.group(0);
    final workoutDaysPerWeek = int.parse(
      numberMatch ?? '3',
    ); // Default to 3 if no number
    final originalDayCount = originalDays.length;
    final restExerciseId = await _getRestExerciseId();

    Map<String, List<Map<String, dynamic>>> extendedDays = {};
    int workoutDayIndex = 0;

    // Define workout day offsets (1-based: 1 = Monday, 7 = Sunday)
    List<int> workoutDayOffsets;
    switch (workoutDaysPerWeek) {
      case 3:
        workoutDayOffsets = [1, 3, 5]; // Mon, Wed, Fri
        break;
      case 4:
        workoutDayOffsets = [1, 3, 5, 6]; // Mon, Wed, Fri, Sat
        break;
      case 5:
        workoutDayOffsets = [1, 2, 3, 4, 5]; // Mon-Fri
        break;
      case 6:
        workoutDayOffsets = [1, 2, 3, 4, 5, 6]; // Mon-Sat
        break;
      default:
        workoutDayOffsets = List.generate(
          workoutDaysPerWeek,
          (i) => i + 1,
        ); // Consecutive days
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final weekDay = (day - 1) % 7 + 1; // 1 = Monday, 7 = Sunday
      if (workoutDayOffsets.contains(weekDay)) {
        // Workout day
        final sourceDay = 'Day ${((workoutDayIndex % originalDayCount) + 1)}';
        extendedDays['Day $day'] = List.from(originalDays[sourceDay] ?? []);
        workoutDayIndex++;
      } else {
        // Rest day
        extendedDays['Day $day'] = [
          {'exerciseId': restExerciseId, 'sets': 0, 'reps': '0'},
        ];
      }
    }

    return extendedDays;
  }

  Future<String> _getRestExerciseId() async {
    final snapshot =
        await firestore
            .collection('exercises')
            .where('name', isEqualTo: 'rest_sets_0_reps_0')
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return 'rest_sets_0_reps_0'; // Fallback
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> createWorkoutProgram() async {
    final title = createTitleController.text.trim();
    final desc = createDescriptionController.text.trim();

    if (title.isEmpty ||
        desc.isEmpty ||
        createLevel == null ||
        workoutExercisesPerDay.isEmpty ||
        imageUrl == null) {
      showError("All fields are required.");
      return;
    }

    final sanitizedTitle = title.replaceAll(' ', '_');
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final docId = '${sanitizedTitle}_$nowStr';

    final extendedDays = await _extendToOneMonth(title, workoutExercisesPerDay);

    await firestore.collection('workoutPrograms').doc(docId).set({
      'title': title,
      'image': imageUrl,
      'days': extendedDays,
      'level': createLevel,
      'description': desc,
    });

    await loadWorkoutPrograms();
    _clearFormForNewProgram();
    if (!mounted) return;
    showError('✅ Workout Program created!');
  }

  Future<void> updateExistingProgram() async {
    if (selectedProgram == null) {
      showError("No existing program selected.");
      return;
    }

    final title = createTitleController.text.trim();
    final desc = createDescriptionController.text.trim();

    if (title.isEmpty ||
        desc.isEmpty ||
        createLevel == null ||
        workoutExercisesPerDay.isEmpty ||
        imageUrl == null) {
      showError("All fields are required.");
      return;
    }

    final docId = selectedProgram!.id;
    final extendedDays = await _extendToOneMonth(title, workoutExercisesPerDay);

    await firestore.collection('workoutPrograms').doc(docId).update({
      'title': title,
      'image': imageUrl,
      'days': extendedDays,
      'level': createLevel,
      'description': desc,
    });

    await loadWorkoutPrograms();
    if (!mounted) return;
    showError('✅ Workout Program updated!');
  }

  void addNewDay() {
    workoutExercisesPerDay['Day $dayCounter'] = [];
    dayCounter++;
    setState(() {});
  }

  void addWorkoutExerciseToDay(String dayInput) {
    final day = int.tryParse(dayInput);
    final sets = int.tryParse(setsController.text);
    final reps = repsController.text.trim();
    if (day == null ||
        selectedExerciseId == null ||
        sets == null ||
        reps.isEmpty) {
      showError("Please provide valid day, exercise, sets, and reps.");
      return;
    }
    final dayKey = 'Day $day';
    workoutExercisesPerDay.putIfAbsent(dayKey, () => []);
    workoutExercisesPerDay[dayKey]!.add({
      'exerciseId': selectedExerciseId!,
      'sets': sets,
      'reps': reps,
    });
    setsController.clear();
    repsController.clear();
    setState(() {});
  }

  Widget buildDaySection(String day) {
    final items = workoutExercisesPerDay[day] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                workoutExercisesPerDay.remove(day);
                setState(() {});
              },
              child: const Text(
                'Remove Day',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
        ...items.map((config) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  "${config['exerciseId']} - ${config['sets']} sets, ${config['reps']} reps",
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  workoutExercisesPerDay[day]?.remove(config);
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
                  _clearFormForNewProgram();
                } else {
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
            if (imageUrl != null)
              if (imageUrl!.startsWith('http'))
                Image.network(imageUrl!, height: 100)
              else
                Image.file(File(imageUrl!), height: 100),
            ElevatedButton(
              onPressed: pickAndUploadImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: uploadCSVFile,
              child: const Text('Upload CSV'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: addNewDay, child: const Text('Add Day')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedExerciseId,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Exercise'),
              items:
                  exercises.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        e.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedExerciseId = val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: createDayInputController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Day Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: setsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Sets'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Reps'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => addWorkoutExerciseToDay(createDayInputController.text),
              child: const Text('Add to Day'),
            ),
            ...workoutExercisesPerDay.keys.map(buildDaySection),
            const SizedBox(height: 20),
            if (selectedProgram == null)
              ElevatedButton(
                onPressed: createWorkoutProgram,
                child: const Text('Create Program'),
              )
            else
              ElevatedButton(
                onPressed: updateExistingProgram,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Update Program'),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
