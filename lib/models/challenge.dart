class Challenge {
  final String id;
  final String type; // "weight_loss", "weight_maintenance", "muscle_gain"
  final String name;
  final String description;
  final String image;
  final List<String> instructions;
  final List<String> participants;
  final double initialWeight;
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int rewardCoins; // 500 coins
  final int rewardPremiumMonths; // 3 months

  Challenge({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.image,
    required this.instructions,
    required this.participants,
    required this.initialWeight,
    required this.targetWeight,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.rewardCoins = 500,
    this.rewardPremiumMonths = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'image': image,
      'instructions': instructions,
      'participants': participants,
      'initialWeight': initialWeight,
      'targetWeight': targetWeight,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationDays': durationDays,
      'rewardCoins': rewardCoins,
      'rewardPremiumMonths': rewardPremiumMonths,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      instructions: List<String>.from(map['instructions'] ?? []),
      participants: List<String>.from(map['participants'] ?? []),
      initialWeight: (map['initialWeight'] ?? 0).toDouble(),
      targetWeight: (map['targetWeight'] ?? 0).toDouble(),

      // Safely parse startDate
      startDate:
          map['startDate'] != null
              ? DateTime.parse(map['startDate'] as String)
              : DateTime.now(),

      // Safely parse endDate
      endDate:
          map['endDate'] != null
              ? DateTime.parse(map['endDate'] as String)
              : DateTime.now(),

      durationDays: (map['durationDays'] ?? 0) as int,
      rewardCoins: (map['rewardCoins'] ?? 500) as int,
      rewardPremiumMonths: (map['rewardPremiumMonths'] ?? 3) as int,
    );
  }
}
