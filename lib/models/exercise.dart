class Exercise {
  final String id;
  final String name;
  final String instructions;
  final String? videoUrl;
  final String? image;
  final List<String> muscleGroups;
  final List<String> injuryRisks;
  final String category;

  // ✅ New optional fields
  final bool? isTimed;
  final int? duration;

  Exercise({
    required this.id,
    required this.name,
    required this.instructions,
    this.videoUrl,
    this.image,
    required this.muscleGroups,
    required this.injuryRisks,
    required this.category,
    this.isTimed,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'image': image,
      'muscleGroups': muscleGroups,
      'injuryRisks': injuryRisks,
      'category': category,
      if (isTimed != null) 'isTimed': isTimed,
      if (duration != null) 'duration': duration,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      instructions: map['instructions'] ?? '',
      videoUrl: map['videoUrl'],
      image: map['image'],
      muscleGroups: List<String>.from(map['muscleGroups'] ?? []),
      injuryRisks: List<String>.from(map['injuryRisks'] ?? []),
      category: map['category'] ?? '',
      isTimed: map['isTimed'],
      duration: map['duration'],
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? instructions,
    String? videoUrl,
    String? image,
    List<String>? muscleGroups,
    List<String>? injuryRisks,
    String? category,
    bool? isTimed,
    int? duration,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      image: image ?? this.image,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      injuryRisks: injuryRisks ?? this.injuryRisks,
      category: category ?? this.category,
      isTimed: isTimed ?? this.isTimed,
      duration: duration ?? this.duration,
    );
  }
}
