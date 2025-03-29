import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';

/// Updated local sample challenge data
/// - No local `progressVideos` anymore
/// - `participants`: an empty list of user IDs
/// - `maxParticipants`: numeric limit
final List<Challenge> challengeData = [
  Challenge(
    id: "30_day_fitness_challenge_29032025",
    name: "30-Day Fitness Challenge",
    description:
        "A full-body challenge for 30 days to improve endurance and strength.",
    participants: [],
    maxParticipants: 150,
    instructions: [
      "Day 1: 10 push-ups, 20 squats, 30-second plank.",
      "Day 2: 15 push-ups, 25 squats, 40-second plank.",
      "Day 3: 20 push-ups, 30 squats, 50-second plank.",
      "Continue increasing reps each day!",
    ],
    image: "assets/images/dance_challenge.jpg",
    prizeAmount: 100,
    // We'll omit `progressVideos` from this local sample:
    // progressVideos: {},
  ),
];

/// Fetch challenges from Firestore, or fall back to [challengeData] if none are found.
Future<List<Challenge>> fetchChallengeData() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('challenges').get();

    // Parse each doc into a Challenge
    final challenges =
        snapshot.docs.map((doc) {
          final data = doc.data();

          // If you need to parse progressVideos from Firestore, you can do so here:
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

          // Merge the parsed progress videos back into the data
          return Challenge.fromMap({
            ...data,
            'progressVideos': parsedProgressVideos,
          });
        }).toList();

    // If Firestore is empty, use the local fallback sample data
    return challenges.isEmpty ? challengeData : challenges;
  } catch (e) {
    // On error, fall back to local sample data
    return challengeData;
  }
}
