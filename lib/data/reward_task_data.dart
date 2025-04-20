import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reward_task.dart';

Future<void> uploadTasksToFirebase() async {
  final tasks = [
    RewardTask(
      id: 'daily_check_in',
      title: 'Daily Check-In',
      description: 'Check in daily to earn escalating FitCoins.',
      points: 0, // Points determined by streak
      type: RewardType.dailyCheckIn,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Check In',
    ),
    RewardTask(
      id: 'complete_workout',
      title: 'Complete a Workout',
      description: 'Finish a workout to earn FitCoins.',
      points: 20,
      type: RewardType.daily,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText:
          'Complete Workout', // Initial action to navigate to workout screen
    ),
    RewardTask(
      id: 'complete_meal_plan',
      title: 'Complete Daily Meal Plan',
      description: 'Complete your daily meals to earn FitCoins.',
      points: 15,
      type: RewardType.daily,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText:
          'Complete Meal Day', // Initial action to navigate to meal logging screen
    ),
    RewardTask(
      id: 'daily_step_goal',
      title: 'Daily Step Goal',
      description: 'Meet your daily step target to earn FitCoins.',
      points: 10,
      type: RewardType.daily,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Check Steps', // Initial action to check step progress
    ),
    RewardTask(
      id: 'update_weight',
      title: 'Update Your Weight',
      description: 'Update your weight weekly to earn FitCoins.',
      points: 10,
      type: RewardType.weekly,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Update Weight', // Initial action to navigate to profile
    ),
    RewardTask(
      id: 'build_profile',
      title: 'Build Profile',
      description: 'Complete your profile to earn FitCoins.',
      points: 15,
      type: RewardType.oneOff,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Build Profile', // Initial action to navigate to profile
    ),
    RewardTask(
      id: 'build_plans',
      title: 'Build Workout & Diet Plan',
      description: 'Set up your workout and diet plan to earn FitCoins.',
      points: 10,
      type: RewardType.oneOff,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText:
          'Build Workout & DietPlan', // Initial action to navigate to builder screen
    ),
    RewardTask(
      id: 'share_progress',
      title: 'Share Progress',
      description: 'Share your progress to earn FitCoins.',
      points: 10,
      type: RewardType.daily, // Changed to daily as per requirement
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Share Progress', // Initial action to navigate to sharing
    ),
    RewardTask(
      id: 'complete_side_hustle',
      title: 'Compete in your first Side Hustle',
      description: 'Complete your first side hustle to earn FitCoins.',
      points: 20,
      type: RewardType.oneOff,
      maxCount: 1,
      isCompleted: false,
      isEnabled: false,
      buttonText:
          'Start Side Hustle', // Initial action to navigate to side hustle
    ),
    RewardTask(
      id: 'watch_ad',
      title: 'Watch an Ad',
      description: 'Watch an ad to earn FitCoins.',
      points: 10,
      type: RewardType.adReward,
      maxCount: 5,
      isCompleted: false,
      isEnabled: false,
      buttonText: 'Watch Ad', // Initial action to watch an ad
    ),
  ];

  final firestore = FirebaseFirestore.instance;
  for (var task in tasks) {
    await firestore.collection('rewards').doc(task.id).set(task.toJson());
  }
}
