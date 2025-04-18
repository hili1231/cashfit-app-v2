import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/exercise.dart';
import '../../models/workout_program.dart';
import 'workout_day_detail_screen.dart';
import '../nav_screen.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Map<String, dynamic>? exerciseConfig;
    if (dayNumber != null) {
      final dayKey = "Day $dayNumber";
      exerciseConfig = workout.days[dayKey]?.firstWhere(
        (config) => config['exerciseId'] == exercise.id,
        orElse: () => {},
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (dayNumber != null)
                      TextButton(
                        onPressed: () {
                          final dayKey = "Day $dayNumber";
                          final navState =
                              context.findAncestorStateOfType<NavScreenState>();
                          if (navState != null) {
                            navState.setDetailScreen(
                              DayDetailScreen(
                                dayNumber: dayNumber!,
                                dayExercises: workout.days[dayKey] ?? [],
                                workout: workout,
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => DayDetailScreen(
                                      dayNumber: dayNumber!,
                                      dayExercises: workout.days[dayKey] ?? [],
                                      workout: workout,
                                    ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "VIEW DAY",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MediaDisplay(
                        videoUrl: exercise.videoUrl,
                        imagePath: exercise.image,
                        height: 220,
                      ),
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(theme, "Instructions"),
                        Text(
                          exercise.instructions.isNotEmpty
                              ? exercise.instructions
                              : "No instructions available",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (exerciseConfig != null &&
                            exerciseConfig.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSectionTitle(theme, "Workout Details"),
                          Text(
                            "Sets: ${exerciseConfig['sets'] ?? 'N/A'}",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Reps: ${exerciseConfig['reps'] ?? 'N/A'}",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (exerciseConfig['restSeconds'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Rest: ${exerciseConfig['restSeconds']} seconds",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                          if (exerciseConfig['supersetWith'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Superset with: ${exerciseConfig['supersetWith']}",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
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
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty) {
      try {
        _controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.videoUrl!),
          )
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isVideoLoaded = true;
                    _controller?.setLooping(true);
                    _controller?.play();
                    _isPlaying = true;
                  });
                }
              })
              .catchError((error) {
                if (mounted) {
                  setState(() {
                    _isVideoLoaded = false;
                  });
                }
              });
      } catch (e) {
        if (mounted) {
          setState(() {
            _isVideoLoaded = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying && _controller != null) {
        _controller!.pause();
        _isPlaying = false;
      } else if (_controller != null) {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isVideoLoaded &&
        _controller != null &&
        _controller!.value.isInitialized) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: colorScheme.primary,
                  bufferedColor: colorScheme.primary.withValues(alpha: 0.5),
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: colorScheme.onSurface,
                size: 48,
              ),
              onPressed: _togglePlayPause,
            ),
          ],
        ),
      );
    }

    if (widget.imagePath != null && widget.imagePath!.trim().isNotEmpty) {
      return Image.network(
        widget.imagePath!,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _buildPlaceholder(colorScheme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(colorScheme);
        },
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fitness_center,
        size: 48,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
