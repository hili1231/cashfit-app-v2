import 'package:cashfit/screens/diets/replace_meal_plan.dart';
import 'package:cashfit/theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_day.dart';
import '../../models/meal_portion.dart';
import '../../providers/user_provider.dart';
import '../diets/replace_meal_context_provider.dart';
import '../nav_screen.dart';
import 'diet_day_detail_screen.dart';
import 'meal_detail_screen.dart';

class MealPlanScreen extends StatelessWidget {
  final MealPlan plan;

  const MealPlanScreen({super.key, required this.plan});

  Future<Map<String, dynamic>> _fetchAllData(
    String userId,
    List<MealDay> sortedDays,
  ) async {
    // Fetch daily calorie goal (or use a default)
    final calorieGoalFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((doc) {
          return doc.exists
              ? (doc.data()!['dailyCalorieGoal'] as int? ?? 2000)
              : 2000;
        });

    // Fetch completed days for this meal plan
    final completedDaysFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('activeDietPlans')
        .doc(plan.id)
        .get()
        .then((doc) {
          if (doc.exists && doc.data()!.containsKey('completedDays')) {
            return List<int>.from(doc['completedDays'] as List<dynamic>);
          }
          return <int>[];
        });

    final results = await Future.wait([calorieGoalFuture, completedDaysFuture]);

    final calorieGoal = results[0] as int;
    final completedDays = results[1] as List<int>;

    return {'calorieGoal': calorieGoal, 'completedDays': completedDays};
  }

  void _handleReplace(
    BuildContext context,
    String mealId,
    String mealType,
    int dayNumber,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();
    final replaceContext = Provider.of<ReplaceMealContextProvider>(
      context,
      listen: false,
    );

    if (!userProvider.isLoggedIn) {
      showDialog(
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
                'Please log in to replace meals.',
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
                    replaceContext.setContext(
                      mealId: mealId,
                      mealType: mealType,
                      dayNumber: dayNumber,
                      originatingScreen: OriginatingScreen.mealPlan,
                      mealPlanId: plan.id,
                    );
                    Navigator.pop(context);
                    navState?.setDetailScreen(const LoginScreen());
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
    } else {
      replaceContext.setContext(
        mealId: mealId,
        mealType: mealType,
        dayNumber: dayNumber,
        originatingScreen: OriginatingScreen.mealPlan,
        mealPlanId: plan.id,
      );
      navState?.setDetailScreen(
        ReplaceMealScreen(
          mealId: mealId,
          mealType: mealType,
          dayNumber: dayNumber,
          plan: plan,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.firebaseUser?.uid ?? 'currentUserId';

    final sortedDays =
        plan.days.toList()..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchAllData(userId, sortedDays),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading data",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final data = snapshot.data!;
              final calorieGoal = data['calorieGoal'] as int;
              final completedDays = data['completedDays'] as List<int>;

              // Sort days: uncompleted days first, completed days at the bottom
              final uncompletedDays = <MealDay>[];
              final completedDaysList = <MealDay>[];
              for (var day in sortedDays) {
                if (completedDays.contains(day.dayNumber)) {
                  completedDaysList.add(day);
                } else {
                  uncompletedDays.add(day);
                }
              }
              final reorderedDays = [...uncompletedDays, ...completedDaysList];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.planName.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPlanImage(colorScheme),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plan.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...reorderedDays.map((day) {
                        final meals =
                            [
                              {'type': 'Breakfast', 'portion': day.breakfast},
                              {'type': 'Snack 1', 'portion': day.snack1},
                              {'type': 'Lunch', 'portion': day.lunch},
                              {'type': 'Snack 2', 'portion': day.snack2},
                              {'type': 'Dinner', 'portion': day.dinner},
                              {'type': 'Snack 3', 'portion': day.snack3},
                            ].where((m) => m['portion'] != null).toList();
                        final isCompleted = completedDays.contains(
                          day.dayNumber,
                        );
                        return _buildDaySection(
                          context,
                          theme,
                          colorScheme,
                          day,
                          meals,
                          calorieGoal,
                          isCompleted,
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlanImage(ColorScheme colorScheme) {
    final imageUrl = _getPlanImage();
    return CachedNetworkImage(
      imageUrl:
          imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.jpg',
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      placeholder:
          (context, url) =>
              _buildPlaceholderImage(colorScheme: colorScheme, height: 220),
      errorWidget:
          (context, url, error) =>
              _buildPlaceholderImage(colorScheme: colorScheme, height: 220),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  String _getPlanImage() {
    try {
      final mealImage =
          plan.days
              .firstWhere((d) => d.breakfast != null)
              .breakfast
              ?.meal
              .image ??
          '';
      return mealImage;
    } catch (_) {
      return '';
    }
  }

  Widget _buildDaySection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    MealDay day,
    List<Map<String, dynamic>> meals,
    int calorieGoal,
    bool isCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Day ${day.dayNumber}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color:
                              isCompleted
                                  ? colorScheme.onSurface.withAlpha(
                                    (255 * 0.6).round(),
                                  )
                                  : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      final navState =
                          context.findAncestorStateOfType<NavScreenState>();
                      navState?.setDetailScreen(
                        DietDayDetailScreen(plan: plan, day: day),
                      );
                    },
                    child: Text(
                      "VIEW DAY",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCalorieGoalCard(
                theme,
                colorScheme,
                day.dayNumber,
                calorieGoal,
                isCompleted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child:
              day.isFasting
                  ? _buildFastingDayMessage(theme, colorScheme)
                  : meals.isEmpty
                  ? Center(
                    child: Text(
                      "No meals available",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: meals.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final mealConfig = meals[index];
                      final mealPortion = mealConfig['portion'] as MealPortion;
                      final mealType = mealConfig['type'] as String;
                      return _buildMealCard(
                        context,
                        theme,
                        colorScheme,
                        mealPortion,
                        mealType,
                        day.dayNumber,
                        isCompleted,
                      );
                    },
                  ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCalorieGoalCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int dayNumber,
    int calorieGoal,
    bool isCompleted,
  ) {
    return Card(
      elevation: 1,
      color:
          isCompleted
              ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
              : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_dining,
              color:
                  isCompleted
                      ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                      : colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Calories: $calorieGoal",
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isCompleted
                        ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                        : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingDayMessage(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_food, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            "Fasting Day: Hydrate and Rest!",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    MealPortion mealPortion,
    String mealType,
    int dayNumber,
    bool isCompleted,
  ) {
    final meal = mealPortion.meal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        navState?.setDetailScreen(
          MealDetailScreen(
            plan: plan,
            day: plan.days.firstWhere((d) => d.dayNumber == dayNumber),
            meal: meal,
          ),
        );
      },
      child: Card(
        color:
            isCompleted
                ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
                : colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Stack(
          children: [
            SizedBox(
              width: 180,
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          meal.image.isNotEmpty
                              ? meal.image
                              : 'assets/images/placeholder.jpg',
                      width: 180,
                      height: 110,
                      fit: BoxFit.cover,
                      color: isCompleted ? Colors.grey : null,
                      colorBlendMode: isCompleted ? BlendMode.saturation : null,
                      placeholder:
                          (context, url) => _buildPlaceholderImage(
                            colorScheme: colorScheme,
                            height: 110,
                          ),
                      errorWidget:
                          (context, url, error) => _buildPlaceholderImage(
                            colorScheme: colorScheme,
                            height: 110,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  isCompleted
                                      ? colorScheme.onSurface.withAlpha(
                                        (255 * 0.6).round(),
                                      )
                                      : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(meal.calories * mealPortion.portionMultiplier).round()} kcal",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isCompleted
                                      ? colorScheme.onSurface.withAlpha(
                                        (255 * 0.6).round(),
                                      )
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Tooltip(
                message: 'Replace Meal',
                child: IconButton(
                  icon: Icon(
                    Icons.swap_horiz,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed:
                      () =>
                          _handleReplace(context, meal.id, mealType, dayNumber),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage({
    required ColorScheme colorScheme,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood,
        size: 40,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
