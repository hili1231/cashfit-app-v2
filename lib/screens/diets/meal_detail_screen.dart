import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/meal.dart';
import '../../models/meal_day.dart';
import '../../models/meal_plan.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/quantity_formatter.dart';

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

  bool get isVideo =>
      (_cachedMeal.video != null && _cachedMeal.video!.isNotEmpty) ||
      _cachedMeal.image.toLowerCase().endsWith('.mp4');

  String get videoUrl =>
      (_cachedMeal.video != null && _cachedMeal.video!.isNotEmpty)
          ? _cachedMeal.video!
          : _cachedMeal.image;

  @override
  void initState() {
    super.initState();
    _cachedMeal = widget.meal;

    if (isVideo) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      )
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        }).catchError((error) {});
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _cachedMeal.name.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isVideo ? _buildVideoPlayer() : _buildImage(colorScheme),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRow(
                  Icons.local_fire_department,
                  QuantityFormatter.formatCalories(_cachedMeal.calories),
                  colorScheme.primary,
                  theme,
                  colorScheme,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<ShoppingListProvider>()
                        .addIngredients(_cachedMeal.ingredients);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ingredients added to Shopping List!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text("Add to Shopping List"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Ingredients", theme, colorScheme),
            ..._cachedMeal.ingredients.map(
              (ingredientLine) => _buildBulletText(
                "${QuantityFormatter.format(ingredientLine.quantity)} ${ingredientLine.unit} ${ingredientLine.ingredient.name}",
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Instructions", theme, colorScheme),
            ..._cachedMeal.instructions.asMap().entries.map(
                  (entry) => _buildNumberedInstruction(
                    entry.key + 1,
                    entry.value,
                    theme,
                    colorScheme,
                  ),
                ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 28,
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      );
    } else {
      return _buildImage(colorScheme);
    }
  }

  Widget _buildImage(ColorScheme colorScheme) {
    final url = _cachedMeal.image;
    final validUrl = (url.isNotEmpty && url.startsWith('http') && !url.contains('firebasestorage.googleapis.com'))
        ? url
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80';

    return CachedNetworkImage(
      imageUrl: validUrl,
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

  Widget _buildNumberedInstruction(
    int stepNumber,
    String text,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$stepNumber",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
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
