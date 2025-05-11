import 'dart:async';
import 'package:cashfit/services/cache_service.dart';
import 'package:cashfit/theme.dart';
import 'package:cashfit/widgets/step_counter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/ad_helper.dart';
import '../models/meal_plan.dart';
import '../models/workout_program.dart';
import '../models/challenge.dart';
import '../models/side_hustle.dart';
import '../screens/nav_screen.dart';
import '../widgets/workout_card.dart';
import '../widgets/meal_card.dart';
import '../screens/personalize/workout_diet_builder_screen.dart' as personalize;
import '../screens/side_hustle/side_hustle_detail_screen.dart';
import '../screens/diets/diet_selector_screen.dart';
import '../providers/user_provider.dart';
import 'side_hustle/side_hustle_screen.dart';

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

class HomeScreen extends StatefulWidget {
  final MealPlan? activeMealPlan;
  const HomeScreen({super.key, this.activeMealPlan});

  static Map<String, dynamic>? cachedHomeData;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeDataFuture;
  bool _isAdRewardButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = fetchAllHomeData();
  }

  void _handleAdWatched() {
    setState(() {
      _isAdRewardButtonEnabled = false; // Disable button after watching ad
    });
    // Simulate ad reward logic
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _isAdRewardButtonEnabled = true; // Re-enable button after reward
      });
    });
  }

  Future<Map<String, dynamic>> fetchAllHomeData() async {
    final cacheService = CacheService();

    // Use cache service to get workout programs and meal plans
    final workoutsFuture = cacheService.getWorkoutPrograms();
    final mealPlansFuture = cacheService.getMealPlans();

    // Batch Firestore queries for challenges and side hustles
    final firestore = FirebaseFirestore.instance;
    final challengesFuture = firestore.collection('challenges').get();
    final hustlesFuture = firestore.collection('sideHustles').get();

    final results = await Future.wait([
      workoutsFuture,
      mealPlansFuture,
      challengesFuture,
      hustlesFuture,
    ]);

    final workoutPrograms = results[0] as List<WorkoutProgram>;
    final mealPlans = results[1] as List<MealPlan>;
    final challengesSnapshot = results[2] as QuerySnapshot;
    final hustlesSnapshot = results[3] as QuerySnapshot;

    final challenges = challengesSnapshot.docs
        .map((doc) => Challenge.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    final sideHustles = hustlesSnapshot.docs
        .map((doc) => SideHustle.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return {
      'workouts': workoutPrograms,
      'mealPlans': mealPlans,
      'challenges': challenges,
      'sideHustles': sideHustles,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _WorkoutDietHeaderDelegate(
                  height: 94, // Already fixed to prevent overflow
                  child: _buildWorkoutDietSection(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: StepCounterWidget(),
                ),
              ),
              const SliverToBoxAdapter(child: AutoRotatingBanner()),
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _homeDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          "No data found",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    final workouts = data['workouts'] as List<WorkoutProgram>;
                    final mealPlans = data['mealPlans'] as List<MealPlan>;
                    final allChallenges = data['challenges'] as List<Challenge>;
                    final sideHustles = data['sideHustles'] as List<SideHustle>;

                    final userProvider = Provider.of<UserProvider>(context);
                    allChallenges
                        .where(
                          (ch) =>
                              ch.id == 
                              (userProvider.currentUser?.activeChallengeId ?? 
                                  ''),
                        )
                        .toList();
                    final bool hasSideHustles = sideHustles.isNotEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        AdHelper.bannerAdWidget(context),
                        const SizedBox(height: 12),
                        _buildSectionTitle(context, "WORKOUTS"),
                        _buildHorizontalList(
                          workouts
                              .map((wp) => WorkoutCard(workout: wp))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        _buildSectionTitle(context, "MEAL PLANS"),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildViewAllMealPlansButton(context),
                        ),
                        _buildMealPlansRow(context, mealPlans),
                        const SizedBox(height: 8),
                        if (hasSideHustles) ...[
                          _buildSectionTitle(context, "SIDE HUSTLES"),
                          _buildSideHustleRow(context, sideHustles),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton(
                          onPressed: _isAdRewardButtonEnabled ? _handleAdWatched : null,
                          child: Text(_isAdRewardButtonEnabled ? 'Watch Ad' : 'Ad Loading...'),
                        ),
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

  Widget _buildWorkoutDietSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PERSONALIZE",
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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
                  screen: const personalize.WorkoutDietBuilderScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required BuildContext context,
    required Widget screen,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        debugPrint('Button "$label" pressed');
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          debugPrint('NavScreenState found, using setDetailScreen');
          navState.setDetailScreen(screen);
        } else {
          debugPrint('NavScreenState not found, using Navigator.push');
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
              .then((_) => debugPrint('Navigation completed'))
              .catchError((e) => debugPrint('Navigation error: $e'));
        }
      },
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildViewAllMealPlansButton(BuildContext context) {
    return _buildAllMealButton(
      label: "View All Meal Plans",
      context: context,
      screen: const DietSelectorScreen(),
    );
  }

  Widget _buildAllMealButton({
    required String label,
    required BuildContext context,
    required Widget screen,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(screen);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Widget> items) {
    Theme.of(context);
    return SizedBox(
      height: 220, // Match card height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }

  Widget _buildMealPlansRow(BuildContext context, List<MealPlan> mealPlans) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (mealPlans.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No meal plans found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 8),
        itemCount: mealPlans.length,
        itemBuilder: (context, index) {
          return MealPlanCard(mealPlan: mealPlans[index]);
        },
      ),
    );
  }

  Widget _buildSideHustleRow(BuildContext context, List<SideHustle> hustles) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hustles.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            "No side hustles found",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hustles.length,
        padding: const EdgeInsets.only(left: 16),
        itemBuilder:
            (context, index) => _buildSideHustleCard(context, hustles[index]),
      ),
    );
  }

  Widget _buildSideHustleCard(BuildContext context, SideHustle hustle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final navState = context.findAncestorStateOfType<NavScreenState>();
    final totalParticipants = hustle.participants.length;
    final maxP = hustle.maxParticipants ?? 0;
    final spotsLeft = maxP > 0 ? (maxP - totalParticipants) : 0;

    return AnimatedCard(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: 180,
        height: 220,
        child: GestureDetector(
          onTap: () {
            if (navState != null) {
              navState.setDetailScreen(SideHustleDetailScreen(hustle: hustle));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child:
                    hustle.thumbnail.trim().isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: hustle.thumbnail,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholderFadeInDuration: const Duration(
                            milliseconds: 200,
                          ),
                          placeholder:
                              (context, url) =>
                                  _buildPlaceholderImage(110, true),
                          errorWidget:
                              (context, url, error) =>
                                  _buildPlaceholderImage(110, false),
                          fadeInDuration: const Duration(milliseconds: 300),
                          useOldImageOnUrlChange: true,
                        )
                        : Image.asset(
                          'assets/images/side_hustle.jpg',
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  hustle.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.people, color: colorScheme.primary, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      maxP > 0
                          ? "$spotsLeft spots left"
                          : "$totalParticipants participants",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: colorScheme.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "\$${hustle.reward} prize",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double size, bool isLoading) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: size,
      width: double.infinity,
      color: colorScheme.surfaceContainer,
      alignment: Alignment.center,
      child:
          isLoading
              ? CircularProgressIndicator(color: colorScheme.primary)
              : Icon(
                Icons.restaurant_menu,
                size: 40,
                color: colorScheme.primary,
              ),
    );
  }

  void _onAdWatched() {
    setState(() {
      _isAdRewardButtonEnabled = true;
    });
  }
}

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
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 2;
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
      height: 180,
      child: PageView(
        controller: _pageController,
        children: [
          _buildBannerSideHustleCard(
            context,
            label: "SIDE HUSTLES",
            onTap: () {
              final navState =
                  context.findAncestorStateOfType<NavScreenState>();
              if (navState != null) {
                navState.setDetailScreen(const SideHustleScreen());
              }
            },
            imageAsset: 'assets/images/side_hustle.jpg',
          ),
        ],
      ),
    );
  }
}

Widget _buildBannerSideHustleCard(
  BuildContext context, {
  required String label,
  required VoidCallback onTap,
  required String imageAsset,
}) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
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
