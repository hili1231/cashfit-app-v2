import '../../models/exercise.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/workout_program.dart';
import '../../models/workout_exercise.dart';
import 'exercise_detail_screen.dart';
import 'workout_detail_screen.dart';
import '../nav_screen.dart';
import '../../theme.dart';

class DayDetailScreen extends StatelessWidget {
  final int dayNumber;
  final List<String> dayExerciseIds; // List of WorkoutExercise IDs
  final WorkoutProgram workout;

  const DayDetailScreen({
    super.key,
    required this.dayNumber,
    required this.dayExerciseIds,
    required this.workout,
    required List<String> dayExercises,
  });

  Future<List<WorkoutExercise>> fetchWorkoutExercises() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('workoutExercises')
            .where(FieldPath.documentId, whereIn: dayExerciseIds)
            .get();

    return snapshot.docs
        .map((doc) => WorkoutExercise.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      workout.image,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _buildPlaceholderImage(height: 220),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    workout.description,
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Exercises for Day $dayNumber",
                    style: GoogleFonts.oswald(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<WorkoutExercise>>(
                    future: fetchWorkoutExercises(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "No exercises available for this day",
                            style: GoogleFonts.oswald(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      final dayExercises = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dayExercises.length,
                        itemBuilder: (context, index) {
                          final workoutEx = dayExercises[index];
                          return _buildExerciseCard(context, workoutEx);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () {
                    final navState =
                        context.findAncestorStateOfType<NavScreenState>();
                    navState?.setDetailScreen(
                      WorkoutDetailScreen(workout: workout),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutExercise workoutEx) {
    return FutureBuilder<Exercise?>(
      future: workoutEx.fetchExercise(), // Fetch the Exercise
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final exercise = snapshot.data!;

        return InkWell(
          onTap: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            navState?.setDetailScreen(
              ExerciseDetailScreen(
                exercise: exercise,
                workout: workout,
                dayNumber: dayNumber,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: Image.network(
                    exercise.image ?? '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => _buildPlaceholderImage(height: 100),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: GoogleFonts.oswald(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${workoutEx.sets} sets • ${workoutEx.reps} reps",
                          style: GoogleFonts.oswald(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_ios, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage({double height = 100, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, size: 40, color: Colors.white70),
    );
  }
}
