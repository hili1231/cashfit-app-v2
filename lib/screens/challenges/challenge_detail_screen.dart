import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/challenge.dart';
import '../../auth/login_screen.dart';
import '../nav_screen.dart';
import 'challenge_progress_screen.dart';
import '../../providers/user_provider.dart';
import '../../ad_helper.dart';

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
        if (!mounted) return; // Guard context usage
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (user != null && userProvider.currentUser == null) {
      await userProvider.loadUserData(user.uid);
    }

    final String currentUserId = userProvider.currentUser?.id ?? "";
    if (!mounted) return; // Guard context usage
    setState(() {
      isSignedUp = widget.challenge.participants.contains(currentUserId);
      isLoading = false;
    });
  }

  Future<void> _signUp() async {
    setState(() => isSigningUp = true);

    // Store UserProvider and ScaffoldMessenger before async operation
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String currentUserId = userProvider.currentUser?.id ?? "";

    try {
      final challengeRef = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      final updatedParticipants = List<String>.from(
        widget.challenge.participants,
      );
      if (!updatedParticipants.contains(currentUserId)) {
        updatedParticipants.add(currentUserId);
      }

      await challengeRef.update({'participants': updatedParticipants});

      if (!userProvider.currentUser!.joinedChallenges.contains(
        widget.challenge.id,
      )) {
        userProvider.currentUser!.joinedChallenges.add(widget.challenge.id);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
              'joinedChallenges': userProvider.currentUser!.joinedChallenges,
            });
      }

      widget.challenge.participants.add(currentUserId);

      if (!mounted) return; // Guard context usage
      setState(() {
        isSignedUp = true;
      });

      AdHelper.showInterstitialAd(context); // Show ad after sign-up for non-premium users

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("Signed up successfully!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return; // Guard context usage
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Sign up failed: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (!mounted) return; // Guard context usage
    setState(() => isSigningUp = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading || FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.challenge.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      body: Stack(
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
                        color: colorScheme.primary.withAlpha(30),
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
                      errorBuilder:
                          (_, __, ___) => _buildPlaceholderImage(colorScheme),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.challenge.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.challenge.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${widget.challenge.participants.length} Participants",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Instructions", theme, colorScheme),
                const SizedBox(height: 8),
                ...widget.challenge.instructions.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "• $step",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Prizes", theme, colorScheme),
                const SizedBox(height: 8),
                Text(
                  "• ${widget.challenge.rewardPremiumMonths} months of Premium Membership",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "• ${widget.challenge.rewardCoins} Coins",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        colorScheme.onPrimary,
                      ),
                    ),
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
                                              Provider.of<UserProvider>(
                                                context,
                                                listen: false,
                                              ).currentUser?.id ??
                                              "",
                                        ),
                                  ),
                                );
                              } else {
                                _signUp();
                              }
                            },
                    child:
                        isSigningUp
                            ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                            : Text(
                              isSignedUp ? "View Progress" : "Sign Up",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                AdHelper.nativeAdWidget(context),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdHelper.bannerAdWidget(context),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Icon(Icons.fitness_center, size: 60, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 18,
      ),
    );
  }
}
