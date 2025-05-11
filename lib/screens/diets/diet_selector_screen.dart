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

class DietSelectorScreen extends StatefulWidget {
  const DietSelectorScreen({super.key});

  static List<MealPlan>? _cachedDiets;

  @override
  State<DietSelectorScreen> createState() => _DietSelectorScreenState();
}

class _DietSelectorScreenState extends State<DietSelectorScreen> {
  late Future<List<MealPlan>> _fetchFuture;
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
    List<MealPlan> allDiets = [];

    try {
      debugPrint('Fetching all diet plans using CacheService');
      // Use the cache service to retrieve meal plans
      allDiets = await CacheService().getMealPlans();
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
      await CacheService().invalidateUserDietsCache(userProvider.firebaseUser!.uid);
      
      // Optimized approach - only fetch and update active diet plans
      final activePlans = await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeDietPlans')
          .get();
          
      final mappedPlans = activePlans.docs
          .map((doc) => ActiveDietPlan.fromMap(doc.data()))
          .toList();
          
      // Update just the active diet plans instead of refreshing all user data
      await userProvider.updateActiveDietPlans(mappedPlans);

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
      await CacheService().invalidateUserDietsCache(userProvider.firebaseUser!.uid);
      
      // Optimized approach - only fetch and update active diet plans
      final activePlans = await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.firebaseUser!.uid)
          .collection('activeDietPlans')
          .get();
          
      final mappedPlans = activePlans.docs
          .map((doc) => ActiveDietPlan.fromMap(doc.data()))
          .toList();
          
      // Update just the active diet plans instead of refreshing all user data
      await userProvider.updateActiveDietPlans(mappedPlans);

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
    if (planIds.isEmpty) return planMap;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.firebaseUser == null) {
      return planMap;
    }
    
    // Use CacheService to get active diet plans for the user
    final activeDietPlans = userProvider.currentUser?.activeDietPlans ?? [];
    
    final cachedDiets = await CacheService().getUserActiveDiets(
      userProvider.firebaseUser!.uid,
      activeDietPlans
    );
    
    return cachedDiets;
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
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            userProvider.isLoggedIn &&
                                    userProvider.firebaseUser != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userProvider.firebaseUser!.uid)
                                    .collection('activeDietPlans')
                                    .snapshots()
                                : null,
                        builder: (context, snapshot) {
                          final activeIds =
                              snapshot.hasData
                                  ? snapshot.data!.docs
                                      .map((doc) => doc.id)
                                      .toSet()
                                  : <String>{};

                          // Group meal plans by category
                          final categoryMap = <String, List<MealPlan>>{};
                          for (var diet in allDiets) {
                            if (!activeIds.contains(diet.id)) {
                              final category =
                                  diet.type?.trim().isNotEmpty == true
                                      ? diet.type!
                                      : 'General';
                              categoryMap
                                  .putIfAbsent(category, () => [])
                                  .add(diet);
                            }
                          }

                          // Sort categories alphabetically, with "General" last
                          final sortedCategories =
                              categoryMap.keys
                                  .toList()
                                  .where((cat) => cat != 'General')
                                  .toList()
                                ..sort()
                                ..addAll(
                                  categoryMap.keys.where(
                                    (cat) => cat == 'General',
                                  ),
                                );

                          return Column(
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
                                          "Your Active Diet Plans",
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_sweep,
                                            color: colorScheme.primary,
                                          ),
                                          tooltip:
                                              'View Deactivated Diet Plans',
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
                                    if (snapshot.hasError)
                                      Center(
                                        child: Text(
                                          'Error: ${snapshot.error}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      )
                                    else if (snapshot.connectionState ==
                                        ConnectionState.waiting)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    else if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty)
                                      Center(
                                        child: Text(
                                          "No active diet plans",
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      )
                                    else
                                      FutureBuilder<Map<String, MealPlan>>(
                                        future: _fetchMealPlans(
                                          activeIds.toList(),
                                        ),
                                        builder: (context, planSnapshot) {
                                          if (planSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          if (planSnapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error: ${planSnapshot.error}',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                            );
                                          }
                                          if (!planSnapshot.hasData ||
                                              planSnapshot.data!.isEmpty) {
                                            return Center(
                                              child: Text(
                                                "No active diet plans found",
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                            );
                                          }

                                          final planMap = planSnapshot.data!;
                                          final activeData =
                                              activeIds
                                                  .where(
                                                    (id) =>
                                                        planMap.containsKey(id),
                                                  )
                                                  .map(
                                                    (id) => {
                                                      'plan': ActiveDietPlan(
                                                        dietPlanId: id, // Added the missing dietPlanId argument
                                                        startDate: DateTime.now(),
                                                        currentDay: 1,
                                                      ),
                                                      'diet': planMap[id]!,
                                                    },
                                                  )
                                                  .toList();

                                          if (activeData.isEmpty) {
                                            return Center(
                                              child: Text(
                                                "No active diet plans found",
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                            );
                                          }

                                          return SizedBox(
                                            height: 200,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: activeData.length,
                                              separatorBuilder:
                                                  (_, __) =>
                                                      const SizedBox(width: 14),
                                              itemBuilder: (context, index) {
                                                final diet =
                                                    activeData[index]['diet']
                                                        as MealPlan;
                                                return GestureDetector(
                                                  onTap: () {
                                                    final navState =
                                                        context
                                                            .findAncestorStateOfType<
                                                              NavScreenState
                                                            >();
                                                    navState?.setDetailScreen(
                                                      MealPlanScreen(
                                                        plan: diet,
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
                          );
                        },
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
          category,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            itemCount: diets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final diet = diets[index];
              return GestureDetector(
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  navState?.setDetailScreen(MealPlanScreen(plan: diet));
                },
                child: Stack(
                  children: [
                    MealPlanCard(mealPlan: diet),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.play_circle,
                          color: colorScheme.primary,
                        ),
                        onPressed: () => _setActiveDiet(diet.id),
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
                        physics: BouncingScrollPhysics(),
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
