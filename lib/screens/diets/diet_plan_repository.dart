import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveDietPlan {
  final String dietPlanId;
  final DateTime startDate;
  final int currentDay;
  final List<int> completedDays;
  final DateTime? lastCompletion;

  ActiveDietPlan({
    required this.dietPlanId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    this.lastCompletion,
  });

  factory ActiveDietPlan.fromMap(Map<String, dynamic> data) {
    return ActiveDietPlan(
      dietPlanId: data['dietPlanId'] ?? '',
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

class DietPlanRepository {
  final FirebaseFirestore _firestore;

  DietPlanRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> setActiveDietPlan(
    String userId,
    String dietPlanId,
    int dayNumber,
  ) async {
    final activePlanRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('activeDietPlans')
        .doc(dietPlanId);

    await activePlanRef.set({
      'dietPlanId': dietPlanId,
      'startDate': DateTime.now().toIso8601String(),
      'currentDay': dayNumber,
      'completedDays': [],
    });
  }

  Future<void> toggleDayCompleted(
    String userId,
    String dietPlanId,
    int dayNumber,
    bool markDone,
    int totalDays,
  ) async {
    final activePlanRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('activeDietPlans')
        .doc(dietPlanId);

    final activePlanDoc = await activePlanRef.get();
    if (!activePlanDoc.exists) {
      throw Exception('Diet plan not active');
    }

    final data = activePlanDoc.data()!;
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

    await activePlanRef.set({
      'dietPlanId': dietPlanId,
      'startDate': data['startDate'] ?? DateTime.now().toIso8601String(),
      'currentDay': newCurrentDay,
      'completedDays': completedDays,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(userId).update({
      'lastMealPlanCompletionDate':
          markDone ? FieldValue.serverTimestamp() : null,
      'mealsTracked': FieldValue.increment(markDone ? 1 : -1),
      // no points increment here
    });
  }

  Stream<ActiveDietPlan?> streamActivePlan(String userId, String dietPlanId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activeDietPlans')
        .doc(dietPlanId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? ActiveDietPlan.fromMap(snapshot.data()!) : null,
        );
  }
}
