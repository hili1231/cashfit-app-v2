import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 **Color Palette**
  static const Color gold = Colors.amber; // Gold color for highlights
  static const Color white70 = Color(0xB3FFFFFF); // White with 70% opacity
  static const Color darkBg = Colors.black; // Dark background color
  static const Color cardBg = Color(0xFF1A1A1A); // Card background color (dark)
  static const Color cardBackground = Color(0xFF1A1A1A);
  // 🔥 **Global Gradient for Backgrounds**
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Colors.black, Color(0xFF1A1A1A)], // Dark gradient background
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 🏆 **Typography**
  // All fonts are set to Oswald via GoogleFonts
  static TextStyle headline = GoogleFonts.oswald(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: white70,
    letterSpacing: 1.5,
  );

  static TextStyle subheading = GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: white70,
  );

  static TextStyle smallText = GoogleFonts.oswald(fontSize: 16, color: white70);

  static TextStyle goldText = GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: gold,
  );

  static TextStyle buttonText = GoogleFonts.oswald(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // 🏗️ **Card Styling**
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        // Approximate white with very low opacity (2/255)
        color: const Color(0x02FFFFFF),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

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

  // 📌 **Button Styling**
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    elevation: 3,
    // Gold with 50/255 opacity (approximately 0.2)
    shadowColor: const Color(0x32FFD700),
  );

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

  // 🔹 **Apply Global ThemeData**
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.transparent, // Ensures the gradient shows
      primaryColor: Colors.amber,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.amber, // ✅ fixes purple spinner
      ),
      fontFamily: GoogleFonts.oswald().fontFamily,
      textTheme: GoogleFonts.oswaldTextTheme(
        TextTheme(
          bodyLarge: TextStyle(color: white70, fontSize: 16),
          // Colors.white.withOpacity(0.6) replaced with Color(0x99FFFFFF)
          bodyMedium: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        labelStyle: const TextStyle(color: white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent AppBar for gradient
        elevation: 2,
        // Replace gold.withAlpha(50) with Color(0x32FFD700)
        shadowColor: const Color(0x32FFD700),
        iconTheme: const IconThemeData(color: white70),
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: gold,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    );
  }
}
