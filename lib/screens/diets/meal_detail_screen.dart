import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/meal.dart';
import '../../models/meal_day.dart';
import '../../models/meal_plan.dart';
import '../nav_screen.dart';
import 'diet_day_detail_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final MealPlan plan;
  final MealDay day;
  final Meal meal;

  const MealDetailScreen({
    super.key,
    required this.plan,
    required this.day,
    required this.meal,
  });

  @override
  MealDetailScreenState createState() => MealDetailScreenState();
}

class MealDetailScreenState extends State<MealDetailScreen> {
  VideoPlayerController? _videoController;
  late Meal _cachedMeal;
  late ColorScheme colorScheme; // Define colorScheme as a class-level variable

  bool get isVideo => widget.meal.image.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    // Cache the meal data once on initialization
    _cachedMeal = widget.meal;

    // Initialize colorScheme in initState
    colorScheme = Theme.of(context).colorScheme;

    // Initialize video if applicable
    if (isVideo) {
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_cachedMeal.image), // Use networkUrl with Uri
        )
        ..initialize()
            .then((_) {
              if (!mounted) return; // Guard context usage
              setState(() {});
              _videoController?.setLooping(true);
              _videoController?.play();
            })
            .catchError((error) {
              // Removed print statement; consider using a logging framework in production
              // e.g., logger.e('Video initialization error: $error');
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Note: We already have colorScheme at class level, but let's keep it here for consistency
    // with other methods that expect it as a parameter
    final colorScheme = this.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _cachedMeal.name.toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                DietDayDetailScreen(plan: widget.plan, day: widget.day),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isVideo ? _buildVideoPlayer() : _buildImage(colorScheme),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.local_fire_department,
              "${_cachedMeal.calories.round()} Calories",
              colorScheme.primary,
              theme,
              colorScheme,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Ingredients", theme, colorScheme),
            ..._cachedMeal.ingredients.map(
              (ingredientLine) => _buildBulletText(
                "${ingredientLine.quantity} ${ingredientLine.unit} ${ingredientLine.ingredient.name}",
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Instructions", theme, colorScheme),
            ..._cachedMeal.instructions.map(
              (instruction) =>
                  _buildBulletText(instruction, theme, colorScheme),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return _buildPlaceholderImage(colorScheme);
    }
  }

  Widget _buildImage(ColorScheme colorScheme) {
    return CachedNetworkImage(
      imageUrl:
          _cachedMeal.image.isNotEmpty
              ? _cachedMeal.image
              : 'assets/images/placeholder.jpg',
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholderImage(colorScheme),
      errorWidget: (context, url, error) => _buildPlaceholderImage(colorScheme),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBulletText(
    String text,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.fastfood, color: colorScheme.primary, size: 50),
    );
  }
}
