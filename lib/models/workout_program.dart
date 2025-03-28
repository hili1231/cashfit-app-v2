class WorkoutProgram {
  final String id; // Add the ID for Firebase document reference
  final String title;
  final String image;
  final Map<String, List<String>>
  days; // day number => list of workoutExerciseIds
  final String level;
  final String description;
  final String? userId;

  WorkoutProgram({
    required this.id, // Required id for new and existing programs
    required this.title,
    required this.image,
    required this.days,
    required this.level,
    required this.description,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'days': days,
      'level': level,
      'description': description,
      if (userId != null) 'userId': userId,
    };
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutProgram(
      id: id, // Pass the id when creating from Firestore data
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      days: Map<String, List<dynamic>>.from(
        map['days'] ?? {},
      ).map((key, value) => MapEntry(key, List<String>.from(value))),
      level: map['level'] ?? 'Beginner',
      description: map['description'] ?? '',
      userId: map['userId'],
    );
  }
}
