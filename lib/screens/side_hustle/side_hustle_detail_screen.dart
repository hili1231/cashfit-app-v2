import '../../data/user_data.dart';
import '../../screens/side_hustle/side_hustle_progress_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/side_hustle.dart';
import '../nav_screen.dart';
import 'side_hustle_screen.dart';
import '../../theme.dart';
import '../upgrade_to_premium_screen.dart';
import '../../auth/login_screen.dart';

class SideHustleDetailScreen extends StatefulWidget {
  final SideHustle hustle;

  const SideHustleDetailScreen({super.key, required this.hustle});

  @override
  State<SideHustleDetailScreen> createState() => _SideHustleDetailScreenState();
}

class _SideHustleDetailScreenState extends State<SideHustleDetailScreen> {
  bool isJoining = false;
  bool hasJoined = false;

  @override
  void initState() {
    super.initState();

    final userId = currentUser?.id ?? "";
    hasJoined =
        widget.hustle.participants.contains(userId) ||
        currentUser?.joinedSideHustles.contains(widget.hustle.id) == true;
  }

  Future<void> _joinHustle() async {
    // If user not premium => upgrade
    final isPremium = currentUser?.isPremium ?? false;
    if (!isPremium) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeToPremierScreen()),
        );
      }
      return;
    }

    setState(() => isJoining = true);
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      // 1) Update user doc
      if (!currentUser!.joinedSideHustles.contains(widget.hustle.id)) {
        currentUser!.joinedSideHustles.add(widget.hustle.id);
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'joinedSideHustles': currentUser!.joinedSideHustles},
        );
      }

      // 2) Update hustle doc
      final hustleRef = FirebaseFirestore.instance
          .collection('sideHustles')
          .doc(widget.hustle.id);

      final updatedParticipants = List<String>.from(widget.hustle.participants);
      if (!updatedParticipants.contains(userId)) {
        updatedParticipants.add(userId);
      }

      await hustleRef.update({'participants': updatedParticipants});

      // 3) Update local
      widget.hustle.participants.add(userId);
      setState(() {
        hasJoined = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Joined Side Hustle successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Join failed: $e")));
      }
    }

    setState(() => isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    // 1) Check if user is logged in
    final user = firebaseUser;
    if (user == null) {
      // Not logged in => show login
      return const _NotLoggedInView();
    }

    // 2) If user is not premium => show upgrade
    final isPremium = currentUser?.isPremium ?? false;
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.hustle.title),
          backgroundColor: Colors.black,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UpgradeToPremierScreen(),
                  ),
                );
              },
              child: const Text("Upgrade to Premium to Join Side Hustle"),
            ),
          ),
        ),
      );
    }

    // Otherwise => show detail
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        widget.hustle.thumbnail,
                        width: double.infinity,
                        height: 220,
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
                            widget.hustle.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            widget.hustle.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Prize
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Prize: \$${widget.hustle.reward}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Video Requirement
                          const Text(
                            "Video Requirement:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.hustle.videoRequirement,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Participants
                          Text(
                            "${widget.hustle.participants.length} participants have joined",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Join or View Progress
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 3,
                              ),
                              onPressed:
                                  isJoining
                                      ? null
                                      : () {
                                        if (hasJoined) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      SideHustleProgressScreen(
                                                        hustle: widget.hustle,
                                                      ),
                                            ),
                                          );
                                        } else {
                                          _joinHustle();
                                        }
                                      },
                              icon:
                                  isJoining
                                      ? const SizedBox.shrink()
                                      : const Icon(
                                        Icons.videocam,
                                        color: Colors.black,
                                      ),
                              label:
                                  isJoining
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        hasJoined
                                            ? "View Progress"
                                            : "Join Side Hustle",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                    navState.setDetailScreen(const SideHustleScreen());
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 50, color: Colors.white70),
    );
  }
}

/// If user not logged in => show a small screen to login
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
          child: const Text("Login to view Side Hustle"),
        ),
      ),
    );
  }
}
