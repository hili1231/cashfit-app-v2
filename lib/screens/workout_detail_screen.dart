import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import 'workout_day_detail_screen.dart';
import 'exercise_detail_screen.dart';
import 'nav_screen.dart';
import '../theme.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutProgram workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    // Group exercises by day.
    final Map<int, List<Exercise>> exercisesByDay = {};
    for (final ex in workout.exercises) {
      exercisesByDay.putIfAbsent(ex.day, () => []).add(ex);
    }
    final sortedDays = exercisesByDay.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Scrollable content.
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                  // Day Sections.
                  ...sortedDays.map((day) {
                    final dayExercises = exercisesByDay[day] ?? [];
                    return _buildDaySection(context, day, dayExercises);
                  }),
                ],
              ),
            ),
            // Back button overlapping the image.
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () {
                    final navState =
                        context.findAncestorStateOfType<NavScreenState>();
                    navState?.setDetailScreen(null);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section for a specific day.
  Widget _buildDaySection(
    BuildContext context,
    int day,
    List<Exercise> dayExercises,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        // Day header row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Day $day",
                style: GoogleFonts.oswald(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildTabButton(
                label: "View All",
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.setDetailScreen(
                      DayDetailScreen(
                        dayNumber: day,
                        exercises: dayExercises,
                        workout: workout,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        // Added extra space between header and cards.
        const SizedBox(height: 12),
        // Horizontal scroll list of exercises.
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: dayExercises.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final ex = dayExercises[index];
              return _buildExerciseCard(context, ex);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Material card for an exercise.
  Widget _buildExerciseCard(BuildContext context, Exercise ex) {
    return SizedBox(
      width: 170,
      child: Card(
        color: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(right: 12),
        elevation: 3,
        // Remove white glow by setting shadowColor to transparent.
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                ExerciseDetailScreen(
                  exercise: ex,
                  workout: workout,
                  dayNumber: null,
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise image.
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  ex.image,
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _buildPlaceholderImage(height: 110),
                ),
              ),
              // Exercise details.
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      "${ex.sets} sets • ${ex.reps} reps",
                      style: GoogleFonts.oswald(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder image if an image fails to load.
  Widget _buildPlaceholderImage({double height = 100}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, size: 40, color: Colors.white70),
    );
  }

  /// A single tab-like button (reusable).
  Widget _buildTabButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 33, 33, 33),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
