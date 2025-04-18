class Exercise {
  final String id;
  final String name;
  final String instructions;
  final List<String> muscleGroups;
  final List<String> injuryRisks;
  final String category;
  // Optional fields
  final String? videoUrl;
  final String? image;
  final List<String>? generalMuscleGroups;
  final bool? isTimed;
  final int? duration; // Duration in seconds for timed exercises
  final String? difficulty; // e.g., "Beginner", "Intermediate", "Advanced"
  final double? caloriesPerMinute; // Calories burned per minute
  final String? setsRange; // e.g., "3-4"
  final String? repsRange; // e.g., "8-12"
  final int? restSeconds; // Rest time between sets in seconds
  final String? exerciseType; // e.g., "Dynamic", "Isometric"
  final String? movementPattern; // e.g., "Hinge", "Squat"
  final String? specificEquipment; // e.g., "Dumbbells"
  final String? targetIntensity; // e.g., "Moderate", "High"
  final String? workoutPhase; // e.g., "Main", "Warm-Up"
  final String? minimumEquipmentAlternative; // e.g., "Bodyweight"
  final String? genderAdjustment; // e.g., none in data
  final String? pairWith; // e.g., none in data

  Exercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.muscleGroups,
    required this.injuryRisks,
    required this.category,
    this.videoUrl,
    this.image,
    this.generalMuscleGroups,
    this.isTimed,
    this.duration,
    this.difficulty,
    this.caloriesPerMinute,
    this.setsRange,
    this.repsRange,
    this.restSeconds,
    this.exerciseType,
    this.movementPattern,
    this.specificEquipment,
    this.targetIntensity,
    this.workoutPhase,
    this.minimumEquipmentAlternative,
    this.genderAdjustment,
    this.pairWith, int? recommendedDurationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'instructions': instructions,
      'muscleGroups': muscleGroups,
      'injuryRisks': injuryRisks,
      'category': category,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (image != null) 'image': image,
      if (generalMuscleGroups != null)
        'generalMuscleGroups': generalMuscleGroups,
      if (isTimed != null) 'isTimed': isTimed,
      if (duration != null) 'duration': duration,
      if (difficulty != null) 'difficulty': difficulty,
      if (caloriesPerMinute != null) 'caloriesPerMinute': caloriesPerMinute,
      if (setsRange != null) 'setsRange': setsRange,
      if (repsRange != null) 'repsRange': repsRange,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (exerciseType != null) 'exerciseType': exerciseType,
      if (movementPattern != null) 'movementPattern': movementPattern,
      if (specificEquipment != null) 'specificEquipment': specificEquipment,
      if (targetIntensity != null) 'targetIntensity': targetIntensity,
      if (workoutPhase != null) 'workoutPhase': workoutPhase,
      if (minimumEquipmentAlternative != null)
        'minimumEquipmentAlternative': minimumEquipmentAlternative,
      if (genderAdjustment != null) 'genderAdjustment': genderAdjustment,
      if (pairWith != null) 'pairWith': pairWith,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      muscleGroups: List<String>.from(map['muscleGroups'] ?? []),
      injuryRisks: List<String>.from(map['injuryRisks'] ?? []),
      category: map['category'] as String? ?? '',
      videoUrl: map['videoUrl'] as String?,
      image: map['image'] as String?,
      generalMuscleGroups:
          map['generalMuscleGroups'] != null
              ? List<String>.from(map['generalMuscleGroups'])
              : null,
      isTimed: map['isTimed'] as bool?,
      duration: map['duration'] as int?,
      difficulty: map['difficulty'] as String?,
      caloriesPerMinute: (map['caloriesPerMinute'] as num?)?.toDouble(),
      setsRange: map['setsRange'] as String?,
      repsRange: map['repsRange'] as String?,
      restSeconds: map['restSeconds'] as int?,
      exerciseType: map['exerciseType'] as String?,
      movementPattern: map['movementPattern'] as String?,
      specificEquipment: map['specificEquipment'] as String?,
      targetIntensity: map['targetIntensity'] as String?,
      workoutPhase: map['workoutPhase'] as String?,
      minimumEquipmentAlternative:
          map['minimumEquipmentAlternative'] as String?,
      genderAdjustment: map['genderAdjustment'] as String?,
      pairWith: map['pairWith'] as String?,
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? instructions,
    List<String>? muscleGroups,
    List<String>? injuryRisks,
    String? category,
    String? videoUrl,
    String? image,
    List<String>? generalMuscleGroups,
    bool? isTimed,
    int? duration,
    String? difficulty,
    double? caloriesPerMinute,
    String? setsRange,
    String? repsRange,
    int? restSeconds,
    String? exerciseType,
    String? movementPattern,
    String? specificEquipment,
    String? targetIntensity,
    String? workoutPhase,
    String? minimumEquipmentAlternative,
    String? genderAdjustment,
    String? pairWith,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      instructions: instructions ?? this.instructions,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      injuryRisks: injuryRisks ?? this.injuryRisks,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      image: image ?? this.image,
      generalMuscleGroups: generalMuscleGroups ?? this.generalMuscleGroups,
      isTimed: isTimed ?? this.isTimed,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      caloriesPerMinute: caloriesPerMinute ?? this.caloriesPerMinute,
      setsRange: setsRange ?? this.setsRange,
      repsRange: repsRange ?? this.repsRange,
      restSeconds: restSeconds ?? this.restSeconds,
      exerciseType: exerciseType ?? this.exerciseType,
      movementPattern: movementPattern ?? this.movementPattern,
      specificEquipment: specificEquipment ?? this.specificEquipment,
      targetIntensity: targetIntensity ?? this.targetIntensity,
      workoutPhase: workoutPhase ?? this.workoutPhase,
      minimumEquipmentAlternative:
          minimumEquipmentAlternative ?? this.minimumEquipmentAlternative,
      genderAdjustment: genderAdjustment ?? this.genderAdjustment,
      pairWith: pairWith ?? this.pairWith,
    );
  }
}
