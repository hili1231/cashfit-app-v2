// main.dart
import 'package:cashfit/screens/diets/diet_plan_repository.dart';
import 'package:cashfit/screens/diets/replace_meal_context_provider.dart';
import 'package:cashfit/screens/workouts/workout_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/nav_screen.dart';
import 'theme.dart';
import 'providers/user_provider.dart';
import 'screens/workouts/replace_workout_context_provider.dart';

/// Global key so any widget (e.g. EarnPointsScreen) can reach NavScreenState.
final GlobalKey<NavScreenState> navKey = GlobalKey<NavScreenState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Mobile‑only ad initialisation
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceContextProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceMealContextProvider()),
        Provider<WorkoutRepository>(create: (_) => WorkoutRepository()),
        Provider<DietPlanRepository>(create: (_) => DietPlanRepository()),
      ],

      /// 🔸 rebuild only when the *themeMode* field changes
      child: Selector<UserProvider, ThemeMode>(
        selector: (_, p) => p.themeMode,
        builder:
            (_, mode, __) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: mode,
              home: const AuthWrapper(),
            ),
      ),
    );
  }
}

/// Displays a splash‑style loading / error screen, then hands control to
/// NavScreen once the user data is ready.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final cs = Theme.of(context).colorScheme;

    if (userProvider.isLoading) {
      return _Splash(colorScheme: cs, child: const CircularProgressIndicator());
    }

    if (userProvider.errorMessage != null) {
      return _Splash(
        colorScheme: cs,
        child: Text(
          'Error:\n${userProvider.errorMessage}',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Normal, happy path 🎉
    return NavScreen(key: navKey);
  }
}

/// A tiny helper widget that shows the background gradient + centered content
class _Splash extends StatelessWidget {
  const _Splash({required this.colorScheme, required this.child});

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
