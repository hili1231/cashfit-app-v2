import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../models/meal.dart';
import '../../models/meal_day.dart';
import '../../models/meal_plan.dart';
import '../nav_screen.dart';
import 'diet_day_detail_screen.dart';
import '../../theme.dart';

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

  bool get isVideo => widget.meal.image.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    // If the meal image is actually a video file, we set up the VideoPlayer.
    if (isVideo) {
      _videoController = VideoPlayerController.asset(widget.meal.image)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
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
    return Scaffold(
      // Transparent background to match your gradient usage.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.meal.name.toUpperCase(),
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
            // If we have a NavScreen, go back to the DietDayDetailScreen.
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(
                DietDayDetailScreen(plan: widget.plan, day: widget.day),
              );
            } else {
              // Otherwise, pop this screen from the stack.
              Navigator.pop(context);
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
              // Either show video if isVideo == true, otherwise show an image.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo ? _buildVideoPlayer() : _buildImage(),
              ),
              const SizedBox(height: 16),

              // Basic meal info row (Calories, etc.)
              _buildInfoRow(
                Icons.local_fire_department,
                "${widget.meal.calories.round()} Calories",
                Colors.amber,
              ),
              const SizedBox(height: 20),

              // Ingredient list
              _buildSectionTitle("Ingredients"),
              ...widget.meal.ingredients.map(
                (ingredientLine) => _buildBulletText(
                  "${ingredientLine.quantity} ${ingredientLine.unit} ${ingredientLine.ingredient.name}",
                ),
              ),
              const SizedBox(height: 20),

              // Instructions
              _buildSectionTitle("Instructions"),
              ...widget.meal.instructions.map(
                (instruction) => _buildBulletText(instruction),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // If the video is initialized, show it; otherwise show a placeholder.
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildImage() {
    // If meal.image is non-empty and not a video, show it as an asset image.
    return widget.meal.image.isNotEmpty
        ? Image.asset(
          widget.meal.image,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        )
        : _buildPlaceholderImage();
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.amber, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, color: Colors.amber, size: 50),
    );
  }
}
