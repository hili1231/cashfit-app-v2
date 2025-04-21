class RemovedDietPlan {
  final String dietPlanId;
  final DateTime removedDate;
  final String uid;

  RemovedDietPlan({
    required this.dietPlanId,
    required this.removedDate,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'dietPlanId': dietPlanId,
      'removedDate': removedDate.toIso8601String(),
      'uid': uid,
    };
  }

  static RemovedDietPlan fromMap(Map<String, dynamic> map) {
    return RemovedDietPlan(
      dietPlanId: map['dietPlanId'] ?? '',
      removedDate: DateTime.parse(
        map['removedDate'] ?? DateTime.now().toIso8601String(),
      ),
      uid: map['uid'] ?? '',
    );
  }
}
