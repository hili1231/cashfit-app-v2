import 'package:cashfit/models/donation.dart';
import 'package:cashfit/models/progress_video.dart';

class Challenge {
  final String id;
  final String name;
  final String description;
  final int participants;
  final Map<String, List<ProgressVideo>> progressVideos;
  final List<String> instructions;
  final String image;
  final DateTime? endDate;
  final List<String> winners;
  final List<Donation> donations;
  final double prizeAmount;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.progressVideos,
    required this.instructions,
    required this.image,
    this.endDate,
    this.winners = const [],
    this.donations = const [],
    required this.prizeAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
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
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      participants: map['participants'] ?? 0,
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
    );
  }
}
