import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/challenge.dart';
import '../../ad_helper.dart';

class ChallengeSignUpScreen extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId;

  const ChallengeSignUpScreen({
    super.key,
    required this.challenge,
    required this.currentUserId,
  });

  @override
  ChallengeSignUpScreenState createState() => ChallengeSignUpScreenState();
}

class ChallengeSignUpScreenState extends State<ChallengeSignUpScreen> {
  final AuthService _authService = AuthService();
  bool isSigningUp = false;

  Future<void> signUp() async {
    setState(() {
      isSigningUp = true;
    });

    // Store Navigator and ScaffoldMessenger before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _authService.signUpForChallenge(
        widget.currentUserId,
        widget.challenge,
      );
      AdHelper.showInterstitialAd(
        // ignore: use_build_context_synchronously
        context,
      ); // Show ad after sign-up for non-premium users
      if (!mounted) return; // Guard context usage
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Signed up successfully!"),
          backgroundColor:
              Colors.green, // Use Material 3 color in implementation
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return; // Guard context usage
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Sign up failed: $e"),
          backgroundColor: Colors.red, // Use Material 3 color in implementation
        ),
      );
    } finally {
      if (!mounted) {
        // ignore: control_flow_in_finally
        return; // Guard context usage
      }
      setState(() {
        isSigningUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sign Up for ${widget.challenge.name}",
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
            Text(
              widget.challenge.description,
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
            const SizedBox(height: 20),
            ElevatedButton(
              style: theme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
              ),
              onPressed: isSigningUp ? null : signUp,
              child:
                  isSigningUp
                      ? CircularProgressIndicator(color: colorScheme.onPrimary)
                      : Text(
                        "Sign Up for Challenge",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
            ),
            const SizedBox(height: 20),
            AdHelper.nativeAdWidget(context),
          ],
        ),
      ),
      bottomNavigationBar: AdHelper.bannerAdWidget(context),
    );
  }
}
