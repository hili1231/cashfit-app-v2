import '../../models/progress_video.dart';

class SideHustle {
  final String id;
  final String title;
  final String description;
  final int reward;
  final String videoRequirement;
  final String thumbnail;

  final Map<String, List<ProgressVideo>> progressVideos;
  final List<String> participants;
  final List<String> winners;
  final DateTime? endDate;
  final bool isActive;
  final String? creatorId;
  final List<String> tags;
  final int? maxParticipants;

  SideHustle({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.videoRequirement,
    required this.thumbnail,
    this.progressVideos = const {},
    this.participants = const [],
    this.winners = const [],
    this.endDate,
    this.isActive = true,
    this.creatorId,
    this.tags = const [],
    this.maxParticipants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'videoRequirement': videoRequirement,
      'thumbnail': thumbnail,
      'progressVideos': progressVideos.map(
        (userId, videos) =>
            MapEntry(userId, videos.map((v) => v.toMap()).toList()),
      ),
      'participants': participants,
      'winners': winners,
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'creatorId': creatorId,
      'tags': tags,
      'maxParticipants': maxParticipants,
    };
  }

  factory SideHustle.fromMap(Map<String, dynamic> map) {
    return SideHustle(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reward: map['reward'] ?? 0,
      videoRequirement: map['videoRequirement'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
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
      participants: List<String>.from(map['participants'] ?? []),
      winners: List<String>.from(map['winners'] ?? []),
      endDate:
          map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      isActive: map['isActive'] ?? true,
      creatorId: map['creatorId'],
      tags: List<String>.from(map['tags'] ?? []),
      maxParticipants: map['maxParticipants'],
    );
  }
}
