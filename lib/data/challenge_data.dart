import '../models/challenge.dart';

final List<Challenge> challengeData = [
  Challenge(
    id: "1",
    name: "30-Day Fitness Challenge",
    description:
        "A full-body challenge for 30 days to improve endurance and strength.",
    participants: 150,
    progressVideos: [
      "assets/videos/progress1.mp4",
      "assets/videos/progress2.mp4",
    ],
    instructions: [
      "Day 1: 10 push-ups, 20 squats, 30-second plank.",
      "Day 2: 15 push-ups, 25 squats, 40-second plank.",
      "Day 3: 20 push-ups, 30 squats, 50-second plank.",
      "Continue increasing reps each day!",
    ],
    image: "assets/images/dance_challenge.jpg",
  ),
  Challenge(
    id: "2",
    name: "Yoga Flexibility Challenge",
    description:
        "Improve flexibility and relaxation with this 21-day yoga program.",
    participants: 95,
    progressVideos: ["assets/videos/yoga1.mp4", "assets/videos/yoga2.mp4"],
    instructions: [
      "Day 1: 5-minute full-body stretch.",
      "Day 2: 10-minute sun salutation.",
      "Day 3: 15-minute deep breathing & relaxation.",
      "Increase duration daily to improve flexibility!",
    ],
    image: "assets/images/dance_challenge.jpg",
  ),
];
