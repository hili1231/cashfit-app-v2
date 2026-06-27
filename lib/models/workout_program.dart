class WorkoutProgram {
  final String id;
  final String title;
  final String image;
  final Map<String, List<Map<String, dynamic>>> days;
  final String level;
  final String description;
  final String? userId;
  final List<String> preferredWorkoutTimes; // Add this field

  WorkoutProgram({
    required this.id,
    required this.title,
    required this.image,
    required this.days,
    required this.level,
    required this.description,
    this.userId,
    this.preferredWorkoutTimes = const [], // Default to empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'days': days,
      'level': level,
      'description': description,
      if (userId != null) 'userId': userId,
      'preferredWorkoutTimes':
          preferredWorkoutTimes, // Include in serialization
    };
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map, String id) {
    String rawImg = map['image'] ?? map['imageUrl'] ?? '';
    if (rawImg.isEmpty || rawImg.startsWith('assets/')) {
      rawImg = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80';
    }
    return WorkoutProgram(
      id: id,
      title: map['title'] ?? '',
      image: rawImg,
      days: Map<String, List<dynamic>>.from(map['days'] ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value).map((item) => Map<String, dynamic>.from(item)).toList(),
        ),
      ),
      level: map['level'] ?? 'Beginner',
      description: map['description'] ?? '',
      userId: map['userId'],
      preferredWorkoutTimes: List<String>.from(
        map['preferredWorkoutTimes'] ?? [],
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutProgram &&
        other.id == id &&
        other.title == title &&
        other.image == image &&
        other.level == level &&
        other.description == description &&
        other.userId == userId &&
        _areListsEqual(other.preferredWorkoutTimes, preferredWorkoutTimes);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      image,
      level,
      description,
      userId,
      Object.hashAll(preferredWorkoutTimes),
    );
  }

  @override
  String toString() =>
      'WorkoutProgram(id: $id, title: $title, preferredWorkoutTimes: $preferredWorkoutTimes)';

  // Helper method to compare lists for equality
  bool _areListsEqual(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
