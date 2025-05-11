import 'package:cashfit/auth/login_screen.dart';
import 'package:cashfit/screens/diets/diet_plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/meal_day.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_portion.dart';
import '../../providers/user_provider.dart';
import '../../widgets/calorie_tracker_widget.dart';
import '../nav_screen.dart';
import 'meal_detail_screen.dart';
import 'replace_meal_screen.dart';

enum DayStatus { notDone, doneToday, doneEarlier }

class DietDayDetailScreen extends StatefulWidget {
  final MealPlan plan;
  final MealDay day;

  const DietDayDetailScreen({super.key, required this.plan, required this.day});

  @override
  State<DietDayDetailScreen> createState() => _DietDayDetailScreenState();
}

class _DietDayDetailScreenState extends State<DietDayDetailScreen> {
  late MealDay _cachedDay;
  late MealPlan _cachedPlan;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cachedDay = widget.day;
    _cachedPlan = widget.plan;
  }

  void _handleReplace(BuildContext context, String mealId, String mealType) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navState = context.findAncestorStateOfType<NavScreenState>();

    if (!userProvider.isLoggedIn) {
      if (mounted) {
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
      }
    } else {
      navState?.setDetailScreen(
        ReplaceMealScreen(
          mealId: mealId,
          mealType: mealType,
          dayNumber: widget.day.dayNumber,
          plan: widget.plan,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.firebaseUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Please log in to view this page.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<ActiveDietPlan?>(
      stream: context.read<DietPlanRepository>().streamActivePlan(
        userId,
        widget.plan.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading diet plan: ${snapshot.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: Text(
                      'Retry',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activePlan = snapshot.data;
        final isPlanActive = activePlan != null;
        final completedDays = activePlan?.completedDays ?? [];
        final isDayCompletedToday =
            completedDays.contains(widget.day.dayNumber) &&
            activePlan?.lastCompletion != null &&
            DateUtils.isSameDay(activePlan!.lastCompletion, DateTime.now());
        final dayStatus =
            isDayCompletedToday
                ? DayStatus.doneToday
                : completedDays.contains(widget.day.dayNumber)
                ? DayStatus.doneEarlier
                : DayStatus.notDone;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAY ${_cachedDay.dayNumber}'.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                const CalorieTrackerWidget(),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ..._buildMealsList(context, theme, colorScheme),
                if (_buildMealsList(context, theme, colorScheme).isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: DayCompletionButton(
                      status: dayStatus,
                      isLoading: _isLoading,
                      onPressed:
                          (markDone) => _toggleDayCompleted(
                            context,
                            isPlanActive ? markDone : true,
                          ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleDayCompleted(BuildContext context, bool markDone) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final repo = context.read<DietPlanRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = userProvider.firebaseUser!.uid;
      await repo.setActiveDietPlan(
        userId,
        widget.plan.id,
        widget.day.dayNumber,
      );

      await repo.toggleDayCompleted(
        userId,
        widget.plan.id,
        widget.day.dayNumber,
        markDone,
        widget.plan.days.length,
      );

      await userProvider.loadUserData(userId, silent: true);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.primary,
            content: Text(
              markDone
                  ? "Meal day completed! Return to Earn Points to claim your reward."
                  : "Meal day completion undone.",
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to ${markDone ? 'complete' : 'undo'} meal day: $e';
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              'Error: $e',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Widget> _buildMealsList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final meals = [
      {"portion": _cachedDay.breakfast, "type": "Breakfast"},
      {"portion": _cachedDay.snack1, "type": "Snack1"},
      {"portion": _cachedDay.lunch, "type": "Lunch"},
      {"portion": _cachedDay.snack2, "type": "Snack2"},
      {"portion": _cachedDay.dinner, "type": "Dinner"},
      {"portion": _cachedDay.snack3, "type": "Snack3"},
    ];

    return meals.where((m) => m['portion'] != null).map((obj) {
      final portion = obj["portion"] as MealPortion;
      final type = obj["type"] as String;
      return _buildMealCard(context, portion, type, theme, colorScheme);
    }).toList();
  }

  Widget _buildMealCard(
    BuildContext context,
    MealPortion portion,
    String mealType,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final meal = portion.meal;

    return Card(
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToMealDetail(context, meal),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    meal.image.isNotEmpty
                        ? meal.image
                        : 'assets/images/placeholder.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => _buildPlaceholderImage(200, colorScheme),
                errorWidget:
                    (context, url, error) =>
                        _buildPlaceholderImage(200, colorScheme),
                fadeInDuration: const Duration(milliseconds: 200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${meal.calories.round()} Cal",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      onPressed:
                          () => _handleReplace(context, meal.id, mealType),
                      child: const Text('Replace Meal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMealDetail(BuildContext context, Meal meal) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    if (navState != null) {
      navState.setDetailScreen(
        MealDetailScreen(plan: _cachedPlan, day: _cachedDay, meal: meal),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => MealDetailScreen(
                plan: _cachedPlan,
                day: _cachedDay,
                meal: meal,
              ),
        ),
      );
    }
  }

  Widget _buildPlaceholderImage(double size, ColorScheme colorScheme) {
    return Container(
      height: size,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood,
        size: 30,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class DayCompletionButton extends StatelessWidget {
  final DayStatus status;
  final bool isLoading;
  final void Function(bool markDone)? onPressed;

  const DayCompletionButton({
    super.key,
    required this.status,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDone = status != DayStatus.notDone;
    final buttonText = isDone ? "Undo Completion" : "Meal Day Completed";
    final buttonColor =
        isDone
            ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
            : colorScheme.primary;
    final textColor =
        isDone
            ? colorScheme.onSurface.withAlpha((255 * 0.6).round())
            : colorScheme.onPrimary;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: isLoading ? null : () => onPressed?.call(!isDone),
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
              : Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
    );
  }
}
