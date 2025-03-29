import '../../screens/challenges/challenges_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/challenge.dart';
import '../../theme.dart';
import '../../data/user_data.dart';
import '../nav_screen.dart';
import 'challenge_progress_screen.dart';
import '../upgrade_to_premium_screen.dart';
import '../../auth/login_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  ChallengeDetailScreenState createState() => ChallengeDetailScreenState();
}

class ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool isSigningUp = false;
  bool isSignedUp = false;

  @override
  void initState() {
    super.initState();

    final String currentUserId = currentUser?.id ?? "";
    isSignedUp =
        widget.challenge.progressVideos.containsKey(currentUserId) ||
        widget.challenge.participants.contains(currentUserId);
  }

  Future<void> _signUp() async {
    // Double-check user is premium
    final bool isPremium = currentUser?.isPremium ?? false;
    if (!isPremium) {
      // If user isn't premium, go to upgrade
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeToPremierScreen()),
        );
      }
      return;
    }

    setState(() => isSigningUp = true);
    final String currentUserId = currentUser?.id ?? "";

    try {
      // 1) Update challenge doc
      final challengeRef = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      final updatedProgressVideos = Map<String, dynamic>.from(
        widget.challenge.progressVideos,
      );
      if (!updatedProgressVideos.containsKey(currentUserId)) {
        updatedProgressVideos[currentUserId] = [];
      }

      final updatedParticipants = List<String>.from(
        widget.challenge.participants,
      );
      if (!updatedParticipants.contains(currentUserId)) {
        updatedParticipants.add(currentUserId);
      }

      await challengeRef.update({
        'progressVideos': updatedProgressVideos,
        'participants': updatedParticipants,
      });

      // 2) Add challenge.id to user doc
      if (!currentUser!.joinedChallenges.contains(widget.challenge.id)) {
        currentUser!.joinedChallenges.add(widget.challenge.id);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'joinedChallenges': currentUser!.joinedChallenges});
      }

      // 3) Update local model
      widget.challenge.progressVideos[currentUserId] ??= [];
      widget.challenge.participants.add(currentUserId);

      setState(() {
        isSignedUp = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signed up successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Sign up failed: $e")));
      }
    }

    setState(() => isSigningUp = false);
  }

  @override
  Widget build(BuildContext context) {
    // 1) Check if user is logged in at all
    final user = firebaseUser;
    if (user == null) {
      // Not logged in => show or navigate to Login
      return const _NotLoggedInView();
    }

    // 2) Now check premium
    final bool isPremium = currentUser?.isPremium ?? false;
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.challenge.name),
          backgroundColor: Colors.black,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Center(
            child: ElevatedButton(
              style: AppTheme.buttonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UpgradeToPremierScreen(),
                  ),
                );
              },
              child: const Text("Upgrade to Premium to Join Challenge"),
            ),
          ),
        ),
      );
    }

    // If user is logged in AND premium => show detail
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.challenge.name),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
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
                        widget.challenge.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.challenge.name,
                    style: AppTheme.headline.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.challenge.description, style: AppTheme.smallText),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white70, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.challenge.participants.length} Participants",
                        style: AppTheme.goldText.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Instructions"),
                  const SizedBox(height: 8),
                  ...widget.challenge.instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text("• $step", style: AppTheme.smallText),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppTheme.buttonStyle,
                      onPressed:
                          isSigningUp
                              ? null
                              : () {
                                if (isSignedUp) {
                                  // View progress
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChallengeProgressScreen(
                                            challenge: widget.challenge,
                                            currentUserId:
                                                currentUser?.id ?? "",
                                          ),
                                    ),
                                  );
                                } else {
                                  _signUp();
                                }
                              },
                      child:
                          isSigningUp
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(isSignedUp ? "View Progress" : "Sign Up"),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: AppTheme.cardDecoration,
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, size: 60, color: Colors.amber),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.headline.copyWith(fontSize: 18));
  }
}

/// A simple widget to show a login screen if user is not logged in
/// You can do a direct `Navigator.pushReplacement` to login if you prefer
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text("Login to view Challenge"),
        ),
      ),
    );
  }
}
