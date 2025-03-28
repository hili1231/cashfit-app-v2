import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/challenge.dart';
import '../../theme.dart';

class ChallengeSignUpScreen extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId; // The ID of the current user

  const ChallengeSignUpScreen({
    super.key,
    required this.challenge,
    required this.currentUserId,
  });

  @override
  ChallengeSignUpScreenState createState() => ChallengeSignUpScreenState();
}

class ChallengeSignUpScreenState extends State<ChallengeSignUpScreen> {
  bool isSigningUp = false;

  Future<void> signUp() async {
    setState(() {
      isSigningUp = true;
    });
    try {
      // Get a reference to the challenge document
      final challengeRef = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      // Create a copy of the progressVideos map (which holds sign-ups)
      Map<String, dynamic> updatedProgressVideos = Map<String, dynamic>.from(
        widget.challenge.progressVideos,
      );

      // If the user is not already signed up, add them with an empty list of videos.
      if (!updatedProgressVideos.containsKey(widget.currentUserId)) {
        updatedProgressVideos[widget.currentUserId] = [];
      }

      // Update Firestore with the new sign-up
      await challengeRef.update({'progressVideos': updatedProgressVideos});

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Signed up successfully!")));

      // Optionally navigate to the progress screen immediately
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Sign up failed: $e")));
    }
    setState(() {
      isSigningUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up for ${widget.challenge.name}"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.challenge.description, style: AppTheme.smallText),
            const SizedBox(height: 20),
            ElevatedButton(
              style: AppTheme.buttonStyle,
              onPressed: isSigningUp ? null : signUp,
              child:
                  isSigningUp
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up for Challenge"),
            ),
          ],
        ),
      ),
    );
  }
}
