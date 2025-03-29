import '../../models/donation.dart';
import '../../models/progress_video.dart';

class Challenge {
  final String id;
  final String name;
  final String description;

  // Instead of storing just an int, store the actual user IDs
  final List<String> participants;

  final Map<String, List<ProgressVideo>> progressVideos;
  final List<String> instructions;
  final String image;
  final DateTime? endDate;
  final List<String> winners;
  final List<Donation> donations;
  final double prizeAmount;
  final int? maxParticipants; // Optional if you want to limit participants

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    // CHANGED: store user IDs
    this.participants = const [],

    this.progressVideos = const {},
    this.instructions = const [],
    this.image = '',
    this.endDate,
    this.winners = const [],
    this.donations = const [],
    required this.prizeAmount,
    this.maxParticipants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      // store participant user IDs in Firestore
      'participants': participants,

      'progressVideos': progressVideos.map(
        (userId, videos) =>
            MapEntry(userId, videos.map((v) => v.toMap()).toList()),
      ),
      'instructions': instructions,
      'image': image,
      'endDate': endDate?.toIso8601String(),
      'winners': winners,
      'donations': donations.map((d) => d.toMap()).toList(),
      'prizeAmount': prizeAmount,

      // Only include if you use it
      'maxParticipants': maxParticipants,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',

      // CHANGED: read participants as List<String>
      participants: List<String>.from(map['participants'] ?? []),

      progressVideos:
          (map['progressVideos'] as Map<String, dynamic>?)?.map(
            (userId, videoList) => MapEntry(
              userId,
              (videoList as List<dynamic>)
                  .map((v) => ProgressVideo.fromMap(v))
                  .toList(),
            ),
          ) ??
          {},
      instructions: List<String>.from(map['instructions'] ?? []),
      image: map['image'] ?? '',
      endDate:
          map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      winners: List<String>.from(map['winners'] ?? []),
      donations:
          (map['donations'] as List<dynamic>?)
              ?.map((d) => Donation.fromMap(d))
              .toList() ??
          [],
      prizeAmount: (map['prizeAmount'] as num?)?.toDouble() ?? 0.0,

      // Only include if you use it
      maxParticipants: map['maxParticipants'],
    );
  }
}
