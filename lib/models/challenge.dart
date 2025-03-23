class Challenge {
  final String id;
  final String name;
  final String description;
  final int participants;
  final List<String> progressVideos;
  final List<String> instructions;
  final String image; // ✅ Added image field

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.progressVideos,
    required this.instructions,
    required this.image, // ✅ Make sure image is required
  });
}
