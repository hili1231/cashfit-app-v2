import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 **Color Schemes for Light and Dark Themes**
  static final ColorScheme _lightColorScheme = ColorScheme.light(
    primary: Colors.amber,
    onPrimary: Colors.black,
    primaryContainer: Colors.amber[200],
    onPrimaryContainer: Colors.black,
    secondary: Colors.amberAccent,
    onSecondary: Colors.black,
    secondaryContainer: Colors.amberAccent[100],
    onSecondaryContainer: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black87,
    surfaceContainer: Colors.grey[100], // Used for elevated surfaces like cards
    onSurfaceVariant: Colors.black54,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Colors.amber,
    onPrimary: Colors.black,
    primaryContainer: Colors.amber[800],
    onPrimaryContainer: Colors.white,
    secondary: Colors.amberAccent,
    onSecondary: Colors.black,
    secondaryContainer: Colors.amberAccent[700],
    onSecondaryContainer: Colors.white,
    surface: const Color(0xFF1A1A1A),
    onSurface: Colors.white70,
    surfaceContainer: Colors.grey[900],
    onSurfaceVariant: Colors.white60,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  // 🏆 **Typography**
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: 0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  // 🔥 **Refined Global Gradient for Backgrounds**
  static BoxDecoration backgroundGradient(ColorScheme colorScheme) {
    final bool isDarkMode = colorScheme.brightness == Brightness.dark;
    if (isDarkMode) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey[900]!, Colors.grey[800]!],
          stops: const [0.0, 0.8, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!, Colors.grey[100]!],
          stops: const [0.0, 0.8, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
  }

  // 🎬 **Global Animation Widget (For Consistent Scaling)**
  static Widget animatedCard({required Widget child}) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.9, end: 1.0),
      builder: (context, double scale, _) {
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }

  // 📌 **Custom Page Transitions**
  static Route createPageRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // 🔹 **ThemeData for Light and Dark Modes**
  static ThemeData lightTheme() {
    final colorScheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(colorScheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // Ensure animations don't overflow
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.amber.withValues(alpha: 0.2),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: _buildTextTheme(
          colorScheme,
        ).headlineSmall?.copyWith(color: colorScheme.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      // Wrap Card widgets with animatedCard globally
      extensions: [
        CardAnimationExtension(
          cardBuilder: (context, child) => animatedCard(child: child),
        ),
      ],
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(colorScheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.amber.withValues(alpha: 0.2),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: _buildTextTheme(
          colorScheme,
        ).headlineSmall?.copyWith(color: colorScheme.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      // Wrap Card widgets with animatedCard globally
      extensions: [
        CardAnimationExtension(
          cardBuilder: (context, child) => animatedCard(child: child),
        ),
      ],
    );
  }
}

// Custom Theme Extension for Card Animation
class CardAnimationExtension extends ThemeExtension<CardAnimationExtension> {
  final Widget Function(BuildContext, Widget) cardBuilder;

  CardAnimationExtension({required this.cardBuilder});

  @override
  ThemeExtension<CardAnimationExtension> copyWith() {
    return CardAnimationExtension(cardBuilder: cardBuilder);
  }

  @override
  ThemeExtension<CardAnimationExtension> lerp(
    ThemeExtension<CardAnimationExtension>? other,
    double t,
  ) {
    if (other is! CardAnimationExtension) return this;
    return CardAnimationExtension(cardBuilder: cardBuilder);
  }
}

// Custom Card Widget to Use Theme Animation
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;

  const AnimatedCard({
    super.key,
    required this.child,
    this.elevation,
    this.color,
    this.shape,
    this.margin,
    this.clipBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final animationExtension = theme.extension<CardAnimationExtension>();

    return animationExtension!.cardBuilder(
      context,
      Card(
        elevation: elevation ?? cardTheme.elevation,
        color: color ?? cardTheme.color,
        shape: shape ?? cardTheme.shape,
        margin: margin ?? cardTheme.margin,
        clipBehavior: clipBehavior ?? cardTheme.clipBehavior,
        child: child,
      ),
    );
  }
}
