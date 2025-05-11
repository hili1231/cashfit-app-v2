import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../../models/meal_plan.dart';
import '../../models/active_diet_plan.dart';
import '../../models/removed_diet_plan.dart';
import '../../widgets/meal_card.dart';
import '../../theme.dart';
import '../../providers/user_provider.dart';
import '../../services/cache_service.dart';
import '../nav_screen.dart';
import 'meal_plan_screen.dart';
import '../personalize/workout_diet_builder_screen.dart';
import 'diet_day_detail_screen.dart';
import 'package:logger/logger.dart';

class DietSelectorScreen extends StatefulWidget {
  const DietSelectorScreen({super.key});

  static List<MealPlan>? _cachedDiets;

  @override
  State<DietSelectorScreen> createState() => _DietSelectorScreenState();
}

class _DietSelectorScreenState extends State<DietSelectorScreen> {
  final Logger _logger = Logger();
  late Future<List<MealPlan>> _fetchFuture;
  final Map<String, bool> _deactivatedDiets = {};
  final bool _isLoadingActiveDiets = false;

  @override
  void initState() {
    super.initState();
    if (DietSelectorScreen._cachedDiets != null) {
      _fetchFuture = Future.value(DietSelectorScreen._cachedDiets);
    } else {
      _fetchFuture = _fetchAllDiets().then((value) {
        DietSelectorScreen._cachedDiets = value;
        return value;
      });
    }
  }

  Future<List<MealPlan>> _fetchAllDiets() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<MealPlan> allDiets = [];

    try {
      debugPrint('Fetching all diet plans using CacheService');
      allDiets = await CacheService().getMealPlans();

      if (userProvider.isLoggedIn && userProvider.firebaseUser != null) {
        final uid = userProvider.firebaseUser!.uid;
        debugPrint('Fetching deactivation status for user: $uid');

        const batchSize = 10;
        for (var i = 0; i < allDiets.length; i += batchSize) {
          final batchIds =
              allDiets
                  .sublist(
                    i,
                    i + batchSize > allDiets.length
                        ? allDiets.length
                        : i + batchSize,
                  )
                  .map((diet) => diet.id)
                  .toList();
          final batchSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('removedDietPlans')
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();
          for (var doc in batchSnapshot.docs) {
            _deactivatedDiets[doc.id] = true;
          }
        }

        for (var diet in allDiets) {
          _deactivatedDiets.putIfAbsent(diet.id, () => false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching diet plans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load diet plans: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    return allDiets;
  }

  Future<void> _setActiveDiet(String dietPlanId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      if (mounted) {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Login Required',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  'Please log in to activate a diet plan.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: Theme.of(context).filledButtonTheme.style,
                    onPressed: () {
                      Navigator.pop(context);
                      navState?.replaceWithScreen(const LoginScreen());
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
        );
      }
      return;
    }

    try {
      debugPrint('Activating diet plan: $dietPlanId');
      final activePlanRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeDietPlans')
          .doc(dietPlanId);

      debugPrint('Fetching meal plan data for: $dietPlanId');
      final planSnapshot =
          await FirebaseFirestore.instance
              .collection('mealPlans')
              .doc(dietPlanId)
              .get();

      if (!planSnapshot.exists) {
        debugPrint('Meal plan does not exist: $dietPlanId');
        throw Exception('Meal plan not found');
      }

      debugPrint('Writing active diet plan to Firestore');
      await activePlanRef.set({
        'dietPlanId': dietPlanId,
        'startDate': DateTime.now().toIso8601String(),
        'currentDay': 1,
        'completedDays': [],
      });

      debugPrint('Removing diet plan from removedDietPlans');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('removedDietPlans')
          .doc(dietPlanId)
          .delete();

      // Invalidate the cache to force a refresh
      await CacheService().invalidateUserDietsCache(
        userProvider.firebaseUser!.uid,
      );

      // Refresh active diet plans
      final activePlans =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .collection('activeDietPlans')
              .get();

      final mappedPlans =
          activePlans.docs
              .map((doc) => ActiveDietPlan.fromMap(doc.data()))
              .toList();

      await userProvider.updateActiveDietPlans(mappedPlans);

      setState(() {
        _deactivatedDiets[dietPlanId] = false;
      });

      if (mounted) {
        debugPrint('Showing success snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diet plan added to active plans',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting active diet plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to activate diet plan: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeActiveDiet(String dietPlanId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      debugPrint('User not logged in or firebaseUser is null');
      return;
    }

    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Remove Active Diet Plan?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );

    if (!confirmed) {
      debugPrint('Removal cancelled');
      return;
    }

    try {
      debugPrint('Removing active diet plan: $dietPlanId');
      final activePlanRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeDietPlans')
          .doc(dietPlanId);

      final removedPlanRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('removedDietPlans')
          .doc(dietPlanId);

      debugPrint('Setting removed diet plan in Firestore');
      await removedPlanRef.set(
        RemovedDietPlan(
          dietPlanId: dietPlanId,
          removedDate: DateTime.now(),
          uid: userProvider.firebaseUser!.uid,
        ).toMap(),
      );

      debugPrint('Deleting active diet plan from Firestore');
      await activePlanRef.delete();

      // Invalidate the cache to force a refresh
      await CacheService().invalidateUserDietsCache(
        userProvider.firebaseUser!.uid,
      );

      // Refresh active diet plans
      final activePlans =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.firebaseUser!.uid)
              .collection('activeDietPlans')
              .get();

      final mappedPlans =
          activePlans.docs
              .map((doc) => ActiveDietPlan.fromMap(doc.data()))
              .toList();

      await userProvider.updateActiveDietPlans(mappedPlans);

      setState(() {
        _deactivatedDiets[dietPlanId] = true;
      });

      if (mounted) {
        debugPrint('Showing success snackbar for removal');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diet plan removed from active plans',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing active diet plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove active diet plan: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<Map<String, MealPlan>> _fetchMealPlans(List<String> planIds) async {
    final Map<String, MealPlan> planMap = {};
    if (planIds.isEmpty) {
      _logger.w('No plan IDs provided to fetch');
      return planMap;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      _logger.w('User not logged in, cannot fetch meal plans');
      return planMap;
    }

    try {
      _logger.d(
        'Using CacheService to fetch active diets for user: ${userProvider.firebaseUser!.uid}',
      );
      _logger.d('Active diet IDs: ${planIds.join(', ')}');

      // Force refresh to ensure we get the latest data
      final cachedDiets = await CacheService().getUserActiveDiets(
        userProvider.firebaseUser!.uid,
        userProvider.currentUser?.activeDietPlans ?? [],
        forceRefresh: true,
      );

      _logger.i('Retrieved ${cachedDiets.length} meal plans from cache');

      for (final entry in cachedDiets.entries) {
        // Skip user-specific diets if needed
        planMap[entry.key] = entry.value;
      }
    } catch (e) {
      _logger.e('Error fetching meal plans from cache: $e');
      // Fallback to direct Firestore query
      const batchSize = 10;
      for (var i = 0; i < planIds.length; i += batchSize) {
        final batchIds = planIds.sublist(
          i,
          i + batchSize > planIds.length ? planIds.length : i + batchSize,
        );

        try {
          final planSnapshot =
              await FirebaseFirestore.instance
                  .collection('mealPlans')
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();

          for (var doc in planSnapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            final mealPlan = MealPlan.fromMap(data);
            planMap[mealPlan.id] = mealPlan;
          }
        } catch (e) {
          _logger.e('Error fetching meal plans batch: $e');
        }
      }
    }

    return planMap;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            FutureBuilder<List<MealPlan>>(
              future: _fetchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading diet plans...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No diet plans found",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final allDiets = snapshot.data!;
                final Map<String, List<MealPlan>> categoryMap = {};

                // Group meal plans by category
                for (var diet in allDiets) {
                  // Skip user-specific diets
                  if (diet.userId != null && diet.userId!.isNotEmpty) {
                    continue;
                  }
                  final category = diet.type?.trim().toUpperCase() ?? 'GENERAL';
                  categoryMap.putIfAbsent(category, () => []).add(diet);
                }

                // Sort categories alphabetically
                final sortedCategories = categoryMap.keys.toList()..sort();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DIET PLANS",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (userProvider.isLoggedIn &&
                              userProvider.firebaseUser != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ACTIVE DIET PLANS",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_sweep,
                                        color: colorScheme.primary,
                                      ),
                                      tooltip: 'View Deactivated Diet Plans',
                                      onPressed: () {
                                        final navState =
                                            context
                                                .findAncestorStateOfType<
                                                  NavScreenState
                                                >();
                                        navState?.setDetailScreen(
                                          const DeactivatedDietPlansScreen(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Builder(
                                  builder: (context) {
                                    final activeDietPlans =
                                        userProvider
                                            .currentUser
                                            ?.activeDietPlans ??
                                        [];

                                    _logger.i(
                                      'User has ${activeDietPlans.length} active diet plans',
                                    );

                                    return FutureBuilder<Map<String, MealPlan>>(
                                      future: _fetchMealPlans(
                                        activeDietPlans
                                            .map((p) => p.dietPlanId)
                                            .toList(),
                                      ),
                                      builder: (context, planSnapshot) {
                                        if (planSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (planSnapshot.hasError) {
                                          _logger.e(
                                            'Error fetching active diet plans: ${planSnapshot.error}',
                                          );
                                          return Center(
                                            child: Text(
                                              'Error: ${planSnapshot.error}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                          );
                                        }
                                        final planMap = planSnapshot.data ?? {};
                                        final activeData =
                                            activeDietPlans
                                                .where(
                                                  (plan) => planMap.containsKey(
                                                    plan.dietPlanId,
                                                  ),
                                                )
                                                .map(
                                                  (plan) => {
                                                    'plan': plan,
                                                    'diet':
                                                        planMap[plan
                                                            .dietPlanId]!,
                                                  },
                                                )
                                                .toList();
                                        // If no active plans, show only the build card
                                        if (activeData.isEmpty) {
                                          return SizedBox(
                                            height: 208,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 180,
                                                  child: Card(
                                                    elevation: 4,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    color: colorScheme.surface,
                                                    child: InkWell(
                                                      onTap: () {
                                                        final navState =
                                                            context
                                                                .findAncestorStateOfType<
                                                                  NavScreenState
                                                                >();
                                                        navState?.setDetailScreen(
                                                          const WorkoutDietBuilderScreen(),
                                                        );
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_circle_outline,
                                                            size: 48,
                                                            color:
                                                                colorScheme
                                                                    .primary,
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Build More Plans',
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  color:
                                                                      colorScheme
                                                                          .primary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        // Otherwise, show all active plans plus the build card at the end
                                        return SizedBox(
                                          height: 208,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: activeData.length + 1,
                                            separatorBuilder:
                                                (_, __) =>
                                                    const SizedBox(width: 14),
                                            itemBuilder: (context, index) {
                                              if (index == activeData.length) {
                                                // Build More Plans Card always at the end
                                                return SizedBox(
                                                  width: 180,
                                                  child: Card(
                                                    elevation: 4,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    color: colorScheme.surface,
                                                    child: InkWell(
                                                      onTap: () {
                                                        final navState =
                                                            context
                                                                .findAncestorStateOfType<
                                                                  NavScreenState
                                                                >();
                                                        navState?.setDetailScreen(
                                                          const WorkoutDietBuilderScreen(),
                                                        );
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_circle_outline,
                                                            size: 48,
                                                            color:
                                                                colorScheme
                                                                    .primary,
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Build More Plans',
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  color:
                                                                      colorScheme
                                                                          .primary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              final diet =
                                                  activeData[index]['diet']
                                                      as MealPlan;
                                              final plan =
                                                  activeData[index]['plan']
                                                      as ActiveDietPlan;
                                              final int dayIndex =
                                                  (plan.currentDay - 1).clamp(
                                                    0,
                                                    diet.days.length - 1,
                                                  );
                                              final currentMealDay =
                                                  diet.days[dayIndex];

                                              return GestureDetector(
                                                onTap: () {
                                                  final navState =
                                                      context
                                                          .findAncestorStateOfType<
                                                            NavScreenState
                                                          >();
                                                  navState?.setDetailScreen(
                                                    DietDayDetailScreen(
                                                      plan: diet,
                                                      day: currentMealDay,
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: MealPlanCard(
                                                        mealPlan: diet,
                                                        currentDay:
                                                            plan.currentDay,
                                                        onDayButtonPressed: () {
                                                          final navState =
                                                              context
                                                                  .findAncestorStateOfType<
                                                                    NavScreenState
                                                                  >();
                                                          navState?.setDetailScreen(
                                                            DietDayDetailScreen(
                                                              plan: diet,
                                                              day:
                                                                  currentMealDay,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Active',
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color:
                                                                    colorScheme
                                                                        .onPrimary,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.close,
                                                          color:
                                                              colorScheme
                                                                  .primary,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            'Remove Active Diet Plan',
                                                        onPressed:
                                                            () =>
                                                                _removeActiveDiet(
                                                                  diet.id,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          // Render dynamic categories
                          for (var category in sortedCategories)
                            if (categoryMap[category]!.isNotEmpty)
                              _buildDietCategorySection(
                                theme,
                                colorScheme,
                                category,
                                categoryMap[category]!,
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isLoadingActiveDiets)
              Positioned(
                bottom: 16,
                right: 16,
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietCategorySection(
    ThemeData theme,
    ColorScheme colorScheme,
    String category,
    List<MealPlan> diets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: diets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final diet = diets[index];
              final isActive = _deactivatedDiets[diet.id] == false;

              return GestureDetector(
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  navState?.setDetailScreen(MealPlanScreen(plan: diet));
                },
                child: Stack(
                  children: [
                    SizedBox(
                      width: 180,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MealPlanCard(mealPlan: diet),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.play_circle,
                          color: colorScheme.primary,
                        ),
                        onPressed:
                            isActive ? null : () => _setActiveDiet(diet.id),
                        tooltip: 'Set as Active',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class DeactivatedDietPlansScreen extends StatelessWidget {
  const DeactivatedDietPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: AppTheme.backgroundGradient(colorScheme),
          child: const Center(
            child: Text('Please log in to view deactivated diet plans.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DEACTIVATED DIET PLANS',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () {
                        final navState =
                            context.findAncestorStateOfType<NavScreenState>();
                        navState?.clearDetailAndGoTo(2); // Navigate to Diet tab
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userProvider.firebaseUser!.uid)
                        .collection('removedDietPlans')
                        .get(GetOptions(source: Source.cache)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No deactivated diet plans found.'),
                        );
                      }

                      final deactivatedDocs = snapshot.data!.docs;
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: deactivatedDocs.length,
                        itemBuilder: (context, index) {
                          final removedPlan = RemovedDietPlan.fromMap(
                            deactivatedDocs[index].data()
                                as Map<String, dynamic>,
                          );
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('mealPlans')
                                .doc(removedPlan.dietPlanId)
                                .get(GetOptions(source: Source.cache)),
                            builder: (context, planSnapshot) {
                              if (planSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Loading...'),
                                );
                              }
                              if (planSnapshot.hasError) {
                                return ListTile(
                                  title: Text('Error: ${planSnapshot.error}'),
                                );
                              }
                              if (!planSnapshot.hasData ||
                                  !planSnapshot.data!.exists) {
                                return const ListTile(
                                  title: Text('Diet plan not found'),
                                );
                              }

                              final dietPlan = MealPlan.fromMap(
                                planSnapshot.data!.data()
                                    as Map<String, dynamic>,
                              );

                              return ListTile(
                                title: Text(
                                  dietPlan.planName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Removed on: ${removedPlan.removedDate.toString().split(' ')[0]}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                  ),
                                  onPressed: () async {
                                    try {
                                      debugPrint(
                                        'Reactivating diet plan: ${dietPlan.id}',
                                      );
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userProvider.firebaseUser!.uid)
                                          .collection('activeDietPlans')
                                          .doc(dietPlan.id)
                                          .set({
                                            'dietPlanId': dietPlan.id,
                                            'startDate':
                                                DateTime.now()
                                                    .toIso8601String(),
                                            'currentDay': 1,
                                            'completedDays': [],
                                          });

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userProvider.firebaseUser!.uid)
                                          .collection('removedDietPlans')
                                          .doc(dietPlan.id)
                                          .delete();

                                      // Invalidate cache
                                      await CacheService()
                                          .invalidateUserDietsCache(
                                            userProvider.firebaseUser!.uid,
                                          );

                                      // Refresh active diet plans
                                      final activePlans =
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(
                                                userProvider.firebaseUser!.uid,
                                              )
                                              .collection('activeDietPlans')
                                              .get();

                                      final mappedPlans =
                                          activePlans.docs
                                              .map(
                                                (doc) => ActiveDietPlan.fromMap(
                                                  doc.data(),
                                                ),
                                              )
                                              .toList();

                                      await userProvider.updateActiveDietPlans(
                                        mappedPlans,
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Diet plan reactivated',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                            backgroundColor:
                                                colorScheme.primary,
                                          ),
                                        );
                                        final navState =
                                            context
                                                .findAncestorStateOfType<
                                                  NavScreenState
                                                >();
                                        navState?.clearDetailAndGoTo(
                                          2,
                                        ); // Navigate to Diet tab
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        'Error reactivating diet plan: $e',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to reactivate diet plan: $e',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onError,
                                              ),
                                            ),
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Reactivate'),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
