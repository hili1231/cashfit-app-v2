import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'workouts/workouts_screen.dart';
import 'diets/diet_selector_screen.dart';
import 'community_feed/community_feed_screen.dart';
import 'side_hustle/side_hustle_screen.dart';
import 'profile_screen.dart';
import 'rewards/earn_points_screen.dart';
import 'rewards/points_conversion_screen.dart';
import '../theme.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  NavScreenState createState() => NavScreenState();
}

class NavScreenState extends State<NavScreen> {
  int selectedIndex = 0;
  Widget? detailScreen;
  final List<Widget> detailStack = [];

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutsScreen(),
    const DietSelectorScreen(),
    const CommunityFeedScreen(),
    const SideHustleScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      detailScreen = null;
      detailStack.clear();
    });
  }

  void clearDetailScreen() {
    setState(() {
      detailScreen = detailStack.isNotEmpty ? detailStack.removeLast() : null;
    });
  }

  void replaceWithScreen(Widget screen) {
    setState(() {
      detailStack.clear(); // clear previous detail navigation history
      detailScreen = screen; // set the new screen
    });
  }

  void setDetailScreen(Widget? screen) {
    setState(() {
      if (detailScreen != null) detailStack.add(detailScreen!);
      detailScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool showPointsBar =
        userProvider.isLoggedIn && userProvider.currentUser != null;

    if (userProvider.isLoggedIn &&
        userProvider.currentUser == null &&
        detailScreen == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setDetailScreen(const LoginScreen());
      });
    }

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:
              userProvider.themeMode == ThemeMode.dark
                  ? Colors.black
                  : colorScheme.surface,
          title: Image.asset("assets/images/logo.png", height: 45),
          centerTitle: true,
          leading:
              detailScreen != null
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: clearDetailScreen,
                  )
                  : IconButton(
                    icon: const Icon(Icons.person, size: 32),
                    onPressed: () {
                      if (userProvider.isLoggedIn) {
                        setDetailScreen(const ProfileScreen());
                      } else {
                        setDetailScreen(const LoginScreen());
                      }
                    },
                  ),
          actions: [
            IconButton(
              icon: Icon(
                userProvider.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
                size: 32,
              ),
              onPressed: () {
                userProvider.setThemeMode(
                  userProvider.themeMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light,
                );
              },
              tooltip:
                  userProvider.themeMode == ThemeMode.light
                      ? "Switch to Dark Mode"
                      : "Switch to Light Mode",
            ),
          ],
          bottom:
              showPointsBar
                  ? PreferredSize(
                    preferredSize: const Size.fromHeight(80),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${userProvider.currentUser!.points ?? 0}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed:
                                      () => setDetailScreen(
                                        const PointsConversionScreen(),
                                      ),
                                  child: Text(
                                    "Points to Cash",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.primary),
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed:
                                    () => setDetailScreen(
                                      const EarnPointsScreen(),
                                    ),
                                child: Text(
                                  "Earn Points",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  : null,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: detailScreen ?? _screens[selectedIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onItemTapped,
          backgroundColor: colorScheme.surface,
          elevation: 5,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded, size: 28),
              selectedIcon: Icon(Icons.home_rounded, size: 28),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_rounded, size: 28),
              selectedIcon: Icon(Icons.fitness_center_rounded, size: 28),
              label: "Workouts",
            ),
            NavigationDestination(
              icon: Icon(Icons.lunch_dining, size: 28),
              selectedIcon: Icon(Icons.lunch_dining, size: 28),
              label: "Diet",
            ),
            NavigationDestination(
              icon: Icon(Icons.people, size: 28),
              selectedIcon: Icon(Icons.people, size: 28),
              label: "Community",
            ),
            NavigationDestination(
              icon: Icon(Icons.monetization_on_rounded, size: 28),
              selectedIcon: Icon(Icons.monetization_on_rounded, size: 28),
              label: "Side Hustles",
            ),
          ],
        ),
      ),
    );
  }
}
