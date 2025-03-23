import 'dart:async';
import 'package:cashfit/screens/diet_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/workout_card.dart';
import '../data/workout_data.dart';
import 'workout_builder_screen.dart';
import 'workout_diet_builder_screen.dart';
import 'diet_selector_screen.dart';
import 'nav_screen.dart';
import '../data/meal_plan_data.dart';
import '../data/challenge_data.dart';
import '../models/challenge.dart';
import '../data/side_hustle_data.dart';
import '../models/side_hustle.dart';
import 'meal_plan_screen.dart';
import 'challenge_detail_screen.dart';
import 'side_hustle_detail_screen.dart';
import '../models/meal_plan.dart';
import '../theme.dart';


/// Custom SliverPersistentHeaderDelegate for the PERSONALIZE header
class _WorkoutDietHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _WorkoutDietHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _WorkoutDietHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class HomeScreen extends StatelessWidget {
  final MealPlan? activeMealPlan; // User’s Active Meal Plan

  const HomeScreen({super.key, this.activeMealPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient, // Global gradient background
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Sticky PERSONALIZE header
              SliverPersistentHeader(
                pinned: true,
                delegate: _WorkoutDietHeaderDelegate(
                  height: 80, // Adjust height as needed
                  child: _buildWorkoutDietSection(context),
                ),
              ),
              // Auto-rotating banner
              SliverToBoxAdapter(child: AutoRotatingBanner()),
              // Other content as slivers
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, "WORKOUTS"),
                    _buildHorizontalList(
                      workoutPrograms
                          .map((wp) => WorkoutCard(workout: wp))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, "RECOMMENDED MEAL PLANS"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildViewAllMealPlansButton(context),
                    ),
                    const SizedBox(height: 8),
                    _buildRecommendedMealPlans(context),
                    const SizedBox(height: 12),
                    _buildSectionTitle(context, "CHALLENGES"),
                    _buildChallengeList(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, "SIDE HUSTLES"),
                    _buildSideHustleList(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PERSONALIZE SECTION
  Widget _buildWorkoutDietSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PERSONALIZE",
              style: GoogleFonts.oswald(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(
                    label: "Workout & Diet",
                    context: context,
                    screen: const WorkoutDietBuilderScreen(),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: "Workout",
                    context: context,
                    screen: const WorkoutBuilderScreen(buildBoth: false),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: "Diet",
                    context: context,
                    screen: const DietBuilderScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required BuildContext context,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(screen);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 33, 33, 33),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllMealPlansButton(BuildContext context) {
    return _buildTabButton(
      label: "View All Meal Plans",
      context: context,
      screen: const DietSelectorScreen(),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, [
    IconData? icon,
  ]) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
            ],
            Text(
              title.toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Widget> items) {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: items,
      ),
    );
  }

  Widget _buildChallengeList(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: challengeData.length,
        padding: const EdgeInsets.only(left: 16),
        itemBuilder: (context, index) {
          final challenge = challengeData[index];
          return _buildChallengeCard(context, challenge);
        },
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, Challenge challenge) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final navState = context.findAncestorStateOfType<NavScreenState>();
          navState?.setDetailScreen(
            ChallengeDetailScreen(challenge: challenge),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.asset(
                challenge.image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.black,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Challenge Title (normal text, not in caps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                challenge.name,
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Participants Info (normal text)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.amber, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "${challenge.participants} participants",
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideHustleList(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sideHustleData.length,
        padding: const EdgeInsets.only(left: 16),
        itemBuilder: (context, index) {
          final hustle = sideHustleData[index];
          return _buildSideHustleCard(context, hustle);
        },
      ),
    );
  }

  Widget _buildSideHustleCard(BuildContext context, SideHustle hustle) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final navState = context.findAncestorStateOfType<NavScreenState>();
          navState?.setDetailScreen(SideHustleDetailScreen(hustle: hustle));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side Hustle Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.asset(
                hustle.thumbnail,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.black,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Side Hustle Title (normal text)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                hustle.title,
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Reward Info (normal text)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "\$${hustle.reward} prize",
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Recommended Meal Plans
  Widget _buildRecommendedMealPlans(BuildContext context) {
    final recommendedPlans =
        allDiets.expand((diet) => diet.plans).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Additional spacing or text can go here if needed
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: recommendedPlans.length,
            itemBuilder: (context, index) {
              return _buildMealPlanCard(context, recommendedPlans[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanCard(BuildContext context, MealPlan plan) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final navState = context.findAncestorStateOfType<NavScreenState>();
          if (navState != null) {
            navState.setDetailScreen(MealPlanScreen(selectedPlan: plan));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealPlanScreen(selectedPlan: plan),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Plan Image or Placeholder Icon
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child:
                  plan.days.isNotEmpty && plan.days.first.breakfast != null
                      ? Image.asset(
                        plan.days.first.breakfast!.image,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _buildPlaceholderImage(100),
                      )
                      : _buildPlaceholderImage(100),
            ),
            const SizedBox(height: 8),

            // Meal Plan Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plan.planName,
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // View Plan Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.setDetailScreen(
                      MealPlanScreen(selectedPlan: plan),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealPlanScreen(selectedPlan: plan),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 33, 33, 33),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "View Plan",
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder Image for Missing Images
  Widget _buildPlaceholderImage(double size) {
    return Container(
      height: size,
      width: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.amber),
    );
  }
}

class AutoRotatingBanner extends StatefulWidget {
  const AutoRotatingBanner({super.key});

  @override
  AutoRotatingBannerState createState() => AutoRotatingBannerState();
}

class AutoRotatingBannerState extends State<AutoRotatingBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start auto-rotate every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 2; // Two pages
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, // Adjust height as needed (similar to your cards)
      child: PageView(
        controller: _pageController,
        children: [
          _buildBannerCard(
            context,
            label: "CHALLENGES",
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              // For demonstration, navigate to the first challenge
              navState?.setDetailScreen(
                ChallengeDetailScreen(challenge: challengeData.first),
              );
            },
            imageAsset:
                'assets/challenge_ad.jpg', // Replace with your actual asset
          ),
          _buildBannerCard(
            context,
            label: "SIDE HUSTLES",
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              // For demonstration, navigate to the first side hustle
              navState?.setDetailScreen(
                SideHustleDetailScreen(hustle: sideHustleData.first),
              );
            },
            imageAsset:
                'assets/side_hustle_ad.jpg', // Replace with your actual asset
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required String imageAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/fallback_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Show a black container with an icon fallback
                  return _buildBannerFallback();
                },
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner Fallback - Fills the entire banner area
  Widget _buildBannerFallback() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.amber),
    );
  }
}
