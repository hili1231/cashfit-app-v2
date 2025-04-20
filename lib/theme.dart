import 'package:flutter/material.dart';

class AppTheme {
  // ───────────────── COLOR SCHEMES ─────────────────
  static final ColorScheme _light = ColorScheme.light(
    primary: Colors.amber,
    onPrimary: Colors.black,
    primaryContainer: Colors.amber.shade200,
    onPrimaryContainer: Colors.black,
    secondary: Colors.amberAccent,
    onSecondary: Colors.black,
    secondaryContainer: Colors.amberAccent.shade100,
    onSecondaryContainer: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black87,
    surfaceContainer: Colors.grey.shade100,
    onSurfaceVariant: Colors.black54,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  static final ColorScheme _dark = ColorScheme.dark(
    primary: Colors.amber,
    onPrimary: Colors.black,
    primaryContainer: Colors.amber.shade800,
    onPrimaryContainer: Colors.white,
    secondary: Colors.amberAccent,
    onSecondary: Colors.black,
    secondaryContainer: Colors.amberAccent.shade700,
    onSecondaryContainer: Colors.white,
    surface: const Color(0xFF1A1A1A),
    onSurface: Colors.white70,
    surfaceContainer: Colors.grey.shade900,
    onSurfaceVariant: Colors.white60,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  // ───────────────── TYPOGRAPHY ─────────────────
  static TextTheme _text(ColorScheme cs) => TextTheme(
    displayLarge: _h(cs, 57, FontWeight.bold, 0.25),
    displayMedium: _h(cs, 45, FontWeight.bold),
    displaySmall: _h(cs, 36, FontWeight.bold, -0.5),
    headlineLarge: _h(cs, 32, FontWeight.bold),
    headlineMedium: _h(cs, 28, FontWeight.bold),
    headlineSmall: _h(cs, 24, FontWeight.bold),
    titleLarge: _h(cs, 22, FontWeight.w500),
    titleMedium: _h(cs, 16, FontWeight.w500, 0.15),
    titleSmall: _h(cs, 14, FontWeight.w500, 0.1),
    bodyLarge: _b(cs, 16),
    bodyMedium: _b(cs, 14, cs.onSurfaceVariant, 0.25),
    bodySmall: _b(cs, 12, cs.onSurfaceVariant, 0.4),
    labelLarge: _l(cs, 14),
    labelMedium: _l(cs, 12, cs.onSurface),
    labelSmall: _l(cs, 11, cs.onSurface),
  );

  static TextStyle _h(
    ColorScheme cs,
    double s,
    FontWeight w, [
    double ls = 0,
  ]) => TextStyle(
    fontSize: s,
    fontWeight: w,
    letterSpacing: ls,
    color: cs.onSurface,
  );
  static TextStyle _b(ColorScheme cs, double s, [Color? c, double ls = 0.5]) =>
      TextStyle(
        fontSize: s,
        fontWeight: FontWeight.normal,
        letterSpacing: ls,
        color: c ?? cs.onSurface,
      );
  static TextStyle _l(ColorScheme cs, double s, [Color? c]) => TextStyle(
    fontSize: s,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: c ?? cs.onSurface,
  );

  // ───────────────── BACKGROUND GRADIENT ─────────────────
  static BoxDecoration backgroundGradient(ColorScheme cs) => BoxDecoration(
    gradient: LinearGradient(
      colors:
          cs.brightness == Brightness.dark
              ? [Colors.black, Colors.grey.shade900, Colors.grey.shade800]
              : [
                Colors.grey.shade50,
                Colors.grey.shade100,
                Colors.grey.shade100,
              ],
      stops: const [0, .8, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ───────────────── CARD POP‑IN EFFECT ─────────────────
  static Widget _animatedCard({required Widget child}) => TweenAnimationBuilder(
    tween: Tween<double>(begin: 0.9, end: 1),
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
    builder:
        (_, double scale, __) => Transform.scale(scale: scale, child: child),
    child: child,
  );

  /// **Public wrapper kept for backward‑compatibility**
  static Widget animatedCard({required Widget child}) =>
      _animatedCard(child: child);

  // ───────────────── PAGE ROUTE ─────────────────
  static Route createPageRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final offset = Tween(
        begin: const Offset(0, .1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: anim.drive(offset),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );

  // ───────────────── BASE THEME BUILDERS ─────────────────
  static ThemeData _base(ColorScheme cs, {required bool dark}) {
    final txt = _text(cs);
    final shadow = dark ? Colors.white70 : Colors.black87;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: txt,
      cardTheme: CardTheme(
        color: cs.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          elevation: 5,
          shadowColor: shadow,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
          shadowColor: shadow,
          surfaceTintColor: Colors.transparent,
          textStyle: txt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 1.5),
          foregroundColor: cs.onSurface,
          backgroundColor: cs.surfaceContainer,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
          shadowColor: shadow,
          surfaceTintColor: Colors.transparent,
          textStyle: txt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: txt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.amber.withAlpha(51),
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: txt.headlineSmall?.copyWith(color: cs.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainer,
        border: _border(cs),
        enabledBorder: _border(cs),
        focusedBorder: _border(cs, focus: true),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
      extensions: [
        CardAnimationExtension(cardBuilder: (_, w) => _animatedCard(child: w)),
        GreyFilledButtonTheme(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(cs.surfaceContainer),
            foregroundColor: WidgetStateProperty.all(cs.onSurface),
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            elevation: WidgetStateProperty.all(4),
            shadowColor: WidgetStateProperty.all(shadow),
            textStyle: WidgetStateProperty.all(
              txt.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(ColorScheme cs, {bool focus = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: focus ? cs.primary : cs.outline,
          width: focus ? 2 : 1,
        ),
      );

  /// Light theme
  static ThemeData lightTheme() => _base(_light, dark: false);

  /// Dark theme
  static ThemeData darkTheme() => _base(_dark, dark: true);
}

// ───────────────── EXTENSIONS ─────────────────
class CardAnimationExtension extends ThemeExtension<CardAnimationExtension> {
  final Widget Function(BuildContext, Widget) cardBuilder;
  CardAnimationExtension({required this.cardBuilder});

  @override
  CardAnimationExtension copyWith({
    Widget Function(BuildContext, Widget)? cardBuilder,
  }) => CardAnimationExtension(cardBuilder: cardBuilder ?? this.cardBuilder);

  @override
  CardAnimationExtension lerp(
    ThemeExtension<CardAnimationExtension>? other,
    double t,
  ) => this;
}

class GreyFilledButtonTheme extends ThemeExtension<GreyFilledButtonTheme> {
  final ButtonStyle style;
  GreyFilledButtonTheme({required this.style});

  @override
  GreyFilledButtonTheme copyWith({ButtonStyle? style}) =>
      GreyFilledButtonTheme(style: style ?? this.style);

  @override
  GreyFilledButtonTheme lerp(
    ThemeExtension<GreyFilledButtonTheme>? other,
    double t,
  ) => this;
}

// ───────────────── HELPER WIDGET ─────────────────
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
    final cardTheme = Theme.of(context).cardTheme;
    final anim = Theme.of(context).extension<CardAnimationExtension>()!;
    return anim.cardBuilder(
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
