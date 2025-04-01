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
    // Calculate how many days are in this workout
    final totalDays = workout.days.length;

    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final navState = context.findAncestorStateOfType<NavScreenState>();
          if (navState != null) {
            navState.setDetailScreen(WorkoutDetailScreen(workout: workout));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(workout: workout),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: _buildWorkoutImage(),
            ),
            const SizedBox(height: 8),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                workout.title,
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),

            // "X days" row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.amber, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "$totalDays days",
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Level row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.amber,
                    size: 12,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    workout.level,
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      color: Colors.white70,
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

  Widget _buildWorkoutImage() {
    // 🔒 Fallback if the image field is empty or null-like
    if (workout.image.isEmpty) {
      return _fallbackImage();
    }

    // 🌐 Check if it's a network image (starts with http or https)
    final isNetwork =
        workout.image.startsWith('http') || workout.image.startsWith('https');

    return isNetwork
        ? Image.network(
          workout.image,
          height: 90,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        )
        : Image.asset(
          workout.image,
          height: 90,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        );
  }

  Widget _fallbackImage() {
    return Container(
      height: 90,
      width: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, color: Colors.amber),
    );
  }
}
