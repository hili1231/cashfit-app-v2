import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

import 'home_screen.dart';
import 'workouts_screen.dart';
import 'challenges_screen.dart';
import 'diet_selector_screen.dart';
import 'side_hustle_screen.dart';
import 'profile_screen.dart';
import '../auth/login_screen.dart'; // ✅ Add this import

import '../data/user_data.dart'; // ✅ For currentUser & isLoggedIn

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  NavScreenState createState() => NavScreenState();
}

class NavScreenState extends State<NavScreen> {
  int selectedIndex = 0;
  Widget? detailScreen;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutsScreen(),
    const DietSelectorScreen(),
    const ChallengesScreen(),
    const SideHustleScreen(),
  ];

  // Switch tabs.
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      detailScreen = null;
    });
  }

  // Clear the detail screen and return to main tab view
  void clearDetailScreen() {
    setState(() {
      detailScreen = null;
    });
  }

  // Set a detail screen dynamically.
  void setDetailScreen(Widget? screen) {
    setState(() {
      detailScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: Colors.black,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Icon
                    IconButton(
                      icon: const Icon(
                        Icons.person,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        if (isLoggedIn) {
                          setDetailScreen(const ProfileScreen());
                        } else {
                          setDetailScreen(const LoginScreen());
                        }
                      },
                    ),
                    // Logo
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 85,
                        ),
                      ),
                    ),
                    // Right Spacer
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: detailScreen ?? _screens[selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white54,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 5,
          iconSize: 24,
          selectedLabelStyle: GoogleFonts.oswald(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.oswald(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: "Workouts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lunch_dining),
              label: "Meal Plan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              label: "Challenges",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_rounded),
              label: "Side Hustles",
            ),
          ],
        ),
      ),
    );
  }
}
