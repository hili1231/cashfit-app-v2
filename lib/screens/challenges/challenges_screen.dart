import 'package:cashfit/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/challenge.dart';
import '../../theme.dart';
import '../../data/user_data.dart'; // Provides currentUser
import '../nav_screen.dart';
import 'challenge_detail_screen.dart';
import '../upgrade_to_premium_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  /// Fetch challenges from Firestore
  Future<List<Challenge>> fetchChallenges() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('challenges').get();

    // Map each document to a Challenge instance.
    List<Challenge> challenges =
        snapshot.docs.map((doc) {
          return Challenge.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();

    // Optionally, you can fallback to hardcoded data if no challenges are found.
    if (challenges.isEmpty) {
      // import your hardcoded list from challenge_data.dart if needed.
      // return challengeData;
    }
    return challenges;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = currentUser?.isPremium ?? false;
    final String currentUserId = currentUser?.id ?? "";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "CHALLENGES",
                    style: AppTheme.headline.copyWith(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              // Challenge List using FutureBuilder
              Expanded(
                child: FutureBuilder<List<Challenge>>(
                  future: fetchChallenges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No challenges found"));
                    }
                    final challenges = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: challenges.length,
                      itemBuilder: (context, index) {
                        final challenge = challenges[index];
                        return _buildChallengeCard(
                          context,
                          challenge,
                          isPremium,
                          currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Challenge challenge,
    bool isPremium,
    String currentUserId,
  ) {
    return GestureDetector(
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();

        if (firebaseUser == null) {
          // Not logged in
          navState?.setDetailScreen(const LoginScreen());
        } else if (currentUser?.isPremium == true) {
          // Logged in + premium
          navState?.setDetailScreen(
            ChallengeDetailScreen(challenge: challenge),
          );
        } else {
          // Logged in but NOT premium
          navState?.setDetailScreen(const UpgradeToPremierScreen());
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child:
                  (challenge.image.startsWith("http"))
                      ? Image.network(
                        challenge.image,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                      : Image.asset(
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
                  // Title
                  Text(
                    challenge.name,
                    style: AppTheme.headline.copyWith(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    challenge.description,
                    style: AppTheme.smallText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Prize Amount
                  Text(
                    "Prize: \$${challenge.prizeAmount.toStringAsFixed(2)}",
                    style: AppTheme.smallText.copyWith(
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Participants
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
