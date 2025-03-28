class ActiveDietPlan {
  final String dietPlanId;
  final DateTime startDate;
  final int currentDay;
  final bool isCompleted;

  /// ✅ Track completed days
  final List<int> completedDays;

  ActiveDietPlan({
    required this.dietPlanId,
    required this.startDate,
    this.currentDay = 1,
    this.isCompleted = false,
    this.completedDays = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'dietPlanId': dietPlanId,
      'startDate': startDate.toIso8601String(),
      'currentDay': currentDay,
      'isCompleted': isCompleted,
      'completedDays': completedDays,
    };
  }

  static ActiveDietPlan fromMap(Map<String, dynamic> map) {
    return ActiveDietPlan(
      dietPlanId: map['dietPlanId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      currentDay: map['currentDay'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      completedDays: List<int>.from(map['completedDays'] ?? []),
    );
  }
}
