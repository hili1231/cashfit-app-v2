import '../models/side_hustle.dart';

final List<SideHustle> sideHustleData = [
  SideHustle(
    id: "1",
    title: "Street Dance Challenge",
    description: "Perform a freestyle street dance & record a video!",
    reward: 50, // $50 Prize
    videoRequirement: "Dance to the provided beat & upload a video.",
    thumbnail: "assets/images/dance_challenge.jpg",
  ),
  SideHustle(
    id: "2",
    title: "Fitness Endurance Test",
    description: "Hold a plank position for 3 minutes while recording!",
    reward: 100, // $100 Prize
    videoRequirement: "Record yourself maintaining a plank for 3 minutes.",
    thumbnail: "assets/images/plank_challenge.jpg",
  ),
];
