import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import 'nav_screen.dart';
import 'workout_day_detail_screen.dart';
import 'workout_detail_screen.dart';
import '../theme.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  final WorkoutProgram workout;
  final int? dayNumber; // If clicked from Day, it has a value.

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.workout,
    this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (dayNumber != null) {
              // Go back to DayDetailScreen if user came from Day view.
              navState?.setDetailScreen(
                DayDetailScreen(
                  dayNumber: dayNumber!,
                  exercises:
                      workout.exercises
                          .where((ex) => ex.day == dayNumber)
                          .toList(),
                  workout: workout,
                ),
              );
            } else {
              // Go back to WorkoutDetailScreen if user came from workout.
              navState?.setDetailScreen(WorkoutDetailScreen(workout: workout));
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // Global gradient background.
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Media (Image or Video) with fallback.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaDisplay(mediaPath: exercise.image, height: 220),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("Instructions"),
              Text(
                exercise.instructions,
                style: GoogleFonts.oswald(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Section title widget using Oswald and white70.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

/// MediaDisplay widget: displays a video if the asset ends with ".mp4", otherwise an image.
/// Uses a placeholder fallback if loading fails.
class MediaDisplay extends StatefulWidget {
  final String mediaPath;
  final double height;

  const MediaDisplay({
    super.key,
    required this.mediaPath,
    required this.height,
  });

  @override
  MediaDisplayState createState() => MediaDisplayState();
}

class MediaDisplayState extends State<MediaDisplay> {
  VideoPlayerController? _controller;
  bool get isVideo => widget.mediaPath.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    if (isVideo) {
      _controller = VideoPlayerController.asset(widget.mediaPath)
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isVideo) {
      if (_controller != null && _controller!.value.isInitialized) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: VideoPlayer(_controller!),
        );
      } else {
        return _buildPlaceholderImage(widget.height);
      }
    } else {
      return Image.asset(
        widget.mediaPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(widget.height),
      );
    }
  }

  Widget _buildPlaceholderImage(double height) {
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
