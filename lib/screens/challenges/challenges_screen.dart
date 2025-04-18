import 'package:cashfit/screens/personalize/workout_diet_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/challenge.dart';
import '../../services/challenge_calculator.dart';
import '../../ad_helper.dart';
import '../../auth/login_screen.dart';
import '../nav_screen.dart';
import '../../providers/user_provider.dart';
import 'challenge_sign_up_screen.dart';
import 'challenge_progress_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ChallengesScreenState createState() => ChallengesScreenState();
}

class ChallengesScreenState extends State<ChallengesScreen> {
  bool isLoading = true;
  Challenge? userChallenge;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    setState(() {
      isLoading = true;
    });

    // Check if the user is logged in
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Guard context usage
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const LoginScreen());
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
      return;
    }

    // Load the user
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData(firebaseUser.uid);
    final AppUser? user = userProvider.currentUser;

    if (user == null) {
      if (!mounted) return; // Guard context usage
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Check if the user has completed the workout and diet builder
    if (user.activeWorkoutPrograms.isEmpty || user.activeDietPlans.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Guard context usage
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const WorkoutDietBuilderScreen());
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutDietBuilderScreen()),
          );
        }
      });
      return;
    }

    // Check if the user has an active challenge
    if (user.joinedChallenges.isNotEmpty) {
      final challengeId = user.joinedChallenges.last;
      final challengeDoc =
          await FirebaseFirestore.instance
              .collection('challenges')
              .doc(challengeId)
              .get();
      if (challengeDoc.exists) {
        if (!mounted) return; // Guard context usage
        setState(() {
          userChallenge = Challenge.fromMap(challengeDoc.data()!);
          isLoading = false;
        });
        return;
      }
    }

    // Generate a new challenge for the user
    final newChallenge = ChallengeCalculator.calculateChallenge(user);
    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(newChallenge.id)
        .set(newChallenge.toMap());

    if (!mounted) return; // Guard context usage
    setState(() {
      userChallenge = newChallenge;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final AppUser? user = userProvider.currentUser;

    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (userChallenge == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Challenges",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 2,
        ),
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            "Unable to load challenge. Please try again.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final bool isSignedUp = userChallenge!.participants.contains(user?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Challenges",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSignedUp) ...[
              Text(
                userChallenge!.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Progress: ${user?.challengeProgress ?? 0}%",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              LinearProgressIndicator(
                value: (user?.challengeProgress ?? 0) / 100,
                backgroundColor: colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
                onPressed: () {
                  if (user == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChallengeProgressScreen(
                            challenge: userChallenge!,
                            currentUserId: user.id,
                          ),
                    ),
                  );
                },
                child: Text(
                  "View Progress",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ] else ...[
              Text(
                userChallenge!.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                userChallenge!.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Requirements:",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "• Daily check-ins",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "• Weekly photo updates of your weight",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Prizes:",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "• ${userChallenge!.rewardPremiumMonths} months of Premium Membership",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "• ${userChallenge!.rewardCoins} Coins",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
                onPressed: () {
                  if (user == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChallengeSignUpScreen(
                            challenge: userChallenge!,
                            currentUserId: user.id,
                          ),
                    ),
                  );
                },
                child: Text(
                  "Sign Up for Challenge",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            AdHelper.nativeAdWidget(context),
          ],
        ),
      ),
      bottomNavigationBar: AdHelper.bannerAdWidget(context),
    );
  }
}
