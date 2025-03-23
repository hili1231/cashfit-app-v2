import 'package:flutter/material.dart';
import '../data/challenge_data.dart';
import '../models/challenge.dart';
import 'nav_screen.dart';
import 'challenge_detail_screen.dart';
import '../theme.dart'; // ✅ Import global theme

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header Title (white70)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "CHALLENGES",
                    style: AppTheme.headline.copyWith(
                      fontSize: 24,
                      color: Colors.white70, // ✅ Updated to white70
                    ),
                  ),
                ),
              ),

              // 🔹 Challenge List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: challengeData.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeData[index];
                    return _buildChallengeCard(context, challenge);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Builds a Challenge Card
  Widget _buildChallengeCard(BuildContext context, Challenge challenge) {
    return GestureDetector(
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        navState?.setDetailScreen(ChallengeDetailScreen(challenge: challenge));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Challenge Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                challenge.image,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📌 Title in white70
                  Text(
                    challenge.name,
                    style: AppTheme.headline.copyWith(
                      fontSize: 18,
                      color: Colors.white70, // ✅ Updated to white70
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 📜 Description (unchanged)
                  Text(
                    challenge.description,
                    style: AppTheme.smallText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 👥 Participants & Arrow
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${challenge.participants} Participants",
                        style: AppTheme.goldText,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Placeholder Image for Challenges
  Widget _buildPlaceholderImage() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, size: 50, color: Colors.amber),
    );
  }
}
