import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
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
  List<Exercise> filteredExercises = [];

  String? selectedExerciseId;
  String? imageUrl,
      videoUrl,
      category,
      difficulty,
      exerciseType,
      movementPattern,
      specificEquipment,
      targetIntensity,
      workoutPhase,
      minimumEquipmentAlternative,
      genderAdjustment,
      pairWith;

  List<String> muscleGroups = [];
  List<String> generalMuscleGroups = [];
  List<String> injuryRisks = [];

  final nameController = TextEditingController();
  final instructionsController = TextEditingController();
  final searchController = TextEditingController();
  final caloriesPerMinuteController = TextEditingController();
  final setsRangeController = TextEditingController();
  final repsRangeController = TextEditingController();
  final restSecondsController = TextEditingController();
  final durationController = TextEditingController();
  bool isTimed = false;

  bool isLoadingExercises = true;
  bool isDownloadingCsv = false;

  final List<String> allCategories = [
    'Gym',
    'Bodyweight',
    'Cardio',
    'dumbbells',
    'Rest',
    'Strength',
    'Core',
    'Warm-Up',
    'Cool-Down',
    'Kettlebell',
  ];

  final List<String> allMuscleGroups = [
    'Upper Chest',
    'Middle Chest',
    'Lower Chest',
    'Chest',
    'Upper Back',
    'Middle Back',
    'Lower Back',
    'Back',
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
    'Full Body',
    'Core',
    'Quads',
    'Hamstrings',
    'Traps',
  ];

  final List<String> allInjuries = [
    'Knee',
    'Shoulder',
    'Back',
    'Wrist',
    'Ankle',
    'Rest',
    'Elbows',
    'Lower Back',
    'Neck',
    'Wrists',
    'Hips',
  ];

  final List<String> difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> exerciseTypes = [
    'Compound',
    'Accessory',
    'Dynamic',
    'Isometric',
    'Warm-Up',
    'Cool-Down',
  ];
  final List<String> movementPatterns = [
    'Push',
    'Pull',
    'Squat',
    'Hinge',
    'Other',
    'Rotation',
    'Lunge',
    'Step-Up',
    'Raise',
    'Extension',
    'Jump',
    'Run',
    'Plank',
  ];
  final List<String> equipmentOptions = [
    'None',
    'Smith Machine',
    'Dumbbells',
    'EZ Bar',
    'Cable',
    'Barbell',
    'Pull-Up Bar',
    'Bench',
    'Cardio Equipment',
    'Resistance Band',
    'Medicine Ball',
    'Ab Wheel',
    'Kettlebell',
    'Leg Press Machine',
    'Seated Row Machine',
    'Chest Press Machine',
  ];
  final List<String> intensities = ['Low', 'Moderate', 'High'];
  final List<String> phases = [
    'Main',
    'Accessory',
    'Warm-Up',
    'Cool-Down',
    'Cardio',
  ];

  @override
  void initState() {
    super.initState();
    loadExercises();
    searchController.addListener(_updateFilteredExercises);
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredExercises);
    searchController.dispose();
    nameController.dispose();
    instructionsController.dispose();
    caloriesPerMinuteController.dispose();
    setsRangeController.dispose();
    repsRangeController.dispose();
    restSecondsController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> cacheExercises(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final exerciseMaps = exercises.map((e) => e.toMap()).toList();
    await prefs.setString('cached_exercises', jsonEncode(exerciseMaps));
  }

  Future<List<Exercise>> loadCachedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_exercises');
    if (cached == null) return [];
    final List<dynamic> exerciseMaps = jsonDecode(cached);
    return exerciseMaps.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<void> loadExercises() async {
    setState(() => isLoadingExercises = true);
    try {
      exercises = await loadCachedExercises();
      if (exercises.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          filteredExercises = [...exercises];
          isLoadingExercises = false;
        });
        return;
      }

      const batchSize = 100;
      List<Exercise> allExercises = [];
      QuerySnapshot<Map<String, dynamic>>? lastSnapshot;

      while (true) {
        Query<Map<String, dynamic>> query = firestore
            .collection('exercises')
            .orderBy('id')
            .limit(batchSize);
        if (lastSnapshot != null) {
          query = query.startAfterDocument(lastSnapshot.docs.last);
        }

        final snapshot = await query.get().timeout(
          const Duration(seconds: 30),
          onTimeout:
              () =>
                  throw TimeoutException(
                    'Firestore query timed out after 30 seconds',
                  ),
        );

        if (snapshot.docs.isEmpty) break;

        final batchExercises =
            snapshot.docs
                .map((doc) => Exercise.fromMap(doc.data()))
                .where((ex) => ex.id.isNotEmpty)
                .toList();

        allExercises.addAll(batchExercises);
        lastSnapshot = snapshot;

        if (snapshot.docs.length < batchSize) break;

        if (!mounted) return;
        setState(() {
          exercises = allExercises;
          filteredExercises = [...exercises];
        });
      }

      if (!mounted) return;
      setState(() {
        exercises = allExercises;
        filteredExercises = [...exercises];
        isLoadingExercises = false;
      });

      await cacheExercises(exercises);
    } catch (e) {
      debugPrint("Error loading exercises: $e");
      if (!mounted) return;
      setState(() => isLoadingExercises = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading exercises: $e")));
    }
  }

  void _updateFilteredExercises() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredExercises = [...exercises];
      } else {
        filteredExercises =
            exercises
                .where((ex) => ex.name.toLowerCase().contains(query))
                .toList();
      }

      if (selectedExerciseId != null &&
          !filteredExercises.any((e) => e.id == selectedExerciseId)) {
        _clearForm();
      }
    });
  }

  void _clearForm() {
    selectedExerciseId = null;
    nameController.clear();
    instructionsController.clear();
    category = null;
    muscleGroups.clear();
    generalMuscleGroups.clear();
    injuryRisks.clear();
    imageUrl = null;
    videoUrl = null;
    isTimed = false;
    durationController.clear();
    difficulty = null;
    caloriesPerMinuteController.clear();
    setsRangeController.clear();
    repsRangeController.clear();
    restSecondsController.clear();
    exerciseType = null;
    movementPattern = null;
    specificEquipment = null;
    targetIntensity = null;
    workoutPhase = null;
    minimumEquipmentAlternative = null;
    genderAdjustment = null;
    pairWith = null;
  }

  Future<String?> uploadFile(XFile file) async {
    try {
      String fileName = file.name;
      final storageRef = storage.ref().child('uploads/$fileName');
      final uploadTask = storageRef.putFile(File(file.path));
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading file: $e");
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    final data =
        Exercise(
          id: exerciseId ?? name.toLowerCase().replaceAll(' ', '_'),
          name: name,
          instructions: instructions,
          muscleGroups: muscleGroups,
          injuryRisks: injuryRisks,
          category: category!,
          videoUrl: videoUrl,
          image: imageUrl,
          generalMuscleGroups:
              generalMuscleGroups.isNotEmpty ? generalMuscleGroups : null,
          isTimed: isTimed,
          duration: int.tryParse(durationController.text),
          difficulty: difficulty,
          caloriesPerMinute:
              double.tryParse(caloriesPerMinuteController.text),
          setsRange:
              setsRangeController.text.isNotEmpty
                  ? setsRangeController.text
                  : null,
          repsRange:
              repsRangeController.text.isNotEmpty
                  ? repsRangeController.text
                  : null,
          restSeconds: int.tryParse(restSecondsController.text),
          exerciseType: exerciseType,
          movementPattern: movementPattern,
          specificEquipment: specificEquipment,
          targetIntensity: targetIntensity,
          workoutPhase: workoutPhase,
          minimumEquipmentAlternative: minimumEquipmentAlternative,
          genderAdjustment: genderAdjustment,
          pairWith: pairWith,
        ).toMap();

    try {
      if (exerciseId != null) {
        await firestore
            .collection('exercises')
            .doc(exerciseId)
            .set(data, SetOptions(merge: true));
      } else {
        await firestore.collection('exercises').doc(data['id']).set(data);
      }

      if (!mounted) return;
      await loadExercises();
      _clearForm();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise saved successfully!')),
      );
    } catch (e) {
      debugPrint("Error saving exercise: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving exercise: $e")));
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    try {
      await firestore.collection('exercises').doc(exerciseId).delete();
      if (!mounted) return;
      setState(() {
        exercises.removeWhere((e) => e.id == exerciseId);
        filteredExercises.removeWhere((e) => e.id == exerciseId);
        selectedExerciseId = null;
      });
      await cacheExercises(exercises);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise deleted successfully!')),
      );
    } catch (e) {
      debugPrint("Error deleting exercise: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting exercise: $e")));
    }
  }

  Future<void> uploadExercisesFromLocal() async {
    try {
      for (final ex in exerciseLibrary) {
        final map = ex.toMap();
        map['id'] =
            map['id'] != null && map['id'].toString().isNotEmpty
                ? map['id']
                : ex.name.toLowerCase().replaceAll(' ', '_');
        await firestore.collection('exercises').doc(map['id']).set(map);
      }
      if (!mounted) return;
      await loadExercises();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercises uploaded from local data')),
      );
    } catch (e) {
      debugPrint("Error uploading exercises from local: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error uploading exercises: $e")));
    }
  }

  Future<void> pickAndUploadImageOrVideo({bool isVideo = false}) async {
    final picker = ImagePicker();
    final pickedFile =
        isVideo
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final url = await uploadFile(pickedFile);
      if (url != null) {
        setState(() => isVideo ? videoUrl = url : imageUrl = url);
      }
    }
  }

  Future<void> uploadExercisesFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'Select Exercise CSV File',
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected.')));
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              backgroundColor: Colors.grey,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Uploading exercises from CSV...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      );

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
      );

      if (csvData.isEmpty || csvData.length < 2) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file is empty or invalid.')),
        );
        return;
      }

      final batch = firestore.batch();
      int uploadedCount = 0;

      for (var row in csvData.skip(1)) {
        if (row.length < 8) {
          debugPrint("Skipping invalid row: $row");
          continue;
        }

        final exercise = Exercise(
          id: row[0]?.toString() ?? '',
          name: row[1]?.toString() ?? '',
          instructions: row[2]?.toString() ?? '',
          videoUrl:
              row[3]?.toString().isNotEmpty ?? false ? row[3].toString() : null,
          image:
              row[4]?.toString().isNotEmpty ?? false ? row[4].toString() : null,
          muscleGroups:
              row[5]?.toString().isNotEmpty ?? false
                  ? row[5].toString().split(';')
                  : [],
          generalMuscleGroups:
              row[6]?.toString().isNotEmpty ?? false
                  ? row[6].toString().split(';')
                  : null,
          injuryRisks:
              row[7]?.toString().isNotEmpty ?? false
                  ? row[7].toString().split(';')
                  : [],
          category: row[8]?.toString() ?? '',
          isTimed: row[9]?.toString().toLowerCase() == 'true',
          difficulty:
              row[10]?.toString().isNotEmpty ?? false
                  ? row[10].toString()
                  : null,
          caloriesPerMinute: double.tryParse(row[11]?.toString() ?? ''),
          setsRange:
              row[12]?.toString().isNotEmpty ?? false
                  ? row[12].toString()
                  : null,
          repsRange:
              row[13]?.toString().isNotEmpty ?? false
                  ? row[13].toString()
                  : null,
          restSeconds: int.tryParse(row[14]?.toString() ?? ''),
          exerciseType:
              row[15]?.toString().isNotEmpty ?? false
                  ? row[15].toString()
                  : null,
          movementPattern:
              row[16]?.toString().isNotEmpty ?? false
                  ? row[16].toString()
                  : null,
          specificEquipment:
              row[17]?.toString().isNotEmpty ?? false
                  ? row[17].toString()
                  : null,
          targetIntensity:
              row[18]?.toString().isNotEmpty ?? false
                  ? row[18].toString()
                  : null,
          workoutPhase:
              row[19]?.toString().isNotEmpty ?? false
                  ? row[19].toString()
                  : null,
          recommendedDurationSeconds: int.tryParse(row[20]?.toString() ?? ''),
          minimumEquipmentAlternative:
              row[21]?.toString().isNotEmpty ?? false
                  ? row[21].toString()
                  : null,
          genderAdjustment:
              row[22]?.toString().isNotEmpty ?? false
                  ? row[22].toString()
                  : null,
          pairWith:
              row[23]?.toString().isNotEmpty ?? false
                  ? row[23].toString()
                  : null,
        );

        if (exercise.id.isEmpty ||
            exercise.name.isEmpty ||
            exercise.instructions.isEmpty ||
            exercise.category.isEmpty) {
          debugPrint(
            "Skipping exercise with missing required fields: ${exercise.id}",
          );
          continue;
        }

        batch.set(
          firestore.collection('exercises').doc(exercise.id),
          exercise.toMap(),
        );
        uploadedCount++;
      }

      await batch.commit();
      await loadExercises();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Uploaded $uploadedCount exercises from CSV.'),
        ),
      );
    } catch (e) {
      debugPrint("Error uploading exercises from CSV: $e");
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading exercises: $e')));
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
                  onSelected:
                      (_) => setState(
                        () =>
                            selected
                                ? selectedList.remove(item)
                                : selectedList.add(item),
                      ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.grey),
    border: OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Exercise Management'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Add/Edit Exercise', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Exercise Name *'),
            ),
            TextField(
              controller: instructionsController,
              decoration: _inputDecoration('Instructions *'),
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
              decoration: _inputDecoration('Category *'),
            ),
            const SizedBox(height: 10),
            _buildChips(
              allMuscleGroups,
              muscleGroups,
              'Select Muscle Groups *',
            ),
            _buildChips(
              allMuscleGroups,
              generalMuscleGroups,
              'General Muscle Groups (Optional)',
            ),
            _buildChips(allInjuries, injuryRisks, 'Injury Risks (Optional)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickAndUploadImageOrVideo(),
                    child: const Text('Upload Image'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickAndUploadImageOrVideo(isVideo: true),
                    child: const Text('Upload Video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Is Timed Exercise'),
              value: isTimed,
              onChanged: (val) => setState(() => isTimed = val ?? false),
            ),
            TextField(
              controller: durationController,
              decoration: _inputDecoration('Duration (seconds)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: difficulties.contains(difficulty) ? difficulty : null,
              items:
                  difficulties
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) => setState(() => difficulty = val),
              decoration: _inputDecoration('Difficulty'),
            ),
            TextField(
              controller: caloriesPerMinuteController,
              decoration: _inputDecoration('Calories Per Minute'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: setsRangeController,
              decoration: _inputDecoration('Sets Range (e.g., 3-4)'),
            ),
            TextField(
              controller: repsRangeController,
              decoration: _inputDecoration('Reps Range (e.g., 8-12)'),
            ),
            TextField(
              controller: restSecondsController,
              decoration: _inputDecoration('Rest Time (seconds)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: exerciseTypes.contains(exerciseType) ? exerciseType : null,
              items:
                  exerciseTypes
                      .map((et) => DropdownMenuItem(value: et, child: Text(et)))
                      .toList(),
              onChanged: (val) => setState(() => exerciseType = val),
              decoration: _inputDecoration('Exercise Type'),
            ),
            DropdownButtonFormField<String>(
              value:
                  movementPatterns.contains(movementPattern)
                      ? movementPattern
                      : null,
              items:
                  movementPatterns
                      .map((mp) => DropdownMenuItem(value: mp, child: Text(mp)))
                      .toList(),
              onChanged: (val) => setState(() => movementPattern = val),
              decoration: _inputDecoration('Movement Pattern'),
            ),
            DropdownButtonFormField<String>(
              value:
                  equipmentOptions.contains(specificEquipment)
                      ? specificEquipment
                      : null,
              items:
                  equipmentOptions
                      .map((eq) => DropdownMenuItem(value: eq, child: Text(eq)))
                      .toList(),
              onChanged: (val) => setState(() => specificEquipment = val),
              decoration: _inputDecoration('Specific Equipment'),
            ),
            DropdownButtonFormField<String>(
              value:
                  intensities.contains(targetIntensity)
                      ? targetIntensity
                      : null,
              items:
                  intensities
                      .map((ti) => DropdownMenuItem(value: ti, child: Text(ti)))
                      .toList(),
              onChanged: (val) => setState(() => targetIntensity = val),
              decoration: _inputDecoration('Target Intensity'),
            ),
            DropdownButtonFormField<String>(
              value: phases.contains(workoutPhase) ? workoutPhase : null,
              items:
                  phases
                      .map((wp) => DropdownMenuItem(value: wp, child: Text(wp)))
                      .toList(),
              onChanged: (val) => setState(() => workoutPhase = val),
              decoration: _inputDecoration('Workout Phase'),
            ),
            DropdownButtonFormField<String>(
              value:
                  equipmentOptions.contains(minimumEquipmentAlternative)
                      ? minimumEquipmentAlternative
                      : null,
              items:
                  equipmentOptions
                      .map((eq) => DropdownMenuItem(value: eq, child: Text(eq)))
                      .toList(),
              onChanged:
                  (val) => setState(() => minimumEquipmentAlternative = val),
              decoration: _inputDecoration('Minimum Equipment Alternative'),
            ),
            TextField(
              controller: TextEditingController(text: genderAdjustment),
              onChanged: (val) => genderAdjustment = val,
              decoration: _inputDecoration('Gender Adjustment'),
            ),
            TextField(
              controller: TextEditingController(text: pairWith),
              onChanged: (val) => pairWith = val,
              decoration: _inputDecoration('Pair With'),
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
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              hint: const Text('Select Exercise to Edit'),
              value:
                  filteredExercises.any((e) => e.id == selectedExerciseId)
                      ? selectedExerciseId
                      : null,
              isExpanded: true,
              onChanged: (newValue) {
                final exists = filteredExercises.any((e) => e.id == newValue);
                if (exists && newValue != null) {
                  final ex = filteredExercises.firstWhere(
                    (e) => e.id == newValue,
                  );
                  setState(() {
                    selectedExerciseId = newValue;
                    nameController.text = ex.name;
                    instructionsController.text = ex.instructions;
                    imageUrl = ex.image;
                    videoUrl = ex.videoUrl;
                    category = ex.category;
                    muscleGroups = List.from(ex.muscleGroups);
                    generalMuscleGroups =
                        ex.generalMuscleGroups != null
                            ? List.from(ex.generalMuscleGroups!)
                            : [];
                    injuryRisks = List.from(ex.injuryRisks);
                    isTimed = ex.isTimed ?? false;
                    durationController.text = ex.duration?.toString() ?? '';
                    difficulty = ex.difficulty;
                    caloriesPerMinuteController.text =
                        ex.caloriesPerMinute?.toString() ?? '';
                    setsRangeController.text = ex.setsRange ?? '';
                    repsRangeController.text = ex.repsRange ?? '';
                    restSecondsController.text =
                        ex.restSeconds?.toString() ?? '';
                    exerciseType = ex.exerciseType;
                    movementPattern = ex.movementPattern;
                    specificEquipment = ex.specificEquipment;
                    targetIntensity = ex.targetIntensity;
                    workoutPhase = ex.workoutPhase;
                    minimumEquipmentAlternative =
                        ex.minimumEquipmentAlternative;
                    genderAdjustment = ex.genderAdjustment;
                    pairWith = ex.pairWith;
                  });
                } else {
                  setState(() => selectedExerciseId = null);
                }
              },
              items:
                  filteredExercises
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
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
            const Divider(height: 40),
            ElevatedButton(
              onPressed:
                  isLoadingExercises || isDownloadingCsv
                      ? null
                      : downloadExercisesAsCsv,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child:
                  isDownloadingCsv
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('⬇ Download Exercises as CSV'),
            ),
            const Divider(height: 40),
            ElevatedButton(
              onPressed: uploadExercisesFromCsv,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('⬆ Upload Exercises from CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> downloadExercisesAsCsv() async {
    if (isLoadingExercises || exercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for exercises to load before exporting.'),
        ),
      );
      return;
    }

    setState(() => isDownloadingCsv = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              backgroundColor: Colors.grey,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Generating CSV file...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      );

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exercise Data CSV',
        fileName: 'exercises.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath == null) {
        if (!mounted) return;
        Navigator.pop(context);
        setState(() => isDownloadingCsv = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File save cancelled.')));
        return;
      }

      final file = File(outputPath);
      final sink = file.openWrite();
      const csvConverter = ListToCsvConverter();
      final header = [
        'id',
        'name',
        'instructions',
        'videoUrl',
        'image',
        'muscleGroups',
        'generalMuscleGroups',
        'injuryRisks',
        'category',
        'isTimed',
        'difficulty',
        'caloriesPerMinute',
        'setsRange',
        'repsRange',
        'restSeconds',
        'exerciseType',
        'movementPattern',
        'specificEquipment',
        'targetIntensity',
        'workoutPhase',
        'recommendedDurationSeconds',
        'minimumEquipmentAlternative',
        'genderAdjustment',
        'pairWith',
      ];
      sink.write(csvConverter.convert([header]));
      sink.write('\n');

      const chunkSize = 100;
      for (int i = 0; i < exercises.length; i += chunkSize) {
        final chunk = exercises.sublist(
          i,
          i + chunkSize > exercises.length ? exercises.length : i + chunkSize,
        );
        final chunkData =
            chunk
                .map(
                  (exercise) => [
                    exercise.id,
                    exercise.name,
                    exercise.instructions,
                    exercise.videoUrl ?? '',
                    exercise.image ?? '',
                    exercise.muscleGroups.join(';'),
                    exercise.generalMuscleGroups?.join(';') ?? '',
                    exercise.injuryRisks.join(';'),
                    exercise.category,
                    exercise.isTimed ?? false,
                    exercise.difficulty ?? '',
                    exercise.caloriesPerMinute ?? '',
                    exercise.setsRange ?? '',
                    exercise.repsRange ?? '',
                    exercise.restSeconds ?? '',
                    exercise.exerciseType ?? '',
                    exercise.movementPattern ?? '',
                    exercise.specificEquipment ?? '',
                    exercise.targetIntensity ?? '',
                    exercise.workoutPhase ?? '',
                    exercise.duration ?? '',
                    exercise.minimumEquipmentAlternative ?? '',
                    exercise.genderAdjustment ?? '',
                    exercise.pairWith ?? '',
                  ],
                )
                .toList();

        sink.write(csvConverter.convert(chunkData));
        if (i + chunkSize < exercises.length) sink.write('\n');
        await Future.delayed(Duration.zero);
      }

      await sink.flush();
      await sink.close();

      if (!mounted) return;
      Navigator.pop(context);
      setState(() => isDownloadingCsv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Exercises exported to $outputPath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => isDownloadingCsv = false);
      debugPrint("Error exporting exercises to CSV: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error exporting exercises: $e")));
    }
  }
}
