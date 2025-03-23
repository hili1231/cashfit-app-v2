import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/workout_data.dart';
import '../models/workout_program.dart';
import '../widgets/workout_card.dart';
import '../theme.dart';
import '../services/workout_plan_generator.dart';
import 'personalized_workout_screen.dart';
import 'workout_diet_builder_screen.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final beginnerWorkouts =
        workoutPrograms.where((w) => w.level == "Beginner").toList();
    final intermediateWorkouts =
        workoutPrograms.where((w) => w.level == "Intermediate").toList();
    final advancedWorkouts =
        workoutPrograms.where((w) => w.level == "Advanced").toList();

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
              const SizedBox(height: 30),
              _buildPersonalizedSection(context),
              const SizedBox(height: 30),
              _buildWorkoutCategory(context, "BEGINNER", beginnerWorkouts),
              const SizedBox(height: 30),
              _buildWorkoutCategory(
                context,
                "INTERMEDIATE",
                intermediateWorkouts,
              ),
              const SizedBox(height: 30),
              _buildWorkoutCategory(context, "ADVANCED", advancedWorkouts),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Personalized Workout Prompt or Button
  Widget _buildPersonalizedSection(BuildContext context) {
    final personalizedPlan = generatePersonalizedWorkoutPlan();

    if (personalizedPlan != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "YOUR PERSONALIZED PLAN",
            style: GoogleFonts.oswald(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalizedWorkoutScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "View My Plan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "GET STARTED",
            style: GoogleFonts.oswald(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorkoutDietBuilderScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Create My Plan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber,
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.amber),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  /// 🔹 Workout Category Section
  Widget _buildWorkoutCategory(
    BuildContext context,
    String level,
    List<WorkoutProgram> workouts,
  ) {
    if (workouts.isEmpty) return const SizedBox();

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
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: workouts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(179, 0, 0, 0).withAlpha(25),
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
  }
}
