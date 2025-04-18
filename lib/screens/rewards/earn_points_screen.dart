import 'package:cashfit/ad_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../personalize/workout_diet_builder_screen.dart';
import '../../theme.dart';
import '../../models/reward_task.dart';

class EarnPointsScreen extends StatefulWidget {
  const EarnPointsScreen({super.key});

  @override
  State<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends State<EarnPointsScreen> {
  final AuthService _authService = AuthService();
  bool isLoading = true;
  List<RewardTask> rewardTasks = [];

  // Daily Check-In State
  bool canCheckInToday = false;
  bool isCheckingIn = false;
  int currentCheckInStreak = 0;
  int pointsToEarn = 0;
  static const List<int> checkInPoints = [
    5,
    10,
    15,
    20,
    25,
    30,
    40,
  ]; // Points for days 1 to 7

  // Watch Ad State
  bool canWatchAd = false;
  int adsWatchedToday = 0;
  bool isWatchingAd = false;
  static const int maxAdsPerDay = 5;
  static const int pointsPerAd = 10; // Bonus for watching ads

  // Build Plans State
  bool canClaimBuildPlansReward = false;
  bool isClaimingBuildPlansReward = false;
  static const int pointsForBuildingPlans = 10;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoading) {
      _buildRewardTasks();
    }
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Ensure user data is loaded
    if (userProvider.currentUser == null) {
      await userProvider.loadUserData(FirebaseAuth.instance.currentUser!.uid);
    }

    if (userProvider.currentUser != null) {
      // Daily Check-In Logic
      final lastCheckIn = userProvider.currentUser!.lastCheckIn;
      final now = DateTime.now();
      currentCheckInStreak = userProvider.currentUser!.checkInStreak;

      if (lastCheckIn == null) {
        canCheckInToday = true;
        currentCheckInStreak = 0; // Start at day 1
      } else {
        final daysSinceLastCheckIn = now.difference(lastCheckIn).inDays;
        if (daysSinceLastCheckIn >= 2) {
          // Missed a day, reset streak
          currentCheckInStreak = 0;
          canCheckInToday = true;
        } else if (daysSinceLastCheckIn == 1) {
          // Can check in today, continue streak
          canCheckInToday = true;
        } else if (lastCheckIn.day == now.day &&
            lastCheckIn.month == now.month &&
            lastCheckIn.year == now.year) {
          // Already checked in today
          canCheckInToday = false;
        } else {
          canCheckInToday = true;
        }
      }

      // Calculate points to earn based on the next streak day
      int nextStreakDay = (currentCheckInStreak + 1) % 7;
      if (nextStreakDay == 0) nextStreakDay = 7; // Day 7
      pointsToEarn = checkInPoints[nextStreakDay - 1];

      // Watch Ad Logic
      final lastAdsWatchedDate = userProvider.currentUser!.lastAdsWatchedDate;
      if (lastAdsWatchedDate == null ||
          lastAdsWatchedDate.day != now.day ||
          lastAdsWatchedDate.month != now.month ||
          lastAdsWatchedDate.year != now.year) {
        adsWatchedToday = 0;
      } else {
        adsWatchedToday = userProvider.currentUser!.dailyAdsWatched;
      }
      canWatchAd = adsWatchedToday < maxAdsPerDay;

      // Build Plans Logic
      canClaimBuildPlansReward =
          userProvider.currentUser!.hasBuiltPlans &&
          !userProvider.currentUser!.hasClaimedBuildPlansReward;

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _buildRewardTasks() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    rewardTasks = [
      // Daily Check-In Task
      RewardTask(
        title: "Daily Check-In",
        description:
            canCheckInToday
                ? "Day ${currentCheckInStreak + 1} of 7: +$pointsToEarn Points"
                : "Completed for Today - Come Back Tomorrow!",
        points: pointsToEarn,
        isCompleted: !canCheckInToday,
        isEnabled: canCheckInToday && !isCheckingIn,
        onAction: canCheckInToday && !isCheckingIn ? _checkIn : null,
        progressChart: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            int day = index + 1;
            bool isCompleted = day <= currentCheckInStreak;
            bool isCurrentDay = day == currentCheckInStreak + 1;
            bool showArrow = day == currentCheckInStreak + 1 && canCheckInToday;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Card(
                          elevation: 4,
                          shape: const CircleBorder(),
                          color:
                              isCompleted
                                  ? colorScheme.primary
                                  : (isCurrentDay && canCheckInToday
                                      ? colorScheme.primary.withOpacity(0.7)
                                      : colorScheme.onSurfaceVariant
                                          .withOpacity(0.3)),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child:
                                  isCompleted
                                      ? Icon(
                                        Icons.check_circle,
                                        color: colorScheme.onPrimary,
                                        size: 24,
                                      )
                                      : Text(
                                        "$day",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  isCurrentDay &&
                                                          canCheckInToday
                                                      ? colorScheme.onPrimary
                                                      : colorScheme
                                                          .onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                            ),
                          ),
                        ),
                        if (showArrow)
                          Positioned(
                            top: -5,
                            child: Icon(
                              Icons.arrow_drop_up,
                              color: colorScheme.secondary,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "+${checkInPoints[day - 1]}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isCompleted || (isCurrentDay && canCheckInToday)
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
      // Build Workout and Diet Plan Task
      RewardTask(
        title: "Build Your Workout & Diet Plan",
        description:
            userProvider.currentUser!.hasBuiltPlans
                ? (userProvider.currentUser!.hasClaimedBuildPlansReward
                    ? "You’ve already claimed this reward."
                    : "You’ve built your plan! Claim your reward.")
                : "Set up your personalized workout and diet plan to earn points!",
        points: pointsForBuildingPlans,
        isCompleted:
            userProvider.currentUser!.hasBuiltPlans &&
            userProvider.currentUser!.hasClaimedBuildPlansReward,
        isEnabled:
            userProvider.currentUser!.hasBuiltPlans
                ? (canClaimBuildPlansReward && !isClaimingBuildPlansReward)
                : true,
        onAction:
            userProvider.currentUser!.hasBuiltPlans
                ? (userProvider.currentUser!.hasClaimedBuildPlansReward
                    ? null
                    : _claimBuildPlansReward)
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutDietBuilderScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
      ),
      // Watch Ad Task
      RewardTask(
        title: "Watch an Ad",
        description:
            canWatchAd
                ? "Watch an ad to earn a bonus! ($adsWatchedToday/$maxAdsPerDay today)"
                : "You’ve reached the daily limit for watching ads. Come back tomorrow!",
        points: pointsPerAd,
        isCompleted: !canWatchAd,
        isEnabled: canWatchAd && !isWatchingAd,
        onAction: canWatchAd && !isWatchingAd ? _watchAd : null,
      ),
    ];
  }

  Future<void> _checkIn() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    setState(() {
      isCheckingIn = true;
    });

    try {
      // Server-side check to prevent abuse
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
      if (lastCheckIn != null &&
          lastCheckIn.day == now.day &&
          lastCheckIn.month == now.month &&
          lastCheckIn.year == now.year) {
        // Already checked in today, prevent further check-ins
        setState(() {
          canCheckInToday = false;
          isCheckingIn = false;
        });
        return;
      }

      // Increment the streak (or reset if completing day 7)
      int newStreak = currentCheckInStreak + 1;
      if (newStreak > 7) newStreak = 1; // Reset to day 1 after day 7
      int pointsAwarded = checkInPoints[newStreak - 1];

      await _authService.dailyCheckIn(
        FirebaseAuth.instance.currentUser!.uid,
        newStreak,
        pointsAwarded,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Checked in! Day $newStreak: +$pointsAwarded points",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Update local state immediately
      setState(() {
        canCheckInToday = false;
        currentCheckInStreak = newStreak;
        pointsToEarn = checkInPoints[(newStreak % 7 == 0 ? 7 : newStreak % 7)];
      });

      // Refresh user data in the background to ensure consistency
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserData(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
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
          isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _claimBuildPlansReward() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    setState(() {
      isClaimingBuildPlansReward = true;
    });

    try {
      await _authService.claimBuildPlansReward(
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Reward claimed! +$pointsForBuildingPlans points",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // Update local state immediately
      setState(() {
        canClaimBuildPlansReward = false;
      });

      // Refresh user data in the background
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserData(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
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
    } finally {
      if (mounted) {
        setState(() {
          isClaimingBuildPlansReward = false;
        });
      }
    }
  }

  Future<void> _watchAd() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    setState(() {
      isWatchingAd = true;
    });

    AdHelper.showRewardedAd(
      context: context,
      onRewarded: (RewardItem reward) async {
        try {
          await _authService.watchAdForPoints(
            FirebaseAuth.instance.currentUser!.uid,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.primary,
              content: Text(
                "Ad watched! +$pointsPerAd points",
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
          // Update local state immediately
          setState(() {
            adsWatchedToday++;
            canWatchAd = adsWatchedToday < maxAdsPerDay;
          });

          // Refresh user data in the background
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).loadUserData(FirebaseAuth.instance.currentUser!.uid);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.error,
              content: Text(
                "Failed to award points for ad: $e",
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
              isWatchingAd = false;
            });
          }
        }
      },
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
                  // Header
                  Text(
                    "Earn Points",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reward Tasks
                  ...rewardTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 1,
                        color: colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                task.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (task.progressChart != null) ...[
                                const SizedBox(height: 8),
                                task.progressChart!,
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        task.isEnabled
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                    foregroundColor:
                                        task.isEnabled
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: task.onAction,
                                  child:
                                      task.title == "Daily Check-In" &&
                                              isCheckingIn
                                          ? CircularProgressIndicator(
                                            color: colorScheme.onPrimary,
                                            strokeWidth: 2,
                                          )
                                          : (task.title ==
                                                      "Build Your Workout & Diet Plan" &&
                                                  isClaimingBuildPlansReward
                                              ? CircularProgressIndicator(
                                                color: colorScheme.onPrimary,
                                                strokeWidth: 2,
                                              )
                                              : (task.title == "Watch an Ad" &&
                                                      isWatchingAd
                                                  ? CircularProgressIndicator(
                                                    color:
                                                        colorScheme.onPrimary,
                                                    strokeWidth: 2,
                                                  )
                                                  : Text(
                                                    task.title ==
                                                                "Daily Check-In" &&
                                                            !task.isCompleted
                                                        ? "Check In"
                                                        : task.isCompleted
                                                        ? "Completed"
                                                        : "+${task.points} Points",
                                                  ))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
