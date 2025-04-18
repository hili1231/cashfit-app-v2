class ActiveWorkoutProgram {
  final String workoutProgramId;
  final DateTime startDate;
  final int currentDay;
  final bool isCompleted;

  /// ✅ Track completed days
  final List<int> completedDays;

  ActiveWorkoutProgram({
    required this.workoutProgramId,
    required this.startDate,
    this.currentDay = 1,
    this.isCompleted = false,
    this.completedDays = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutProgramId': workoutProgramId,
      'startDate': startDate.toIso8601String(),
      'currentDay': currentDay,
      'isCompleted': isCompleted,
      'completedDays': completedDays,
    };
  }

  static ActiveWorkoutProgram fromMap(Map<String, dynamic> map) {
    return ActiveWorkoutProgram(
      workoutProgramId: map['workoutProgramId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      currentDay: map['currentDay'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      completedDays: List<int>.from(map['completedDays'] ?? []),
    );
  }
}
