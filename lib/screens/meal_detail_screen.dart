import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/meal.dart';
import '../models/meal_day.dart';
import '../models/meal_plan.dart';
import '../screens/nav_screen.dart';
import 'diet_day_detail_screen.dart';
import '../theme.dart';

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎥 **Meal Media (Image or Video)**
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo ? _buildVideoPlayer() : _buildImage(),
              ),
              const SizedBox(height: 16),

              // 🔥 **Calories**
              _buildInfoRow(
                Icons.local_fire_department,
                "${widget.meal.calories} Calories",
                Colors.amber,
              ),
              const SizedBox(height: 20),

              // 🥗 **Ingredients**
              _buildSectionTitle("Ingredients"),
              if (widget.meal.ingredients.isNotEmpty)
                ...widget.meal.ingredients.map((ing) => _buildBulletText(ing))
              else
                _buildEmptyMessage("No ingredients available"),
              const SizedBox(height: 20),

              // 🍽 **Instructions**
              _buildSectionTitle("Instructions"),
              if (widget.meal.instructions.isNotEmpty)
                ...widget.meal.instructions.map(
                  (step) => _buildBulletText(step),
                )
              else
                _buildEmptyMessage("No instructions available"),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// **🎥 Video Player for `.mp4` Files**
  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  /// **🖼 Meal Image Display**
  Widget _buildImage() {
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

  /// **🔥 Calories Display**
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

  /// **📌 Section Title**
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

  /// **🔹 Bullet Point Text**
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

  /// **⚠ Empty Message Placeholder**
  Widget _buildEmptyMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.white70, fontSize: 16),
    );
  }

  /// **🖼 Placeholder Image for Missing Media**
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
