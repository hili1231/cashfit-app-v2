import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_program.dart';
import '../../models/workout_exercise.dart';
import '../../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../nav_screen.dart';
import '../../theme.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutProgram workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                  ...workout.days.entries.map((entry) {
                    final day = entry.key;
                    final workoutExerciseIds = entry.value;
                    return _buildDaySection(context, day, workoutExerciseIds);
                  }),
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

  Widget _buildDaySection(
    BuildContext context,
    String day,
    List<String> workoutExerciseIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Day $day",
            style: GoogleFonts.oswald(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<WorkoutExercise>>(
            future: _fetchWorkoutExercises(workoutExerciseIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No exercises available",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              final exercises = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return _buildExerciseCard(context, exercises[index]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<List<WorkoutExercise>> _fetchWorkoutExercises(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('workoutExercises')
            .where(FieldPath.documentId, whereIn: ids)
            .get();
    return snapshot.docs
        .map((doc) => WorkoutExercise.fromMap(doc.id, doc.data()))
        .toList();
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutExercise workoutEx) {
    return FutureBuilder<Exercise?>(
      future: workoutEx.fetchExercise(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final exercise = snapshot.data!;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              navState?.setDetailScreen(
                ExerciseDetailScreen(
                  exercise: exercise,
                  workout: workout,
                  dayNumber: null,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.white70.withAlpha(10),
              child: SizedBox(
                width: 180,
                height: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        exercise.image ?? '',
                        width: 180,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _buildPlaceholderImage(height: 110),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: GoogleFonts.oswald(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (exercise.name.toLowerCase() != "rest")
                              Text(
                                "${workoutEx.sets} sets • ${workoutEx.reps} reps",
                                style: GoogleFonts.oswald(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage({double height = 100}) {
    return Container(
      width: double.infinity,
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
