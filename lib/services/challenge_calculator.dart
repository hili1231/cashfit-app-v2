import 'package:cashfit/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/challenge.dart';
import '../../providers/user_provider.dart';

class ChallengeCalculator {
  // Configurable constants
  static const int defaultDurationDays = 90; // 3 months
  static const double weightLossTargetKg = 5.0; // Default weight loss target
  static const double muscleGainTargetKg = 1.0; // Default muscle gain target
  static const int rewardCoins = 500;
  static const int rewardPremiumMonths = 3;
  static const String defaultImage = 'assets/images/challenge_placeholder.jpg';

  /// Generate a personalized challenge for the user and save it to Firestore.
  static Future<Challenge> generateChallenge({
    required BuildContext context,
    int durationDays = defaultDurationDays,
    double weightLossTarget = weightLossTargetKg,
    double muscleGainTarget = muscleGainTargetKg,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception("User not found. Please ensure you are logged in.");
      }

      // Validate user data
      final double currentWeight = double.tryParse(user.weight) ?? 0.0;
      double height = double.tryParse(user.height) ?? 0.0;
      if (currentWeight <= 0 || height <= 0) {
        throw Exception(
          "Invalid user data: weight and height must be positive numbers.",
        );
      }

      // Convert height units if necessary (similar to DietGenerator)
      if (user.height.contains("in")) height *= 2.54; // Convert inches to cm

      // Calculate BMI to determine if the user needs to lose weight
      final double bmi = currentWeight / ((height / 100) * (height / 100));
      final bool needsWeightLoss = bmi > 25;

      final DateTime startDate = DateTime.now();
      final DateTime endDate = startDate.add(Duration(days: durationDays));
      final String challengeId = const Uuid().v4();

      String challengeType;
      String challengeName;
      String challengeDescription;
      double targetWeight;

      // Align goal strings with AppUser model
      if (user.dietGoal == "Lose Fat" ||
          (needsWeightLoss && user.workoutGoal == "Lose Fat")) {
        challengeType = 'weight_loss';
        challengeName =
            'Lose ${weightLossTarget}kg in ${durationDays ~/ 30} Months';
        challengeDescription =
            'Lose ${weightLossTarget}kg over the next ${durationDays ~/ 30} months by following a healthy diet and exercise plan.';
        targetWeight = currentWeight - weightLossTarget;
      } else if (user.dietGoal == "Build Muscle" ||
          user.workoutGoal == "Build Muscle") {
        challengeType = 'muscle_gain';
        challengeName = 'Gain Muscle in ${durationDays ~/ 30} Months';
        challengeDescription =
            'Increase muscle mass over the next ${durationDays ~/ 30} months with a strength training program.';
        targetWeight = currentWeight + muscleGainTarget;
      } else {
        challengeType = 'weight_maintenance';
        challengeName = 'Maintain Weight in ${durationDays ~/ 30} Months';
        challengeDescription =
            'Maintain your current weight over the next ${durationDays ~/ 30} months while improving fitness.';
        targetWeight = currentWeight;
      }

      // Adjust target weight based on activity level
      if (user.activityLevel == 'Sedentary') {
        targetWeight *= 0.98;
      } else if (user.activityLevel == 'Very Active') {
        targetWeight *= 1.02;
      }

      final challenge = Challenge(
        id: challengeId,
        type: challengeType,
        name: challengeName,
        description: challengeDescription,
        image: defaultImage,
        instructions: [
          'Check in daily to track your progress.',
          'Submit a weekly photo update of your weight on the scale.',
          'Follow your diet and workout plan to achieve your goal.',
        ],
        participants: [],
        initialWeight: currentWeight,
        targetWeight: targetWeight,
        startDate: startDate,
        endDate: endDate,
        durationDays: durationDays,
        rewardCoins: rewardCoins,
        rewardPremiumMonths: rewardPremiumMonths,
      );

      // Save the challenge to Firestore
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .set(challenge.toMap());

      // Update user's joined challenges and active challenge
      List<String> updatedJoinedChallenges = [
        ...user.joinedChallenges,
        challengeId,
      ];
      await userProvider.updateUserFields({
        'joinedChallenges': updatedJoinedChallenges,
        'activeChallengeId': challengeId,
      });

      return challenge;
    } catch (e) {
      throw Exception("Failed to generate challenge: $e");
    }
  }

  /// Calculate the user's progress in the challenge.
  static int calculateProgress(Challenge challenge, double currentWeight) {
    if (currentWeight <= 0) {
      throw Exception("Invalid current weight: must be a positive number.");
    }

    if (challenge.type == 'weight_maintenance') {
      // For maintenance, progress is 100% if within 1kg of target weight
      return (currentWeight >= challenge.targetWeight - 1 &&
              currentWeight <= challenge.targetWeight + 1)
          ? 100
          : 0;
    } else if (challenge.type == 'muscle_gain') {
      // For muscle gain, progress can be based on weight gain or other metrics
      // Here, we'll use weight gain, but this could be expanded (e.g., strength gains)
      final double weightChange = currentWeight - challenge.initialWeight;
      final double targetChange =
          challenge.targetWeight - challenge.initialWeight;
      if (targetChange == 0) return 0;
      final double progress = (weightChange / targetChange) * 100;
      return progress.clamp(0, 100).toInt();
    } else {
      // For weight loss, progress is based on weight loss
      final double weightChange = challenge.initialWeight - currentWeight;
      final double targetChange =
          challenge.initialWeight - challenge.targetWeight;
      if (targetChange == 0) return 0;
      final double progress = (weightChange / targetChange) * 100;
      return progress.clamp(0, 100).toInt();
    }
  }

  static calculateChallenge(AppUser user) {}
}
