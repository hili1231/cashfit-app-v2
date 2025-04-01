class WorkoutProgram {
  final String id;
  final String title;
  final String image;
  final Map<String, List<String>> days;
  final String level;
  final String description;
  final String? userId;

  WorkoutProgram({
    required this.id,
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
      id: id,
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

  // 👇 Add these methods to fix DropdownButton equality issues
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutProgram && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorkoutProgram(id: $id, title: $title)';
}
