import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF2D55);
  static const Color secondaryColor = Color(0xFF5856D6);
  static const Color accentColor = Color(0xFF00C7BE);
  static const Color backgroundColor = Color(0xFF010101);
  static const Color surfaceColor = Color(0xFF121214);

  static const double horizontalPadding = 24.0;
  static const double verticalSpacing = 24.0;
  static const double borderRadius = 20.0;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFFFF5E7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.12),
      Colors.white.withValues(alpha: 0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF1C1C1E),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
