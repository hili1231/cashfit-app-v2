import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../models/exercise.dart';
import '../../models/workout_program.dart';
import '../nav_screen.dart';
import 'workout_day_detail_screen.dart';
import 'workout_detail_screen.dart';
import '../../theme.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  final WorkoutProgram workout;
  final int? dayNumber;

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
              navState?.setDetailScreen(
                DayDetailScreen(
                  dayNumber: dayNumber!,
                  dayExercises: workout.days["day_$dayNumber"] ?? [],
                  workout: workout,
                  dayExerciseIds: [],
                ),
              );
            } else {
              navState?.setDetailScreen(WorkoutDetailScreen(workout: workout));
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaDisplay(
                  videoUrl: exercise.videoUrl,
                  imagePath: exercise.image,
                  height: 220,
                ),
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

class MediaDisplay extends StatefulWidget {
  final String? videoUrl;
  final String? imagePath;
  final double height;

  const MediaDisplay({
    super.key,
    this.videoUrl,
    this.imagePath,
    required this.height,
  });

  @override
  State<MediaDisplay> createState() => _MediaDisplayState();
}

class _MediaDisplayState extends State<MediaDisplay> {
  VideoPlayerController? _controller;
  bool _isVideoLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      // ✅ Replaced the deprecated `.network(...)` with `.networkUrl(Uri.parse(...))`
      _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl!),
        )
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoLoaded = true;
              _controller?.setLooping(true);
              _controller?.play();
            });
          }
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
    if (_isVideoLoaded && _controller != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayer(_controller!),
        ),
      );
    }

    // If it's not a video or not loaded, try to show an image
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.network(
        widget.imagePath!,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Otherwise, show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.fitness_center, size: 48, color: Colors.white54),
    );
  }
}
