import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';

import '../../models/workout_program.dart';
import '../../widgets/workout_card.dart';
import '../../theme.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkoutCategory(context, "BEGINNER"),
              _buildWorkoutCategory(context, "INTERMEDIATE"),
              _buildWorkoutCategory(context, "ADVANCED"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCategory(BuildContext context, String level) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('workoutPrograms')
              .where(
                'level',
                isEqualTo: level[0] + level.substring(1).toLowerCase(),
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox();
        }

        final workouts =
            docs
                .map(
                  (doc) => WorkoutProgram.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();
        const SizedBox(height: 30);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // Thread-safe UI callback
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level,
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: workouts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            179,
                            0,
                            0,
                            0,
                          ).withAlpha(25),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: WorkoutCard(workout: workout),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
