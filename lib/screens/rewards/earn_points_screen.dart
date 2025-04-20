import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../providers/user_provider.dart';
import '../personalize/workout_diet_builder_screen.dart';
import '../../theme.dart';
import '../../models/reward_task.dart';
import '../diets/diet_selector_screen.dart';
import '../community_feed/community_feed_screen.dart';
import '../side_hustle/side_hustle_screen.dart';
import '../profile_screen.dart';
import '../nav_screen.dart';
import '../workouts/workouts_screen.dart';
import '../../ad_helper.dart';

class EarnPointsScreen extends StatefulWidget {
  const EarnPointsScreen({super.key});

  @override
  State<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends State<EarnPointsScreen> {
  final Logger _logger = Logger();
  bool isLoading = true;
  bool isUserDataLoaded = false;
  List<RewardTask> rewardTasks = [];
  Map<String, bool> taskStates = {};
  Map<String, bool> taskLoadingStates = {};
  Map<String, bool> taskSparkleStates = {};

  // Daily Check-In State
  bool canCheckInToday = false;
  int currentCheckInStreak = 0;
  int checkInFitCoinsToEarn = 0;
  static const List<int> checkInFitCoins = [5, 10, 15, 20, 25, 30, 40];

  // Watch Ad State
  bool canWatchAd = false;
  int adsWatchedToday = 0;
  Timestamp? lastAdWatchedTimestamp;
  static const int maxAdsPerPeriod = 5;
  static const int fitCoinsPerAd = 10;
  static const Duration adCooldown = Duration(hours: 4);

  // Step Counter State
  int currentSteps = 0;
  int dailyStepTarget = 10000;
  Stream<StepCount>? stepCountStream;
  bool stepCounterInitialized = false;
  bool stepCounterSupported = true;

  @override
  void initState() {
    super.initState();
    _initAll();
    _initializeStepCounter();
  }

  @override
  void dispose() {
    stepCountStream = null;
    super.dispose();
  }

  Future<void> _initializeStepCounter() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.w(
        "Step counter not supported on this platform: ${Platform.operatingSystem}",
      );
      setState(() {
        stepCounterSupported = false;
        stepCounterInitialized = false;
      });
      return;
    }

    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      setState(() {
        stepCounterInitialized = true;
      });
      stepCountStream = Pedometer.stepCountStream;
      stepCountStream
          ?.listen((StepCount event) {
            setState(() {
              currentSteps = event.steps;
            });
            _updateDailyStepGoalState();
          })
          .onError((error) {
            _logger.e("Step Counter Error: $error");
            setState(() {
              stepCounterInitialized = false;
            });
          });
    } else {
      _logger.w("Step counter permission denied");
      if (status.isPermanentlyDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Step counter permission is required to track your steps. Please enable it in settings.",
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      setState(() {
        stepCounterInitialized = false;
      });
    }
  }

  Future<void> _initAll() async {
    setState(() => isLoading = true);
    await _loadTasks();
    await _loadUserData();
    _buildRewardTasks();
    setState(() => isLoading = false);
  }

  Future<void> _loadTasks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('rewards').get();
      rewardTasks =
          snapshot.docs.map((doc) => RewardTask.fromJson(doc.data())).toList();
      taskSparkleStates = {for (var task in rewardTasks) task.id: false};
    } catch (e) {
      _logger.e("Failed to load reward tasks: $e");
      rewardTasks = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reward tasks: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      await userProvider.loadUserData(FirebaseAuth.instance.currentUser!.uid);
    }

    if (userProvider.currentUser != null) {
      final now = DateTime.now();
      final user = userProvider.currentUser!;

      // Daily Check-In Logic
      final lastCheckIn = user.lastCheckIn;
      currentCheckInStreak = user.checkInStreak;
      canCheckInToday = lastCheckIn == null || !_isSameDay(lastCheckIn, now);
      if (lastCheckIn != null && canCheckInToday) {
        final daysSinceLastCheckIn = now.difference(lastCheckIn).inDays;
        if (daysSinceLastCheckIn >= 2) {
          currentCheckInStreak = 0;
        }
      }
      int nextStreakDay = (currentCheckInStreak + 1) % 7;
      if (nextStreakDay == 0) nextStreakDay = 7;
      checkInFitCoinsToEarn = checkInFitCoins[nextStreakDay - 1];

      // Watch Ad Logic
      final lastAdsWatchedDate = user.lastAdsWatchedDate;
      lastAdWatchedTimestamp = user.lastAdWatchedTimestamp as Timestamp?;
      adsWatchedToday =
          lastAdsWatchedDate != null && _isSameDay(lastAdsWatchedDate, now)
              ? user.dailyAdsWatched
              : 0;
      canWatchAd =
          adsWatchedToday < maxAdsPerPeriod &&
          (lastAdWatchedTimestamp == null ||
              now.difference(lastAdWatchedTimestamp!.toDate()).inSeconds >=
                  adCooldown.inSeconds);

      // Load daily step target
      dailyStepTarget = user.dailyStepTarget ?? 10000;

      // Initialize task states
      taskStates = {
        'daily_check_in': canCheckInToday,
        'complete_workout':
            user.lastWorkoutCompletionDate != null &&
            _isSameDay(user.lastWorkoutCompletionDate!, now),
        'complete_meal_plan':
            user.lastMealPlanCompletionDate != null &&
            _isSameDay(user.lastMealPlanCompletionDate!, now),
        'daily_step_goal':
            stepCounterSupported && currentSteps >= dailyStepTarget,
        'update_weight':
            user.lastWeightUpdateDate != null &&
            DateTime.now().difference(user.lastWeightUpdateDate!).inDays < 7,
        'build_profile':
            user.gender.isNotEmpty &&
            user.age.isNotEmpty &&
            user.height.isNotEmpty &&
            user.weight.isNotEmpty &&
            user.avatar.isNotEmpty,
        'build_plans': user.hasBuiltPlans,
        'share_progress': user.joinedChallenges.isNotEmpty,
        'join_challenge': user.joinedChallenges.isNotEmpty,
        'complete_side_hustle': user.joinedSideHustles.isNotEmpty,
        'watch_ad': canWatchAd,
      };

      taskLoadingStates = {for (var id in taskStates.keys) id: false};

      _logger.i('Task States: $taskStates');
      _logger.i('User Completed One-Offs: ${user.completedOneOffIds}');
      _logger.i('Last Check-In: $lastCheckIn, Can Check In: $canCheckInToday');
      _logger.i(
        'Ads Watched Today: $adsWatchedToday, Can Watch Ad: $canWatchAd',
      );
      _logger.i(
        'Has Built Plans: ${user.hasBuiltPlans}, Has Claimed Build Plans Reward: ${user.hasClaimedBuildPlansReward}',
      );

      setState(() {
        isUserDataLoaded = true;
      });

      _buildRewardTasks();
    } else {
      setState(() {
        isLoading = false;
        isUserDataLoaded = true;
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  void _updateDailyStepGoalState() {
    if (!stepCounterSupported) return;
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      taskStates['daily_step_goal'] = currentSteps >= dailyStepTarget;
      _buildRewardTasks();
    }
  }

  void _buildRewardTasks() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();
    final user = userProvider.currentUser;

    if (user == null) {
      _logger.w('User is null, cannot build reward tasks');
      return;
    }

    if (navState == null) {
      _logger.w('NavScreenState is null, navigation may not work');
    }

    // Sort tasks: daily_check_in first, then active tasks, then completed one-off tasks
    final sortedTasks = [...rewardTasks];
    sortedTasks.sort((a, b) {
      if (a.id == 'daily_check_in') return -1;
      if (b.id == 'daily_check_in') return 1;
      bool aCompleted =
          !taskStates[a.id]! &&
          (a.type == RewardType.oneOff || a.type == RewardType.weekly);
      bool bCompleted =
          !taskStates[b.id]! &&
          (b.type == RewardType.oneOff || b.type == RewardType.weekly);
      if (aCompleted && !bCompleted) return 1;
      if (!aCompleted && bCompleted) return -1;
      return 0;
    });

    rewardTasks =
        sortedTasks.map((task) {
          bool isCompleted = false;
          bool isEnabled = false;
          VoidCallback? onAction;
          String buttonText = task.buttonText;

          // Check if the reward has been claimed
          final claimedReward = user.claimedRewards[task.id];
          bool hasClaimed =
              claimedReward != null && claimedReward['claimed'] == true;
          DateTime? lastClaimedDate;

          if (claimedReward != null && claimedReward['lastClaimed'] != null) {
            lastClaimedDate =
                (claimedReward['lastClaimed'] as Timestamp).toDate();
          }

          // Reset daily/weekly/ad rewards if not claimed on the current day/week
          if (lastClaimedDate != null) {
            final now = DateTime.now();
            if (task.type == RewardType.daily ||
                task.type == RewardType.dailyCheckIn ||
                task.type == RewardType.adReward) {
              if (!_isSameDay(lastClaimedDate, now)) {
                hasClaimed = false;
              }
            } else if (task.type == RewardType.weekly) {
              final daysSinceLastClaim = now.difference(lastClaimedDate).inDays;
              if (daysSinceLastClaim >= 7) {
                hasClaimed = false;
              }
            }
          }

          switch (task.id) {
            case 'daily_check_in':
              isCompleted = hasClaimed;
              isEnabled =
                  canCheckInToday &&
                  !isCompleted &&
                  !taskLoadingStates[task.id]!;
              onAction = isEnabled ? () => _checkIn(task) : null;
              buttonText = isCompleted ? 'Completed' : 'Check In';
              break;
            case 'complete_workout':
              final workoutCompleted =
                  user.lastWorkoutCompletionDate != null &&
                  _isSameDay(user.lastWorkoutCompletionDate!, DateTime.now());
              isCompleted = hasClaimed;
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (workoutCompleted
                          ? () => _claimReward(task)
                          : () =>
                              navState.setDetailScreen(const WorkoutsScreen()))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (workoutCompleted ? 'Claim Reward' : 'Go to Workout');
              break;
            case 'complete_meal_plan':
              final mealPlanCompleted =
                  user.lastMealPlanCompletionDate != null &&
                  _isSameDay(user.lastMealPlanCompletionDate!, DateTime.now());
              isCompleted = hasClaimed;
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (mealPlanCompleted
                          ? () => _claimReward(task)
                          : () => navState.setDetailScreen(
                            const DietSelectorScreen(),
                          ))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (mealPlanCompleted ? 'Claim Reward' : 'Log Meals');
              break;
            case 'daily_step_goal':
              if (!stepCounterSupported) {
                isCompleted = true;
                isEnabled = false;
                buttonText = 'Not Supported';
                break;
              }
              final stepGoalReached = currentSteps >= dailyStepTarget;
              isCompleted = hasClaimed;
              isEnabled =
                  stepGoalReached &&
                  !isCompleted &&
                  !taskLoadingStates[task.id]!;
              onAction = isEnabled ? () => _claimReward(task) : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (stepGoalReached ? 'Claim Reward' : 'Check Steps');
              break;
            case 'update_weight':
              final canUpdateWeight =
                  user.lastWeightUpdateDate == null ||
                  DateTime.now()
                          .difference(user.lastWeightUpdateDate!)
                          .inDays >=
                      7;
              isCompleted = hasClaimed || !canUpdateWeight;
              isEnabled =
                  canUpdateWeight &&
                  !isCompleted &&
                  !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (canUpdateWeight
                          ? () => _claimReward(task)
                          : () =>
                              navState.setDetailScreen(const ProfileScreen()))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (canUpdateWeight ? 'Claim Reward' : 'Update Weight');
              break;
            case 'build_profile':
              final profileBuilt =
                  user.gender.isNotEmpty &&
                  user.age.isNotEmpty &&
                  user.height.isNotEmpty &&
                  user.weight.isNotEmpty &&
                  user.avatar.isNotEmpty;
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('build_profile');
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (profileBuilt
                          ? () => _claimReward(task)
                          : () =>
                              navState.setDetailScreen(const ProfileScreen()))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (profileBuilt ? 'Claim Reward' : 'Build Profile');
              break;
            case 'build_plans':
              final built = user.hasBuiltPlans;
              isCompleted = hasClaimed || user.hasClaimedBuildPlansReward;
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  navState != null
                      ? (built
                          ? () => _claimReward(task)
                          : () => navState.setDetailScreen(
                            const WorkoutDietBuilderScreen(),
                          ))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (built ? 'Claim Reward' : 'Build Plan');
              break;
            case 'share_progress':
              final hasShared = user.joinedChallenges.isNotEmpty;
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('share_progress');
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (hasShared
                          ? () => _claimReward(task)
                          : () => navState.setDetailScreen(
                            const CommunityFeedScreen(),
                          ))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (hasShared ? 'Claim Reward' : 'Share Progress');
              break;
            case 'join_challenge':
              final hasJoinedChallenge = user.joinedChallenges.isNotEmpty;
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('join_challenge');
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (hasJoinedChallenge
                          ? () => _claimReward(task)
                          : () => navState.setDetailScreen(
                            const CommunityFeedScreen(),
                          ))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (hasJoinedChallenge
                          ? 'Claim Reward'
                          : 'Join Challenge');
              break;
            case 'complete_side_hustle':
              final hasCompletedHustle = user.joinedSideHustles.isNotEmpty;
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('complete_side_hustle');
              isEnabled = !isCompleted && !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled && navState != null
                      ? (hasCompletedHustle
                          ? () => _claimReward(task)
                          : () => navState.setDetailScreen(
                            const SideHustleScreen(),
                          ))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (hasCompletedHustle
                          ? 'Claim Reward'
                          : 'Start Side Hustle');
              break;
            case 'watch_ad':
              final adWatched =
                  adsWatchedToday > 0 && adsWatchedToday <= maxAdsPerPeriod;
              isCompleted = hasClaimed || adsWatchedToday >= maxAdsPerPeriod;
              isEnabled =
                  (canWatchAd || adWatched) &&
                  !isCompleted &&
                  !taskLoadingStates[task.id]!;
              onAction =
                  isEnabled
                      ? (adWatched
                          ? () => _claimReward(task)
                          : () => _watchAd(task))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (adWatched ? 'Claim Reward' : 'Watch Ad');
              break;
          }

          return RewardTask(
            id: task.id,
            title: task.title,
            description: _getTaskDescription(task),
            points:
                task.id == 'daily_check_in'
                    ? checkInFitCoinsToEarn
                    : task.points,
            type: task.type,
            maxCount: task.maxCount,
            isCompleted: isCompleted,
            isEnabled: isEnabled,
            onAction: onAction,
            progressChart:
                task.type == RewardType.dailyCheckIn ? _progressWheel() : null,
            buttonText: buttonText,
          );
        }).toList();

    setState(() {});
  }

  String _getTaskDescription(RewardTask task) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser!;
    final now = DateTime.now();

    final claimedReward = user.claimedRewards[task.id];
    bool hasClaimed = claimedReward != null && claimedReward['claimed'] == true;
    DateTime? lastClaimedDate;

    if (claimedReward != null && claimedReward['lastClaimed'] != null) {
      lastClaimedDate = (claimedReward['lastClaimed'] as Timestamp).toDate();
    }

    if (lastClaimedDate != null) {
      if (task.type == RewardType.daily ||
          task.type == RewardType.dailyCheckIn ||
          task.type == RewardType.adReward) {
        if (!_isSameDay(lastClaimedDate, now)) {
          hasClaimed = false;
        }
      } else if (task.type == RewardType.weekly) {
        final daysSinceLastClaim = now.difference(lastClaimedDate).inDays;
        if (daysSinceLastClaim >= 7) {
          hasClaimed = false;
        }
      }
    }

    switch (task.id) {
      case 'daily_check_in':
        return canCheckInToday
            ? "Check in to mine +$checkInFitCoinsToEarn FitCoins (Day ${currentCheckInStreak + 1}/7)"
            : "Completed for today. Come back tomorrow!";
      case 'complete_workout':
        return hasClaimed
            ? "Workout completed! FitCoins mined."
            : (user.lastWorkoutCompletionDate != null &&
                    _isSameDay(user.lastWorkoutCompletionDate!, now)
                ? "Workout completed! Mine your +${task.points} FitCoins."
                : "Complete a workout to mine +${task.points} FitCoins.");
      case 'complete_meal_plan':
        return hasClaimed
            ? "Meal plan completed! FitCoins mined."
            : (user.lastMealPlanCompletionDate != null &&
                    _isSameDay(user.lastMealPlanCompletionDate!, now)
                ? "Meal plan completed! Mine your +${task.points} FitCoins."
                : "Log your meals to mine +${task.points} FitCoins.");
      case 'daily_step_goal':
        if (!stepCounterSupported) {
          return "Step counting is not supported on this platform.";
        }
        return hasClaimed
            ? "Step goal reached! FitCoins mined."
            : (currentSteps >= dailyStepTarget
                ? "Step goal reached! Mine your +${task.points} FitCoins."
                : "Hit your step target ($currentSteps/$dailyStepTarget) to mine +${task.points} FitCoins.");
      case 'update_weight':
        return hasClaimed
            ? "Weight updated this week. Check back next week."
            : (user.lastWeightUpdateDate != null &&
                    DateTime.now()
                            .difference(user.lastWeightUpdateDate!)
                            .inDays <
                        7
                ? "Weight updated! Mine your +${task.points} FitCoins (Badge: Weight Tracker)."
                : "Update your weight to mine +${task.points} FitCoins (Badge: Weight Tracker).");
      case 'build_profile':
        return hasClaimed || user.completedOneOffIds.contains('build_profile')
            ? "Profile completed! FitCoins mined (Badge: Profile Builder)."
            : "Complete your profile to mine +${task.points} FitCoins (Badge: Profile Builder).";
      case 'build_plans':
        return hasClaimed || user.hasClaimedBuildPlansReward
            ? "Plans built! FitCoins mined (Badge: Plan Creator)."
            : (user.hasBuiltPlans
                ? "Plans built! Mine your +${task.points} FitCoins (Badge: Plan Creator)."
                : "Build your workout and diet plan to mine +${task.points} FitCoins (Badge: Plan Creator).");
      case 'share_progress':
        return hasClaimed
            ? "Progress shared! FitCoins mined."
            : (user.joinedChallenges.isNotEmpty
                ? "Progress shared! Mine your +${task.points} FitCoins."
                : "Share your progress to mine +${task.points} FitCoins.");
      case 'join_challenge':
        return hasClaimed || user.completedOneOffIds.contains('join_challenge')
            ? "Challenge joined! FitCoins mined."
            : "Join a challenge to mine +${task.points} FitCoins.";
      case 'complete_side_hustle':
        return hasClaimed ||
                user.completedOneOffIds.contains('complete_side_hustle')
            ? "Side hustle completed! FitCoins mined."
            : "Complete a side hustle to mine +${task.points} FitCoins.";
      case 'watch_ad':
        if (canWatchAd) {
          return "Watch an ad to mine +$fitCoinsPerAd FitCoins (${maxAdsPerPeriod - adsWatchedToday}/$maxAdsPerPeriod remaining today).";
        } else if (lastAdWatchedTimestamp != null &&
            now.difference(lastAdWatchedTimestamp!.toDate()).inSeconds <
                adCooldown.inSeconds) {
          final remainingSeconds =
              adCooldown.inSeconds -
              now.difference(lastAdWatchedTimestamp!.toDate()).inSeconds;
          final remainingMinutes = (remainingSeconds / 60).ceil();
          return "Cooldown: $remainingMinutes minutes until next ad.";
        } else {
          return "Max ads watched today. Try again tomorrow.";
        }
      default:
        return task.description;
    }
  }

  Widget _progressWheel() {
    final cs = Theme.of(context).colorScheme;
    final todayIdx = currentCheckInStreak + (canCheckInToday ? 1 : 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final idx = i + 1;
        final reached = idx <= currentCheckInStreak;
        final today = idx == todayIdx;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    reached || today ? cs.primary : cs.surfaceVariant,
                child:
                    reached
                        ? Icon(Icons.check, size: 20, color: cs.onPrimary)
                        : Text(
                          '$idx',
                          style: TextStyle(
                            color: today ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${checkInFitCoins[idx - 1]}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _checkIn(RewardTask task) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      taskLoadingStates[task.id] = true;
    });

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
      final lastCheckIn =
          userDoc.data()!['lastCheckIn'] != null
              ? (userDoc.data()!['lastCheckIn'] as Timestamp).toDate()
              : null;

      final now = DateTime.now();
      if (lastCheckIn != null && _isSameDay(lastCheckIn, now)) {
        setState(() {
          canCheckInToday = false;
          taskLoadingStates[task.id] = false;
        });
        return;
      }

      int newStreak = currentCheckInStreak + 1;
      if (newStreak > 7) newStreak = 1;
      int fitCoinsAwarded = checkInFitCoins[newStreak - 1];

      await userProvider.claimReward(task.id, fitCoinsAwarded);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Checked in! Day $newStreak: +$fitCoinsAwarded FitCoins",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      setState(() {
        canCheckInToday = false;
        currentCheckInStreak = newStreak;
        checkInFitCoinsToEarn =
            checkInFitCoins[(newStreak % 7 == 0 ? 7 : newStreak % 7)];
        taskStates[task.id] = false;
        taskSparkleStates[task.id] = true;
      });

      await _loadUserData();
    } catch (e) {
      _logger.e("Failed to check in: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to check in: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          taskLoadingStates[task.id] = false;
        });
      }
    }
  }

  Future<void> _claimReward(RewardTask task) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      taskLoadingStates[task.id] = true;
    });

    try {
      String? badge;
      if (task.id == 'build_plans') {
        badge = 'Plan Creator';
      } else if (task.id == 'build_profile') {
        badge = 'Profile Builder';
      } else if (task.id == 'update_weight') {
        badge = 'Weight Tracker';
      }

      await userProvider.claimReward(task.id, task.points, badge: badge);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "FitCoins mined! +${task.points} FitCoins${badge != null ? ' (Badge: $badge)' : ''}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      setState(() {
        taskStates[task.id] = false;
        taskSparkleStates[task.id] = true;
      });

      await _loadUserData();
    } catch (e) {
      _logger.e("Failed to earn FitCoins: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to earn FitCoins: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          taskLoadingStates[task.id] = false;
        });
      }
    }
  }

  Future<void> _watchAd(RewardTask task) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      taskLoadingStates[task.id] = true;
    });

    try {
      AdHelper.showRewardedAd(
        context: context,
        onRewarded: (RewardItem reward) async {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userProvider.firebaseUser!.uid)
                .update({
                  'dailyAdsWatched': FieldValue.increment(1),
                  'lastAdWatchedTimestamp': FieldValue.serverTimestamp(),
                  'lastAdsWatchedDate': FieldValue.serverTimestamp(),
                });

            setState(() {
              adsWatchedToday++;
              canWatchAd = adsWatchedToday < maxAdsPerPeriod;
              lastAdWatchedTimestamp = Timestamp.now();
              taskStates[task.id] = canWatchAd;
            });

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colorScheme.primary,
                content: Text(
                  "Ad watched! Mine your +$fitCoinsPerAd FitCoins",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            await _loadUserData();
          } catch (e) {
            _logger.e("Failed to process ad reward: $e");
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colorScheme.error,
                content: Text(
                  "Failed to process ad reward: $e",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onError,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } finally {
            if (mounted) {
              setState(() {
                taskLoadingStates[task.id] = false;
              });
            }
          }
        },
      );
    } catch (e) {
      _logger.e("Error showing ad: $e");
      if (mounted) {
        setState(() {
          taskLoadingStates[task.id] = false;
        });
      }
    }
  }

  Widget _buildTaskCard(RewardTask task) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    String? badge;
    if (task.id == 'build_plans') {
      badge = 'Plan Creator';
    } else if (task.id == 'build_profile') {
      badge = 'Profile Builder';
    } else if (task.id == 'update_weight') {
      badge = 'Weight Tracker';
    }

    _logger.i(
      'Task ${task.id}: isEnabled=${task.isEnabled}, isCompleted=${task.isCompleted}, onAction=${task.onAction != null}',
    );

    return AppTheme.animatedCard(
      child: Card(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        task.isCompleted ? 'Done' : '+${task.points}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset('assets/images/fitcoin_icon.png', width: 24),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getTaskDescription(task),
                style: theme.textTheme.bodyMedium,
              ),
              if (task.progressChart != null) ...[
                const SizedBox(height: 8),
                task.progressChart!,
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _actionButton(
                  label: task.buttonText,
                  enabled: task.isEnabled && !taskLoadingStates[task.id]!,
                  onTap: task.onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Action for $label',
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? cs.primary : cs.surfaceVariant,
          foregroundColor: enabled ? cs.onPrimary : cs.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: enabled ? onTap : null,
        child:
            taskLoadingStates[label] == true
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: cs.onPrimary,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading || userProvider.currentUser == null) {
      return Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Earn FitCoins",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset('assets/images/fitcoin_icon.png', width: 30),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...rewardTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTaskCard(task),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
