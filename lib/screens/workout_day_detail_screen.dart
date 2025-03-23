import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import 'exercise_detail_screen.dart';
import 'workout_detail_screen.dart';
import 'nav_screen.dart';
import '../theme.dart';

class DayDetailScreen extends StatelessWidget {
  final int dayNumber;
  final List<Exercise> exercises;
  final WorkoutProgram workout;

  const DayDetailScreen({
    super.key,
    required this.dayNumber,
    required this.exercises,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Main scrollable content.
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Image.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      workout.image,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _buildPlaceholderImage(height: 220),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Workout Description.
                  Text(
                    workout.description,
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Heading for the day's exercises.
                  Text(
                    "Exercises for Day $dayNumber",
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // List of exercises.
                  exercises.isNotEmpty
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          return _buildExerciseCard(context, ex);
                        },
                      )
                      : Center(
                        child: Text(
                          "No exercises available for this day",
                          style: GoogleFonts.oswald(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            // Back button overlapping the top left of the workout image.
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () {
                    final navState =
                        context.findAncestorStateOfType<NavScreenState>();
                    if (navState != null) {
                      navState.setDetailScreen(
                        WorkoutDetailScreen(workout: workout),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a Material card for an exercise with dynamic height.
  Widget _buildExerciseCard(BuildContext context, Exercise ex) {
    return InkWell(
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(
            ExerciseDetailScreen(
              exercise: ex,
              workout: workout,
              dayNumber: dayNumber,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), // Reduced vertical spacing.
        decoration: BoxDecoration(
          color: Colors.black, // Card background is black.
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Image.
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child:
                  ex.image.isNotEmpty
                      ? Image.asset(
                        ex.image,
                        fit: BoxFit.cover,
                        width: 100,
                        errorBuilder:
                            (_, __, ___) =>
                                _buildPlaceholderImage(height: 100, width: 100),
                      )
                      : _buildPlaceholderImage(height: 100, width: 100),
            ),
            const SizedBox(width: 8), // Reduced horizontal spacing.
            // Exercise Details.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Exercise Name.
                    Text(
                      ex.name,
                      style: GoogleFonts.oswald(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Sets & Reps.
                    Text(
                      "${ex.sets} sets • ${ex.reps} reps",
                      style: GoogleFonts.oswald(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Shortened Instructions.
                    Text(
                      ex.instructions,
                      style: GoogleFonts.oswald(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Arrow Icon.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder image if an image fails to load.
  Widget _buildPlaceholderImage({double height = 100, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, size: 40, color: Colors.white70),
    );
  }
}
