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

// Enum to define button style
enum FitCoinButtonStyle { filled, outlined, text, greyFilled }

// Custom widget for FitCoin buttons (filled, outlined, text, grey-filled)
class FitCoinButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final FitCoinButtonStyle style;

  const FitCoinButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case FitCoinButtonStyle.filled:
        return FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
        );
      case FitCoinButtonStyle.outlined:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(label),
        );
      case FitCoinButtonStyle.text:
        return TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
        );
      case FitCoinButtonStyle.greyFilled:
        final greyTheme = Theme.of(context).extension<GreyFilledButtonTheme>();
        return FilledButton.icon(
          style: greyTheme?.style,
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
        );
    }
  }
}

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  NavScreenState createState() => NavScreenState();
}

class NavScreenState extends State<NavScreen> {
  final PageController _pageController = PageController();
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
    _pageController.jumpToPage(index);
  }

  void clearDetailScreen() {
    setState(() {
      detailScreen = detailStack.isNotEmpty ? detailStack.removeLast() : null;
    });
  }

  void replaceWithScreen(Widget screen) {
    setState(() {
      detailStack.clear();
      detailScreen = screen;
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

    final bool showFitCoinBar =
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
                    icon: const Icon(Icons.person, size: 28),
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: Icon(
                  userProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  key: ValueKey(userProvider.themeMode),
                  size: 28,
                ),
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
              showFitCoinBar
                  ? _buildFitCoinBar(context, userProvider, colorScheme, theme)
                  : null,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              detailScreen ??
              PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => selectedIndex = index),
                children: _screens,
              ),
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
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_rounded, size: 28),
              label: "Workouts",
            ),
            NavigationDestination(
              icon: Icon(Icons.lunch_dining, size: 28),
              label: "Diet",
            ),
            NavigationDestination(
              icon: Icon(Icons.people, size: 28),
              label: "Community",
            ),
            NavigationDestination(
              icon: Icon(Icons.monetization_on_rounded, size: 28),
              label: "Side Hustles",
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFitCoinBar(
    BuildContext context,
    UserProvider userProvider,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Image.asset('assets/images/fitcoin_icon.png', width: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${userProvider.currentUser?.points ?? 0} FitCoins",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            FitCoinButton(
              label: "FitCoins to Cash",
              icon: Icons.swap_horiz,
              onPressed: () => setDetailScreen(const PointsConversionScreen()),
              style: FitCoinButtonStyle.filled,
            ),
            const SizedBox(width: 8),
            FitCoinButton(
              label: "Earn FitCoins",
              icon: Icons.add_circle_outline,
              onPressed: () => setDetailScreen(const EarnPointsScreen()),
              style: FitCoinButtonStyle.outlined,
            ),
          ],
        ),
      ),
    );
  }
}
