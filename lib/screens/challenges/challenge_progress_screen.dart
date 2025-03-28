import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/challenge.dart';
import '../../theme.dart';

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId; // The ID of the current user

  const ChallengeProgressScreen({
    super.key,
    required this.challenge,
    required this.currentUserId,
  });

  @override
  ChallengeProgressScreenState createState() => ChallengeProgressScreenState();
}

class ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  final videoUrlController = TextEditingController();
  bool isUpdating = false;
  List<String> progressVideos = [];

  @override
  void initState() {
    super.initState();
    // Initialize with the current user's progress videos from the challenge.
    progressVideos = List<String>.from(
      widget.challenge.progressVideos[widget.currentUserId] ?? [],
    );
  }

  Future<void> uploadVideo() async {
    if (videoUrlController.text.isEmpty) return;

    setState(() {
      isUpdating = true;
    });

    try {
      String newVideoUrl = videoUrlController.text.trim();
      progressVideos.add(newVideoUrl);

      // Get a reference to the challenge document.
      final challengeRef = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      // Create a copy of the progressVideos map and update the current user's list.
      Map<String, dynamic> updatedProgressVideos = Map<String, dynamic>.from(
        widget.challenge.progressVideos,
      );
      updatedProgressVideos[widget.currentUserId] = progressVideos;

      await challengeRef.update({'progressVideos': updatedProgressVideos});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video uploaded successfully!")),
      );

      videoUrlController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to upload video: $e")));
    }
    setState(() {
      isUpdating = false;
    });
  }

  @override
  void dispose() {
    videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Challenge Progress"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.challenge.name,
              style: AppTheme.headline.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              "Upload your progress videos below:",
              style: AppTheme.smallText,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: videoUrlController,
              decoration: InputDecoration(
                labelText: "Video URL",
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: AppTheme.buttonStyle,
              onPressed: isUpdating ? null : uploadVideo,
              child:
                  isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Upload Video"),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Uploaded Videos:",
              style: AppTheme.headline.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  progressVideos.isEmpty
                      ? Center(
                        child: Text(
                          "No videos uploaded yet.",
                          style: AppTheme.smallText,
                        ),
                      )
                      : ListView.builder(
                        itemCount: progressVideos.length,
                        itemBuilder: (context, index) {
                          final videoUrl = progressVideos[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.amber,
                            ),
                            title: Text(videoUrl, style: AppTheme.smallText),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
