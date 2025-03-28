import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// User data & model
import '../data/user_data.dart' show currentUser;
import '../auth/login_screen.dart';

// Screens & Models
import '../theme.dart';
import '../models/meal_plan.dart';
import '../models/workout_program.dart';
import '../models/challenge.dart';
import '../models/side_hustle.dart';

// Local widgets or data
import '../data/challenge_data.dart';
import '../data/side_hustle_data.dart';
import '../screens/nav_screen.dart';
import '../widgets/workout_card.dart';
import '../screens/personalize/workout_diet_builder_screen.dart';
import '../screens/personalize/workout_builder_screen.dart';
import '../screens/personalize/diet_builder_screen.dart';
import '../screens/challenges/challenge_detail_screen.dart';
import '../screens/side_hustle/side_hustle_detail_screen.dart';
import '../screens/diets/diet_selector_screen.dart';
import '../screens/diets/meal_plan_screen.dart';

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
  final MealPlan? activeMealPlan; // optional: user’s Active Meal Plan

  const HomeScreen({super.key, this.activeMealPlan});

  Future<List<WorkoutProgram>> fetchWorkoutPrograms() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('workoutPrograms').get();
    return snapshot.docs
        .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Sticky PERSONALIZE header
              SliverPersistentHeader(
                pinned: true,
                delegate: _WorkoutDietHeaderDelegate(
                  height: 80,
                  child: _buildWorkoutDietSection(context),
                ),
              ),
              // Auto-rotating banner
              const SliverToBoxAdapter(child: AutoRotatingBanner()),
              // Other content as slivers
              SliverToBoxAdapter(
                child: FutureBuilder<List<WorkoutProgram>>(
                  future: fetchWorkoutPrograms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No workouts found"));
                    }

                    final workoutPrograms = snapshot.data!;
                    return Column(
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
                        _buildSectionTitle(context, "MEAL PLANS"),
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
                    );
                  },
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
          color: Colors.black,
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
        // 1. Check if user is logged in:
        if (currentUser == null || currentUser!.id.isEmpty) {
          // 2. Grab NavScreen’s state:
          final navState = context.findAncestorStateOfType<NavScreenState>();
          if (navState != null) {
            // 3. If user is NOT logged in, show the LoginScreen using setDetailScreen
            navState.setDetailScreen(const LoginScreen());
          } else {
            // Fallback (should rarely happen):
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
          return; // Stop here if not logged in
        }

        // If user IS logged in, proceed as usual:
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
      height: 230,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: items,
      ),
    );
  }

  Widget _buildRecommendedMealPlans(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('mealPlans').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No meal plans found',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final plans =
            snapshot.data!.docs
                .map(
                  (doc) =>
                      MealPlan.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList();

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return _buildMealPlanCard(context, plans[index]);
            },
          ),
        );
      },
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
            // Meal Plan Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child:
                  plan.days.isNotEmpty && plan.days.first.breakfast != null
                      ? Image.asset(
                        plan.days.first.breakfast!.meal.image,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _buildPlaceholderImage(100),
                      )
                      : _buildPlaceholderImage(90),
            ),
            const SizedBox(height: 8),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plan.planName,
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // View Plan Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double size) {
    return Container(
      height: size,
      width: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.amber),
    );
  }

  Widget _buildChallengeList(BuildContext context) {
    return FutureBuilder<List<Challenge>>(
      future: fetchChallengeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No challenges found"));
        }
        final challenges = snapshot.data!;
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            padding: const EdgeInsets.only(left: 16),
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _buildChallengeCard(context, challenge);
            },
          ),
        );
      },
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
              child:
                  challenge.image.startsWith("http")
                      ? Image.network(
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
                      )
                      : Image.asset(
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
            // Title
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
            // Participants
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
            // Hustle Image
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
            // Title
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
            // Reward Info
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
}

/// A placeholder function to represent the future that fetches challenges
Future<List<Challenge>> fetchChallengeData() async {
  // In real code, you might fetch from Firestore or an API
  await Future.delayed(const Duration(milliseconds: 300));
  return challengeData; // from challenge_data.dart
}

/// A placeholder banner for demonstration
class AutoRotatingBanner extends StatefulWidget {
  const AutoRotatingBanner({super.key});

  @override
  State<AutoRotatingBanner> createState() => AutoRotatingBannerState();
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
        _currentPage = (_currentPage + 1) % 2; // we have 2 pages
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
      height: 160, // Adjust as needed
      child: PageView(
        controller: _pageController,
        children: [
          _buildBannerCard(
            context,
            label: "CHALLENGES",
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              navState?.setDetailScreen(
                ChallengeDetailScreen(challenge: challengeData.first),
              );
            },
            imageAsset: 'assets/challenge_ad.jpg',
          ),
          _buildBannerCard(
            context,
            label: "SIDE HUSTLES",
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              navState?.setDetailScreen(
                SideHustleDetailScreen(hustle: sideHustleData.first),
              );
            },
            imageAsset: 'assets/side_hustle_ad.jpg',
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
              // Use `imageAsset` or fallback?
              Image.asset(
                'assets/fallback_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => _buildBannerFallback(),
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

  Widget _buildBannerFallback() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.amber),
    );
  }
}
