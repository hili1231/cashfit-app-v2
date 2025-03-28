import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';
import '../models/progress_video.dart';

final List<Challenge> challengeData = [
  Challenge(
    id: "1",
    name: "30-Day Fitness Challenge",
    description:
        "A full-body challenge for 30 days to improve endurance and strength.",
    participants: 150,
    progressVideos: {
      "user1": [
        ProgressVideo(
          url: "assets/videos/progress1.mp4",
          uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ProgressVideo(
          url: "assets/videos/progress2.mp4",
          uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    },
    instructions: [
      "Day 1: 10 push-ups, 20 squats, 30-second plank.",
      "Day 2: 15 push-ups, 25 squats, 40-second plank.",
      "Day 3: 20 push-ups, 30 squats, 50-second plank.",
      "Continue increasing reps each day!",
    ],
    image: "assets/images/dance_challenge.jpg",
    prizeAmount: 100,
  ),
  Challenge(
    id: "2",
    name: "Yoga Flexibility Challenge",
    description:
        "Improve flexibility and relaxation with this 21-day yoga program.",
    participants: 95,
    progressVideos: {
      "user2": [
        ProgressVideo(
          url: "assets/videos/yoga1.mp4",
          uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ProgressVideo(
          url: "assets/videos/yoga2.mp4",
          uploadedAt: DateTime.now(),
        ),
      ],
    },
    instructions: [
      "Day 1: 5-minute full-body stretch.",
      "Day 2: 10-minute sun salutation.",
      "Day 3: 15-minute deep breathing & relaxation.",
      "Increase duration daily to improve flexibility!",
    ],
    image: "assets/images/dance_challenge.jpg",
    prizeAmount: 100,
  ),
];

Future<List<Challenge>> fetchChallengeData() async {
  try {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('challenges').get();

    List<Challenge> challenges =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Ensure progressVideos is parsed correctly
          final progressVideosRaw = Map<String, dynamic>.from(
            data['progressVideos'] ?? {},
          );
          final parsedProgressVideos = progressVideosRaw.map((userId, videos) {
            final List<dynamic> videoList = videos ?? [];
            return MapEntry(
              userId,
              videoList.map((video) {
                final videoMap = Map<String, dynamic>.from(video);
                return {
                  'url': videoMap['url'] ?? '',
                  'uploadedAt':
                      DateTime.tryParse(videoMap['uploadedAt'] ?? '') ??
                      DateTime.now(),
                };
              }).toList(),
            );
          });

          return Challenge.fromMap({
            ...data,
            'progressVideos': parsedProgressVideos,
          });
        }).toList();

    return challenges.isEmpty ? challengeData : challenges;
  } catch (e) {
    return challengeData;
  }
}
