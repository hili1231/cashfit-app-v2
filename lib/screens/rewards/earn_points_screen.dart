import 'dart:io';
import 'package:cashfit/models/app_user.dart';
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
import '../side_hustle/side_hustle_screen.dart';
import '../profile_screen.dart';
import '../nav_screen.dart';
import '../workouts/workouts_screen.dart';
import '../../ad_helper.dart';
import '../../services/auth_service.dart';

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

  bool canCheckInToday = false;
  int currentCheckInStreak = 0;
  int checkInFitCoinsToEarn = 0;
  static const List<int> checkInFitCoins = [5, 10, 15, 20, 25, 30, 40];

  bool canWatchAd = false;
  int adsWatchedToday = 0;
  Timestamp? lastAdWatchedTimestamp;
  static const int maxAdsPerPeriod = 7;
  static const int fitCoinsPerAd = 10;
  static const Duration adDebounce = Duration(seconds: 1);

  int currentSteps = 0;
  int dailyStepTarget = 10000;
  Stream<StepCount>? stepCountStream;
  bool stepCounterInitialized = false;
  bool stepCounterSupported = Platform.isAndroid || Platform.isIOS;
  DateTime? lastAdAttempt;

  @override
  void initState() {
    super.initState();
    _initAll();
    if (stepCounterSupported) {
      _initializeStepCounter();
    } else {
      _logger.i(
        'Step counter skipped on unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }

  @override
  void dispose() {
    stepCountStream = null;
    super.dispose();
  }

  Future<void> _initializeStepCounter() async {
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
              "Step counter permission is required to track steps. Please enable it in settings.",
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
    } else {
      await userProvider.refreshUser();
    }

    if (userProvider.currentUser != null) {
      _updateTaskStates();
      setState(() {
        isUserDataLoaded = true;
      });
    } else {
      setState(() {
        isLoading = false;
        isUserDataLoaded = true;
      });
    }
  }
  void _updateTaskStates() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final now = DateTime.now();
    final user = userProvider.currentUser!;

    // Daily Check-In Logic
    final lastCheckIn = user.lastCheckIn;
    currentCheckInStreak = user.checkInStreak;
    
    // Fix for new users - ensure we show Day 1 for first-time users
    if (lastCheckIn == null) {
      currentCheckInStreak = 0;
    }
    
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

    // Ad Watching Logic
    final lastAdsWatchedDate = user.lastAdsWatchedDate;
    lastAdWatchedTimestamp =
        user.lastAdWatchedTimestamp is Timestamp
            ? user.lastAdWatchedTimestamp as Timestamp?
            : user.lastAdWatchedTimestamp != null
            ? Timestamp.fromDate(user.lastAdWatchedTimestamp as DateTime)
            : null;
    adsWatchedToday =
        lastAdsWatchedDate != null && _isSameDay(lastAdsWatchedDate, now)
            ? user.dailyAdsWatched
            : 0;
    canWatchAd = adsWatchedToday < maxAdsPerPeriod;

    // Daily Step Goal Logic
    dailyStepTarget = user.dailyStepTarget ?? 10000;
    taskStates['daily_step_goal'] =
        stepCounterSupported && currentSteps >= dailyStepTarget;    // Other Tasks Logic
    taskStates = {
      'daily_check_in': canCheckInToday,
      'complete_workout':
          user.lastWorkoutCompletionDate != null &&
          _isSameDay(user.lastWorkoutCompletionDate!, now),
      'complete_meal_plan':
          user.lastMealPlanCompletionDate != null &&
          _isSameDay(user.lastMealPlanCompletionDate!, now),
      'update_weight': _hasUnclaimedWeightUpdate(user, now),
      'build_profile':
          user.gender.isNotEmpty &&
          user.age.isNotEmpty &&
          user.height.isNotEmpty &&
          user.weight.isNotEmpty,
      'complete_side_hustle': user.joinedSideHustles.isNotEmpty,
      'share_on_social': false, // Default to false, will be controlled by user interaction
      'watch_ad': canWatchAd,
    };

    taskLoadingStates = {for (var id in taskStates.keys) id: false};

    _logger.i('Task States: $taskStates');
    _logger.i('User Completed One-Offs: ${user.completedOneOffIds}');
    _logger.i('Last Check-In: $lastCheckIn, Can Check In: $canCheckInToday');
    _logger.i('Ads Watched Today: $adsWatchedToday, Can Watch Ad: $canWatchAd');
    _logger.i(
      'Has Built Plans: ${user.hasBuiltPlans}, Has Claimed Build Plans Reward: ${user.hasClaimedBuildPlansReward}',
    );

    _buildRewardTasks();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  DateTime _getLastMonday(DateTime date) {
    final daysSinceMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysSinceMonday));
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final lastMonday1 = _getLastMonday(date1);
    final lastMonday2 = _getLastMonday(date2);
    return lastMonday1.year == lastMonday2.year &&
        lastMonday1.month == lastMonday2.month &&
        lastMonday1.day == lastMonday2.day;
  }

  bool _hasUnclaimedWeightUpdate(AppUser user, DateTime now) {
    final lastWeightUpdate = user.lastWeightUpdateDate;
    final claimedReward = user.claimedRewards['update_weight'];
    final hasClaimed =
        claimedReward != null && claimedReward['claimed'] == true;
    final lastClaimedDate =
        hasClaimed
            ? (claimedReward['lastClaimed'] as Timestamp?)?.toDate()
            : null;

    if (lastWeightUpdate == null) return false;

    final isWeightUpdatedThisWeek = _isSameWeek(lastWeightUpdate, now);
    final isClaimedThisWeek =
        lastClaimedDate != null && _isSameWeek(lastClaimedDate, now);

    return isWeightUpdatedThisWeek && !isClaimedThisWeek;
  }

  void _updateDailyStepGoalState() {
    if (!stepCounterSupported) return;
    taskStates['daily_step_goal'] = currentSteps >= dailyStepTarget;
    _buildRewardTasks();
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
    final sortedTasks = [...rewardTasks];
    sortedTasks.sort((a, b) {
      if (a.id == 'daily_check_in') return -1;
      if (b.id == 'daily_check_in') return 1;
      bool aCompleted =
          !(taskStates[a.id] ?? false) &&
          (a.type == RewardType.oneOff || a.type == RewardType.weekly);
      bool bCompleted =
          !(taskStates[b.id] ?? false) &&
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

          final claimedReward = user.claimedRewards[task.id];
          bool hasClaimed =
              claimedReward != null && claimedReward['claimed'] == true;
          DateTime? lastClaimedDate;

          if (claimedReward != null && claimedReward['lastClaimed'] != null) {
            lastClaimedDate =
                (claimedReward['lastClaimed'] as Timestamp).toDate();
          }

          if (lastClaimedDate != null) {
            final now = DateTime.now();
            if (task.type == RewardType.daily ||
                task.type == RewardType.dailyCheckIn ||
                task.type == RewardType.adReward) {
              if (!_isSameDay(lastClaimedDate, now)) {
                hasClaimed = false;
              }
            } else if (task.type == RewardType.weekly) {
              if (!_isSameWeek(lastClaimedDate, now)) {
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
                  !(taskLoadingStates[task.id] ?? false);
              onAction = isEnabled ? () => _checkIn(task) : null;
              buttonText = isCompleted ? 'Completed' : 'Check In';
              break;
            case 'complete_workout':
              final workoutCompleted =
                  user.lastWorkoutCompletionDate != null &&
                  _isSameDay(user.lastWorkoutCompletionDate!, DateTime.now());
              isCompleted = hasClaimed;
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
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
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
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
                isCompleted = false;  // Changed from true to false
                isEnabled = false;
                buttonText = 'Not Supported';
                break;
              }
              final stepGoalReached = currentSteps >= dailyStepTarget;
              isCompleted = hasClaimed;
              isEnabled =
                  stepGoalReached &&
                  !isCompleted &&
                  !(taskLoadingStates[task.id] ?? false);
              onAction = isEnabled ? () => _claimReward(task) : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (stepGoalReached ? 'Claim Reward' : 'Check Steps');
              break;
            case 'update_weight':
              final hasUpdatedWeight = taskStates['update_weight'] ?? false;

              // 1️⃣ completed this week? → grey / disabled
              isCompleted = hasClaimed;

              // 2️⃣ otherwise we enable the button only
              //    – if user still has to update the weight  ➜ “Update weight”
              //    – or if weight is updated but reward not claimed ➜ “Claim reward”
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
              onAction =
                  navState != null
                      ? (hasUpdatedWeight && !isCompleted
                          ? () => _claimReward(task)
                          : () =>
                              navState.setDetailScreen(const ProfileScreen()))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (hasUpdatedWeight ? 'Claim Reward' : 'Update Weight');
              break;
            case 'build_profile':
              final profileBuilt = taskStates['build_profile'] ?? false;

              // one‑off → once claimed, never enabled again
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('build_profile');
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
              onAction =
                  navState != null
                      ? (profileBuilt && !isCompleted
                          ? () => _claimReward(task)
                          : () =>
                              navState.setDetailScreen(const ProfileScreen()))
                      : null;
              buttonText =
                  isCompleted
                      ? 'Completed'
                      : (profileBuilt ? 'Claim Reward' : 'Build Profile');
              break;            case 'build_plans':
              final built = user.hasBuiltPlans;
              isCompleted = hasClaimed || user.hasClaimedBuildPlansReward;
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
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
                      : (built ? 'Claim Reward' : 'Build Plan');              break;
              
            case 'share_on_social':
              isCompleted = hasClaimed || 
                  user.completedOneOffIds.contains('share_on_social');
              isEnabled = !isCompleted && !(taskLoadingStates[task.id] ?? false);
              onAction = isEnabled ? () => _shareOnSocial(task) : null;
              buttonText = isCompleted ? 'Completed' : 'Share Now';
              break;

            case 'complete_side_hustle':
              final hasCompletedHustle = user.joinedSideHustles.isNotEmpty;
              isCompleted =
                  hasClaimed ||
                  user.completedOneOffIds.contains('complete_side_hustle');
              isEnabled =
                  !isCompleted && !(taskLoadingStates[task.id] ?? false);
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
                  !(taskLoadingStates[task.id] ?? false);
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
        if (!_isSameWeek(lastClaimedDate, now)) {
          hasClaimed = false;
        }
      }
    }    switch (task.id) {
      case 'daily_check_in':
        return canCheckInToday
            ? "Check in to mine +$checkInFitCoinsToEarn FitCoins (Day ${currentCheckInStreak == 0 ? 1 : (currentCheckInStreak % 7) == 0 ? 7 : (currentCheckInStreak % 7) + 1}/7)"
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
                    _isSameWeek(user.lastWeightUpdateDate!, now)
                ? "Weight updated! Mine your +${task.points} FitCoins (Badge: Weight Tracker)."
                : "Update your weight to mine +${task.points} FitCoins (Badge: Weight Tracker).");
      case 'build_profile':
        return hasClaimed || user.completedOneOffIds.contains('build_profile')
            ? "Profile completed! FitCoins mined (Badge: Profile Builder)."
            : "Complete your profile to mine +${task.points} FitCoins (Badge: Profile Builder).";
      case 'build_plans':        return hasClaimed || user.hasClaimedBuildPlansReward
            ? "Plans built! FitCoins mined (Badge: Plan Creator)."
            : (user.hasBuiltPlans
                ? "Plans built! Mine your +${task.points} FitCoins (Badge: Plan Creator)."
                : "Build your workout and diet plan to mine +${task.points} FitCoins (Badge: Plan Creator).");
      case 'share_on_social':
        return hasClaimed || user.completedOneOffIds.contains('share_on_social')
            ? "Thank you for sharing! FitCoins mined."
            : "Share CashFit on your social network to mine +${task.points} FitCoins!";
      case 'complete_side_hustle':
        return hasClaimed ||
                user.completedOneOffIds.contains('complete_side_hustle')
            ? "Side hustle completed! FitCoins mined."
            : "Complete a side hustle to mine +${task.points} FitCoins.";
      case 'watch_ad':
        if (canWatchAd) {
          return "Watch an ad to mine +$fitCoinsPerAd FitCoins (${maxAdsPerPeriod - adsWatchedToday}/$maxAdsPerPeriod remaining today).";
        } else {
          return "Max ads watched today. Try again tomorrow.";
        }
      default:
        return task.description;
    }
  }
  Widget _progressWheel() {
    final cs = Theme.of(context).colorScheme;
    // Calculate today's index for the circle properly, accounting for first-time users
    final todayIdx = currentCheckInStreak == 0 ? 1 : ((currentCheckInStreak % 7) == 0 ? 7 : (currentCheckInStreak % 7) + (canCheckInToday ? 1 : 0));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final idx = i + 1;
        final reached = idx <= (currentCheckInStreak == 0 ? 0 : (currentCheckInStreak % 7 == 0 ? 7 : currentCheckInStreak % 7));
        final today = idx == todayIdx;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    reached || today ? cs.primary : cs.surfaceContainerHighest,
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
      }      // For new users (currentCheckInStreak == 0), we want to set the streak to 1
      // For everyone else, increment and handle day 7 to day 1 transition
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

      await userProvider.refreshUser();
      _buildRewardTasks();
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
        await AuthService.instance.claimBuildPlansReward(
          userProvider.firebaseUser!.uid,
        );
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

      await userProvider.refreshUser();
      _buildRewardTasks();
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

    final now = DateTime.now();
    if (lastAdAttempt != null &&
        now.difference(lastAdAttempt!).inSeconds < adDebounce.inSeconds) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              "Please wait a moment before watching another ad.",
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
      }
      return;
    }

    setState(() {
      taskLoadingStates[task.id] = true;
      lastAdAttempt = now;
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

            await userProvider.refreshUser();
            _buildRewardTasks();
          } catch (e) {
            _logger.e("Failed to process ad reward: $e");
            if (mounted) {
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
            }
          }
        },
        onAdDismissed: () {
          if (mounted) {
            setState(() {
              taskLoadingStates[task.id] = false;
            });
          }
        },
        onAdFailed: (AdError error) {
          _logger.e("Ad failed to show: ${error.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colorScheme.error,
                content: Text(
                  "Failed to load ad: ${error.message}",
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
            setState(() {
              taskLoadingStates[task.id] = false;
            });
          }
        },
      );
    } catch (e) {
      _logger.e("Error showing ad: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              "Error showing ad: $e",
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
        setState(() {
          taskLoadingStates[task.id] = false;
        });
      }
    }
  }
  Future<void> _shareOnSocial(RewardTask task) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    setState(() {
      taskLoadingStates[task.id] = true;
    });

    try {
      // This would normally use a share plugin like share_plus
      // But for demo purposes, we'll just simulate the sharing action
      await Future.delayed(const Duration(seconds: 1)); // Simulate sharing
      
      // Since we don't have an actual share plugin imported, we'll show a dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share on Social Media'),
          content: const Text('Share your fitness journey with CashFit on your favorite social network!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeSharing(task);
              },
              child: const Text('I\'ve Shared'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e("Failed to share: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to share: $e",
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
  
  Future<void> _completeSharing(RewardTask task) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.claimReward(task.id, task.points);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Thank you for sharing! +${task.points} FitCoins mined!",
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

      await userProvider.refreshUser();
      _buildRewardTasks();
    } catch (e) {
      _logger.e("Failed to claim share reward: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to claim reward: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildTaskCard(RewardTask task) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                  enabled:
                      task.isEnabled && !(taskLoadingStates[task.id] ?? false),
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
          backgroundColor: enabled ? cs.primary : cs.surfaceContainerHighest,
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
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Rebuild tasks whenever user data changes
    if (isUserDataLoaded && userProvider.currentUser != null) {
      _updateTaskStates();
    }

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
