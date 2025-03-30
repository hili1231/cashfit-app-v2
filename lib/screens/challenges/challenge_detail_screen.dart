import '../../screens/challenges/challenges_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isLoading = true;
  User? firebaseUser;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadUser();
  }

  Future<void> _checkLoginAndLoadUser() async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const LoginScreen());
        }
      });
      return;
    }

    await _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    final user = firebaseUser;

    if (user != null &&
        (currentUser == null || currentUser?.id.isEmpty == true)) {
      await loadUserFromFirestore(user.uid);
    }

    final String currentUserId = currentUser?.id ?? "";
    setState(() {
      isSignedUp =
          widget.challenge.progressVideos.containsKey(currentUserId) ||
          widget.challenge.participants.contains(currentUserId);
      isLoading = false;
    });
  }

  Future<void> _signUp() async {
    final bool isPremium = currentUser?.isPremium ?? false;
    if (!isPremium) {
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
      final challengeRef = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      final updatedProgressVideos = Map<String, dynamic>.from(
        widget.challenge.progressVideos,
      );
      updatedProgressVideos.putIfAbsent(currentUserId, () => []);

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

      if (!currentUser!.joinedChallenges.contains(widget.challenge.id)) {
        currentUser!.joinedChallenges.add(widget.challenge.id);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'joinedChallenges': currentUser!.joinedChallenges});
      }

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
    if (isLoading || FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

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
