import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise.dart';
import '../../data/exercise_data.dart';

class ActiveWorkoutProgram {
  final String workoutProgramId;
  final DateTime startDate;
  final int currentDay;
  final List<int> completedDays;
  final DateTime? lastCompletion;

  ActiveWorkoutProgram({
    required this.workoutProgramId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    this.lastCompletion,
  });

  factory ActiveWorkoutProgram.fromMap(Map<String, dynamic> data) {
    return ActiveWorkoutProgram(
      workoutProgramId: data['workoutProgramId'] ?? '',
      startDate: DateTime.parse(
        data['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      currentDay: data['currentDay'] ?? 1,
      completedDays:
          (data['completedDays'] as List<dynamic>?)?.cast<int>() ?? [],
      lastCompletion: (data['lastCompletion'] as Timestamp?)?.toDate(),
    );
  }
}

class WorkoutRepository {
  final FirebaseFirestore _firestore;

  WorkoutRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> setActiveWorkout(
    String userId,
    String workoutProgramId,
    int dayNumber,
  ) async {
    final activeProgramRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('activeWorkoutPrograms')
        .doc(workoutProgramId);

    await activeProgramRef.set({
      'workoutProgramId': workoutProgramId,
      'startDate': DateTime.now().toIso8601String(),
      'currentDay': dayNumber,
      'completedDays': [],
    });
  }

  Future<void> toggleDayCompleted(
    String userId,
    String workoutProgramId,
    int dayNumber,
    bool markDone,
    int totalDays,
  ) async {
    final activeProgramRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('activeWorkoutPrograms')
        .doc(workoutProgramId);

    final activeProgramDoc = await activeProgramRef.get();
    if (!activeProgramDoc.exists) {
      throw Exception('Workout program not active');
    }

    final data = activeProgramDoc.data()!;
    List<int> completedDays =
        (data['completedDays'] as List<dynamic>?)?.cast<int>() ?? [];

    if (markDone && !completedDays.contains(dayNumber)) {
      completedDays.add(dayNumber);
    } else if (!markDone && completedDays.contains(dayNumber)) {
      completedDays.remove(dayNumber);
    } else {
      return; // No change needed
    }

    int newCurrentDay = data['currentDay'] ?? 1;
    if (markDone && newCurrentDay < totalDays) {
      newCurrentDay++;
      while (newCurrentDay <= totalDays &&
          completedDays.contains(newCurrentDay)) {
        newCurrentDay++;
      }
      if (newCurrentDay > totalDays) {
        newCurrentDay = totalDays;
      }
    } else if (!markDone) {
      newCurrentDay = dayNumber;
      if (newCurrentDay > completedDays.length + 1) {
        newCurrentDay = completedDays.isNotEmpty ? completedDays.last + 1 : 1;
      }
    }

    await activeProgramRef.set({
      'workoutProgramId': workoutProgramId,
      'startDate': data['startDate'] ?? DateTime.now().toIso8601String(),
      'currentDay': newCurrentDay,
      'completedDays': completedDays,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(userId).update({
      'lastWorkoutCompletionDate':
          markDone ? FieldValue.serverTimestamp() : null,
      'workoutsCompleted': FieldValue.increment(markDone ? 1 : -1),
    });
  }

  Stream<ActiveWorkoutProgram?> streamActiveWorkout(
    String userId,
    String workoutProgramId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activeWorkoutPrograms')
        .doc(workoutProgramId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists
                  ? ActiveWorkoutProgram.fromMap(snapshot.data()!)
                  : null,
        );
  }

  Future<List<Exercise>> fetchExercises(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .where(FieldPath.documentId, whereIn: exerciseIds)
          .get()
          .timeout(const Duration(seconds: 1));
      final list = snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data()..['id'] = doc.id))
          .toList();
      if (list.isNotEmpty) return list;
      return _getFallbackExercises(exerciseIds);
    } catch (e) {
      return _getFallbackExercises(exerciseIds);
    }
  }

  List<Exercise> _getFallbackExercises(List<String> exerciseIds) {
    List<Exercise> matched = [];
    for (var id in exerciseIds) {
      final found = exerciseLibrary.firstWhere(
        (ex) => ex.id == id,
        orElse: () => exerciseLibrary.first,
      );
      matched.add(found);
    }
    return matched.isNotEmpty ? matched : exerciseLibrary;
  }
}
