import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workout_program.dart';
import '../screens/workouts/workout_detail_screen.dart';
import '../screens/nav_screen.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutProgram workout;

  const WorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensures ripple effect works correctly
      child: InkWell(
        onTap: () {
          // Use NavScreenState for correct navigation
          final navState = context.findAncestorStateOfType<NavScreenState>();
          if (navState != null) {
            navState.setDetailScreen(WorkoutDetailScreen(workout: workout));
          } else {
            // Fallback to normal push if navState is not found
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent, // Remove splash effect
        highlightColor: Colors.transparent, // Remove highlight effect
        child: Card(
          color: Colors.black, // Matches Dark Theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4, // Softer depth
          shadowColor: Colors.white70.withAlpha(10),
          child: SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildWorkoutImage(),
                ),
                // Workout Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    workout.title,
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Days & Level
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        workout.level,
                        style: GoogleFonts.oswald(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Workout Image with fallback
  Widget _buildWorkoutImage() {
    return Image.asset(
      workout.image,
      fit: BoxFit.cover,
      width: 180,
      height: 110,
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
    );
  }

  /// Placeholder image if an image fails to load
  Widget _buildPlaceholderImage() {
    return Container(
      width: 180,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
    );
  }
}
