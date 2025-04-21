import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/app_user.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import '../nav_screen.dart';
import 'meal_plan_screen.dart';

class ReplaceMealScreen extends StatefulWidget {
  final String mealId;
  final String mealType;
  final int dayNumber;
  final MealPlan plan;

  const ReplaceMealScreen({
    super.key,
    required this.mealId,
    required this.mealType,
    required this.dayNumber,
    required this.plan,
  });

  static List<Meal>? _cachedAllMeals;
  static final Map<String, List<Meal>> _cachedRecommendedMeals = {};

  @override
  State<ReplaceMealScreen> createState() => _ReplaceMealScreenState();
}

class _ReplaceMealScreenState extends State<ReplaceMealScreen> {
  List<Meal> _recommendedMeals = [];
  List<Meal> _allMeals = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isBrowsingAll = false;

  @override
  void initState() {
    super.initState();
    if (ReplaceMealScreen._cachedAllMeals != null &&
        ReplaceMealScreen._cachedRecommendedMeals.containsKey(widget.mealId)) {
      _allMeals = ReplaceMealScreen._cachedAllMeals!;
      _recommendedMeals =
          ReplaceMealScreen._cachedRecommendedMeals[widget.mealId]!;
      _isLoading = false;
      setState(() {});
    } else {
      _fetchMeals();
    }
  }

  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Fetching meals for mealId: ${widget.mealId}');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentMealDoc =
          await FirebaseFirestore.instance
              .collection('meals')
              .doc(widget.mealId)
              .get();
      if (!currentMealDoc.exists) {
        throw Exception('Current meal not found: ${widget.mealId}');
      }
      final currentMeal = Meal.fromMap(currentMealDoc.data()!);

      final snapshot =
          await FirebaseFirestore.instance.collection('meals').get();
      final allMeals =
          snapshot.docs
              .map((doc) => Meal.fromMap(doc.data()..['id'] = doc.id))
              .toList();

      final recommended = _rankMeals(
        allMeals,
        currentMeal,
        userProvider.currentUser,
      );

      if (mounted) {
        setState(() {
          _allMeals = allMeals;
          _recommendedMeals = recommended.take(5).toList();
          _isLoading = false;
        });
        ReplaceMealScreen._cachedAllMeals = allMeals;
        ReplaceMealScreen._cachedRecommendedMeals[widget.mealId] =
            recommended.take(5).toList();
      }
    } catch (e) {
      debugPrint('Fetch meals error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load meals: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Meal> _rankMeals(List<Meal> meals, Meal current, AppUser? user) {
    final scoredMeals =
        meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;
          double score = 0.0;

          if (meal.category == current.category) score += 0.4;
          if (user != null && meal.diets.contains(user.dietPreference)) {
            score += 0.3;
          }
          if ((meal.calories - current.calories).abs() < 100) {
            score += 0.2;
          }
          if (user != null &&
              meal.allergies.every(
                (allergy) => !user.allergies.contains(allergy),
              ) &&
              meal.allergies.every(
                (allergy) => !user.dietaryRestrictions.contains(allergy),
              )) {
            score += 0.1;
          }

          if (user != null &&
              meal.allergies.any(
                (allergy) =>
                    user.allergies.contains(allergy) ||
                    user.dietaryRestrictions.contains(allergy),
              )) {
            score = 0.0;
          }

          return {'index': index, 'score': score, 'meal': meal};
        }).toList();

    scoredMeals.sort((a, b) {
      final scoreA = a['score'] as double? ?? 0.0;
      final scoreB = b['score'] as double? ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return scoredMeals
        .where((item) => (item['score'] as double? ?? 0.0) > 0)
        .map((item) => item['meal'] as Meal)
        .toList();
  }

  Future<Map<String, dynamic>> _replaceMeal(
    String? newMealId,
    bool applyToAllDays,
  ) async {
    if (_isLoading) {
      debugPrint('ReplaceMeal: Skipped due to ongoing operation');
      return {'success': false, 'planId': widget.plan.id};
    }

    setState(() => _isLoading = true);
    try {
      debugPrint(
        'Starting replaceMeal with newMealId: $newMealId, original mealId: ${widget.mealId}, applyToAllDays: $applyToAllDays',
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final firebaseAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (!userProvider.isLoggedIn ||
          userProvider.firebaseUser == null ||
          firebaseAuthUser == null) {
        debugPrint(
          'ReplaceMeal: Authentication invalid, isLoggedIn: ${userProvider.isLoggedIn}',
        );
        throw Exception('Please log in to make changes');
      }
      final currentUid = firebaseAuthUser.uid;
      debugPrint('Current user UID: $currentUid');

      if (widget.mealId.isEmpty) {
        throw Exception('Invalid original meal ID: ${widget.mealId}');
      }
      if (newMealId != null && newMealId.isEmpty) {
        throw Exception('Invalid new meal ID: $newMealId');
      }

      if (newMealId != null) {
        debugPrint('Validating new meal ID: $newMealId');
        final newMealDoc =
            await FirebaseFirestore.instance
                .collection('meals')
                .doc(newMealId)
                .get();
        if (!newMealDoc.exists) {
          throw Exception('New meal not found: $newMealId');
        }
      }

      debugPrint('Validating meal plan ID: ${widget.plan.id}');
      final planRef = FirebaseFirestore.instance
          .collection('mealPlans')
          .doc(widget.plan.id);
      final planDoc = await planRef.get();
      if (!planDoc.exists) {
        throw Exception('Meal plan not found: ${widget.plan.id}');
      }

      final planData = planDoc.data()!;
      final rawDays = planData['days'] ?? [];
      if (rawDays is! List) {
        throw Exception(
          'Invalid days format: Expected List, got ${rawDays.runtimeType}',
        );
      }

      final planUserId = planData['userId'] as String?;
      debugPrint(
        'Checking permissions: planUserId=$planUserId, currentUid=$currentUid',
      );
      if (planUserId != null && planUserId != currentUid) {
        debugPrint(
          'Permission denied: plan userId ($planUserId) does not match current user ($currentUid)',
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'You do not have permission to modify this plan',
        );
      }

      final days =
          rawDays
              .asMap()
              .map(
                (index, day) => MapEntry(
                  index,
                  MealDay.fromMap(Map<String, dynamic>.from(day)).swapMeal(
                    widget.mealType,
                    Meal(
                      id: '',
                      name: '',
                      image: '',
                      ingredients: [],
                      instructions: [],
                      diets: [],
                      category: '',
                      allergies: [],
                      prepTime: 0,
                    ),
                    1.0,
                  ),
                ),
              )
              .values
              .toList();

      if (newMealId != null) {
        final newMealDoc =
            await FirebaseFirestore.instance
                .collection('meals')
                .doc(newMealId)
                .get();
        final newMeal = Meal.fromMap(newMealDoc.data()!);

        if (applyToAllDays) {
          for (var i = 0; i < days.length; i++) {
            days[i] = days[i].swapMeal(widget.mealType, newMeal, 1.0);
          }
        } else {
          final dayIndex = days.indexWhere(
            (day) => day.dayNumber == widget.dayNumber,
          );
          if (dayIndex != -1) {
            days[dayIndex] = days[dayIndex].swapMeal(
              widget.mealType,
              newMeal,
              1.0,
            );
          }
        }
      } else {
        if (applyToAllDays) {
          for (var i = 0; i < days.length; i++) {
            days[i] = days[i].swapMeal(
              widget.mealType,
              Meal(
                id: '',
                name: '',
                image: '',
                ingredients: [],
                instructions: [],
                diets: [],
                category: '',
                allergies: [],
                prepTime: 0,
              ),
              1.0,
            );
          }
        } else {
          final dayIndex = days.indexWhere(
            (day) => day.dayNumber == widget.dayNumber,
          );
          if (dayIndex != -1) {
            days[dayIndex] = days[dayIndex].swapMeal(
              widget.mealType,
              Meal(
                id: '',
                name: '',
                image: '',
                ingredients: [],
                instructions: [],
                diets: [],
                category: '',
                allergies: [],
                prepTime: 0,
              ),
              1.0,
            );
          }
        }
      }

      String finalPlanId = widget.plan.id;
      bool writeSuccess = false;
      try {
        if (planUserId == null) {
          debugPrint('Attempting to update existing plan: $finalPlanId');
          await planRef.update({
            'days': days.map((day) => day.toMap()).toList(),
          });
          debugPrint('Updated existing plan: $finalPlanId');
          writeSuccess = true;
        } else {
          debugPrint('Updating owned plan: $finalPlanId');
          await planRef.update({
            'days': days.map((day) => day.toMap()).toList(),
          });
          debugPrint('Updated existing plan: $finalPlanId');
          writeSuccess = true;
        }
      } catch (e) {
        debugPrint('Initial Firestore write error: $e');
        if (e is FirebaseException &&
            e.code == 'permission-denied' &&
            planUserId == null) {
          debugPrint(
            'Falling back to create new plan due to permissions error',
          );
          final newPlanRef =
              FirebaseFirestore.instance.collection('mealPlans').doc();
          try {
            await newPlanRef.set({
              ...planData,
              'userId': currentUid,
              'days': days.map((day) => day.toMap()).toList(),
            });
            finalPlanId = newPlanRef.id;
            debugPrint('Created new plan as fallback: $finalPlanId');
            writeSuccess = true;
          } catch (fallbackError) {
            debugPrint('Fallback Firestore write error: $fallbackError');
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Failed to create new plan: $fallbackError',
            );
          }
        } else {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Failed to write plan: $e',
          );
        }
      }

      if (writeSuccess) {
        debugPrint('Checking if plan is active: $finalPlanId');
        final activePlanRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('activeDietPlans')
            .doc(finalPlanId);
        final activeDoc = await activePlanRef.get();

        if (!activeDoc.exists) {
          debugPrint('Plan is not active, setting as active: $finalPlanId');
          try {
            await activePlanRef.set({
              'dietPlanId': finalPlanId,
              'startDate': DateTime.now().toIso8601String(),
              'currentDay': 1,
              'completedDays': [],
            });
            debugPrint('Set active plan: $finalPlanId');
          } catch (e) {
            debugPrint('Active plan write error: $e');
          }
        } else {
          debugPrint(
            'Plan is already active, updating active plan: $finalPlanId',
          );
          final activeData = activeDoc.data();
          if (activeData != null) {
            try {
              await activePlanRef.update({
                'days': days.map((day) => day.toMap()).toList(),
              });
              debugPrint('Updated active plan with new days: $finalPlanId');
            } catch (e) {
              debugPrint('Error updating active plan days: $e');
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newMealId == null
                  ? 'Meal removed successfully'
                  : 'Meal replaced successfully',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.replaceWithScreen(
            MealPlanScreen(
              plan: MealPlan(
                id: finalPlanId,
                planName: widget.plan.planName,
                description: widget.plan.description,
                days: days,
                userId: userProvider.firebaseUser?.uid,
                type: widget.plan.type,
              ),
            ),
          );
          debugPrint('Navigated to MealPlanScreen after replace/remove');
        }
      }

      return {'success': true, 'planId': finalPlanId, 'days': days};
    } catch (e) {
      debugPrint('ReplaceMeal error: $e');
      String errorMessage;
      if (e is FirebaseException && e.code == 'permission-denied') {
        errorMessage =
            'Unable to save changes due to permissions. A new plan has been created for you.';
      } else {
        errorMessage = 'Failed to update meal plan: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return {'success': false, 'planId': widget.plan.id};
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _confirmRemoval() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Remove Meal?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Are you sure you want to remove this meal?',
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
                style: Theme.of(context).filledButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error,
                  ),
                ),
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
    );
    return confirmed;
  }

  Future<Map<String, dynamic>> _confirmApplyToAll() async {
    bool applyToAll = false;
    bool confirmed = false;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Replace Meal Scope',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Do you want to replace this meal for Day ${widget.dayNumber} only or across all days?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<bool>(
                        title: Text(
                          'This day only (Day ${widget.dayNumber})',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: false,
                        groupValue: applyToAll,
                        onChanged:
                            (value) =>
                                setDialogState(() => applyToAll = value!),
                        activeColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      RadioListTile<bool>(
                        title: Text(
                          'All days',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: true,
                        groupValue: applyToAll,
                        onChanged:
                            (value) =>
                                setDialogState(() => applyToAll = value!),
                        activeColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
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
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: Text(
                  'Replace',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
    return {'confirmed': confirmed, 'applyToAll': applyToAll};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    debugPrint(
      'UserProvider state: isLoggedIn=${userProvider.isLoggedIn}, uid=${userProvider.firebaseUser?.uid}',
    );
    final filteredMeals =
        _allMeals.where((meal) {
          if (_searchQuery.isEmpty) return true;
          return meal.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
                : SingleChildScrollView(
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
                            'REPLACE MEAL',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: colorScheme.error,
                                  size: 28,
                                ),
                                tooltip: 'Remove Meal',
                                padding: const EdgeInsets.all(8),
                                onPressed: () async {
                                  final confirmed = await _confirmRemoval();
                                  if (confirmed && mounted) {
                                    await _replaceMeal(null, false);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                tooltip: 'Browse All Meals',
                                padding: const EdgeInsets.all(8),
                                onPressed:
                                    () => setState(
                                      () => _isBrowsingAll = !_isBrowsingAll,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isBrowsingAll
                                ? 'All Meals'
                                : 'Recommended Replacements',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isBrowsingAll) ...[
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Search meals',
                                labelStyle: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged:
                                  (value) =>
                                      setState(() => _searchQuery = value),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ...(_isBrowsingAll ? filteredMeals : _recommendedMeals).map(
                            (meal) => AppTheme.animatedCard(
                              child: GestureDetector(
                                onTap: () async {
                                  if (meal.id.isNotEmpty) {
                                    debugPrint(
                                      'Tapped meal: ${meal.id}, name: ${meal.name}',
                                    );
                                    final result = await _confirmApplyToAll();
                                    if (result['confirmed'] && mounted) {
                                      final replaceResult = await _replaceMeal(
                                        meal.id,
                                        result['applyToAll'],
                                      );
                                      if (replaceResult['success'] && mounted) {
                                        // Navigation handled in _replaceMeal
                                      }
                                    }
                                  } else {
                                    debugPrint('Invalid meal ID: ${meal.id}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Cannot replace with invalid meal',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onError,
                                          ),
                                        ),
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child:
                                              meal.image.isNotEmpty
                                                  ? Image.network(
                                                    meal.image,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Container(
                                                          width: 100,
                                                          height: 100,
                                                          color:
                                                              colorScheme
                                                                  .surfaceContainer,
                                                          child: Icon(
                                                            Icons.fastfood,
                                                            color:
                                                                colorScheme
                                                                    .onSurfaceVariant,
                                                          ),
                                                        ),
                                                  )
                                                  : Container(
                                                    width: 100,
                                                    height: 100,
                                                    color:
                                                        colorScheme
                                                            .surfaceContainer,
                                                    child: Icon(
                                                      Icons.fastfood,
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                meal.name,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.onSurface,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                meal.diets.join(', '),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                              Text(
                                                'Calories: ${meal.calories.round()} kcal',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                              Text(
                                                'Category: ${meal.category}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
