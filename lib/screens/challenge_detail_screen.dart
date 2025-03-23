import 'package:flutter/material.dart';
import '../models/challenge.dart';
import 'nav_screen.dart';
import 'challenges_screen.dart';
import '../theme.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // ✅ Main scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50), // Push content below back button
                  // 🔹 Challenge Image
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withAlpha(30),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        challenge.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Challenge Title
                  Text(
                    challenge.name,
                    style: AppTheme.headline.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Challenge Description
                  Text(challenge.description, style: AppTheme.smallText),
                  const SizedBox(height: 20),

                  // 🔹 Participants
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white70, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${challenge.participants} Participants",
                        style: AppTheme.goldText.copyWith(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Instructions
                  _buildSectionTitle("Instructions"),
                  const SizedBox(height: 8),
                  ...challenge.instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text("• $step", style: AppTheme.smallText),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Progress Videos
                  _buildSectionTitle("Progress Videos"),
                  const SizedBox(height: 8),
                  ...challenge.progressVideos.map(
                    (videoPath) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 120,
                        decoration: AppTheme.cardDecoration,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle,
                              color: Colors.amber,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Video: ${videoPath.split('/').last}",
                              style: AppTheme.smallText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Start Challenge Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppTheme.buttonStyle,
                      onPressed: () {
                        // TODO: Implement start challenge
                      },
                      child: const Text("Start Challenge"),
                    ),
                  ),
                ],
              ),
            ),

            // 🔙 Floating Back Button
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    final navState =
                        context.findAncestorStateOfType<NavScreenState>();
                    if (navState != null) {
                      navState.setDetailScreen(const ChallengesScreen());
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder if image is missing
  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: AppTheme.cardDecoration,
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, size: 60, color: Colors.amber),
    );
  }

  /// Section title style
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.headline.copyWith(fontSize: 18));
  }
}
