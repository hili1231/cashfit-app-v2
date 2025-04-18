import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/workout_program.dart';
import '../screens/workouts/workout_detail_screen.dart';
import '../screens/nav_screen.dart';
import '../theme.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutProgram workout;
  final int? currentDay; // Optional current day for active workouts
  final VoidCallback? onDayButtonPressed; // Callback for day button action

  const WorkoutCard({
    super.key,
    required this.workout,
    this.currentDay,
    this.onDayButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = workout.days.length;

    return AnimatedCard(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 180,
        height: 240,
        child: GestureDetector(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            navState?.setDetailScreen(WorkoutDetailScreen(workout: workout));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: _buildWorkoutImage(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  workout.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "$totalDays days",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: FilledButton(
                  onPressed:
                      onDayButtonPressed ??
                      () {
                        final navState =
                            context.findAncestorStateOfType<NavScreenState>();
                        navState?.setDetailScreen(
                          WorkoutDetailScreen(workout: workout),
                        );
                      },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    currentDay != null ? "Day $currentDay" : "View Workout",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = workout.image.trim();

    if (imageUrl.isEmpty) {
      return Container(
        height: 80,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fitness_center, size: 40, color: colorScheme.primary),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 80,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder:
          (context, url) => Container(
            height: 80,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            height: 80,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
      memCacheWidth: 320,
      maxWidthDiskCache: 320,
    );
  }
}
