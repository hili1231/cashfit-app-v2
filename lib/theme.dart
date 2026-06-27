import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardAnimationExtension extends ThemeExtension<CardAnimationExtension> {
  final Widget Function(BuildContext context, Widget child) cardBuilder;
  CardAnimationExtension({required this.cardBuilder});

  @override
  ThemeExtension<CardAnimationExtension> copyWith({
    Widget Function(BuildContext context, Widget child)? cardBuilder,
  }) => CardAnimationExtension(cardBuilder: cardBuilder ?? this.cardBuilder);

  @override
  ThemeExtension<CardAnimationExtension> lerp(
    covariant ThemeExtension<CardAnimationExtension>? other,
    double t,
  ) => this;
}

class GreyFilledButtonTheme extends ThemeExtension<GreyFilledButtonTheme> {
  final ButtonStyle style;
  GreyFilledButtonTheme({required this.style});

  @override
  ThemeExtension<GreyFilledButtonTheme> copyWith({ButtonStyle? style}) =>
      GreyFilledButtonTheme(style: style ?? this.style);

  @override
  ThemeExtension<GreyFilledButtonTheme> lerp(
    covariant ThemeExtension<GreyFilledButtonTheme>? other,
    double t,
  ) => this;
}

class AppTheme {
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);

  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F3F6);

  static const Color electricEmerald = Color(0xFF00E676);
  static const Color cyberCyan = Color(0xFF00E5FF);

  static BoxDecoration backgroundGradient(ColorScheme cs) => BoxDecoration(
        gradient: LinearGradient(
          colors: cs.brightness == Brightness.dark
              ? [darkBackground, darkSurface]
              : [lightBackground, lightSurface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );

  static BoxDecoration glassCardDecoration(ColorScheme cs) => BoxDecoration(
        color: cs.brightness == Brightness.dark
            ? darkCard.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ───────────────── BASE THEME BUILDERS ─────────────────
  static ThemeData _base(ColorScheme cs, {required bool dark}) {
    final baseText = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final googleText = GoogleFonts.outfitTextTheme(baseText).apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: googleText,
      cardTheme: CardTheme(
        color: cs.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 4,
          shadowColor: cs.primary.withValues(alpha: 0.4),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 1.8),
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.onSurfaceVariant.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
      extensions: [
        CardAnimationExtension(cardBuilder: (_, w) => animatedCard(child: w)),
        GreyFilledButtonTheme(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
            foregroundColor: WidgetStateProperty.all(cs.onSurfaceVariant),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── DARK THEME ─────────────────
  static ThemeData get darkTheme => _base(
        const ColorScheme.dark(
          primary: electricEmerald,
          onPrimary: Colors.black,
          secondary: cyberCyan,
          onSecondary: Colors.black,
          surface: darkBackground,
          onSurface: Colors.white,
          surfaceContainer: darkSurface,
          surfaceContainerHighest: darkCard,
          onSurfaceVariant: Color(0xFF8B949E),
          error: Color(0xFFFF5252),
          onError: Colors.white,
        ),
        dark: true,
      );

  // ───────────────── LIGHT THEME ─────────────────
  static ThemeData get lightTheme => _base(
        const ColorScheme.light(
          primary: Color(0xFF00C853),
          onPrimary: Colors.white,
          secondary: Color(0xFF00B0FF),
          onSecondary: Colors.white,
          surface: lightBackground,
          onSurface: Color(0xFF1F2328),
          surfaceContainer: lightSurface,
          surfaceContainerHighest: lightCard,
          onSurfaceVariant: Color(0xFF6E7781),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        dark: false,
      );

  static Widget animatedCard({required Widget child}) {
    return AnimatedCard(child: child);
  }

  static PageRouteBuilder createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  const AnimatedCard({super.key, required this.child});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
