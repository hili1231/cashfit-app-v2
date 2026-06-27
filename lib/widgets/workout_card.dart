import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/workout_program.dart';
import '../screens/workouts/workout_detail_screen.dart';
import '../screens/nav_screen.dart';
import '../theme.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutProgram workout;
  final int? currentDay;
  final VoidCallback? onDayButtonPressed;

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
      child: Container(
        width: 190,
        height: 240,
        decoration: AppTheme.glassCardDecoration(colorScheme),
        child: GestureDetector(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            navState?.setDetailScreen(WorkoutDetailScreen(workout: workout));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _buildWorkoutImage(context),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: colorScheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "$totalDays Days",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(
                  workout.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDayButtonPressed ??
                        () {
                          final navState = context.findAncestorStateOfType<NavScreenState>();
                          navState?.setDetailScreen(WorkoutDetailScreen(workout: workout));
                        },
                    child: Text(
                      currentDay != null ? "Day $currentDay" : "View Program",
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

    final validUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80';

    return CachedNetworkImage(
      imageUrl: validUrl,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        height: 100,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fitness_center, size: 44, color: colorScheme.primary),
      ),
      errorWidget: (context, url, error) => Container(
        height: 100,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fitness_center, size: 44, color: colorScheme.primary),
      ),
    );
  }
}
