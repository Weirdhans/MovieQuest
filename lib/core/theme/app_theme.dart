import 'package:flutter/material.dart';

/// MovieQuest Theme - Zenith Reborn branding
/// Phoenix-inspired color scheme with gold and orange accents
class AppTheme {
  // Zenith Reborn Color Palette
  static const Color primaryGold = Color(0xFFFFB800); // Phoenix gold
  static const Color primaryOrange = Color(0xFFFF6B35); // Phoenix flame orange
  static const Color deepRed = Color(0xFFB91C1C); // Deep red accent
  static const Color accentTurquoise = Color(0xFF4FD1C5); // Filmreel turquoise accent
  static const Color accentGreen = Color(0xFF68D391); // Success/up arrow green
  static const Color darkBackground = Color(0xFF0A0A0A); // Very dark bg
  static const Color surfaceDark = Color(0xFF1A1A1A); // Slightly lighter surface
  static const Color lightText = Color(0xFFF5F5F5); // Off-white text
  static const Color neutralGray = Color(0xFF9CA3AF); // Neutral gray

  // Phoenix Gradient Colors
  static const phoenixGradient = LinearGradient(
    colors: [
      Color(0xFFFFB800), // Gold
      Color(0xFFFF6B35), // Orange
      Color(0xFFB91C1C), // Deep red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy naming for compatibility
  static const Color primary = primaryGold;
  static const Color accent = primaryOrange;
  static const Color background = darkBackground;
  static const Color surface = surfaceDark;
  static const Color textPrimary = lightText;
  static const Color textSecondary = neutralGray;
  static const Color danger = deepRed;
  static const Color success = primaryGold;
  static const Color error = deepRed;

  /// Dark theme with Zenith Reborn phoenix branding
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryOrange,
        surface: surfaceDark,
        error: deepRed,
        onPrimary: darkBackground,
        onSecondary: darkBackground,
        onSurface: lightText,
        onError: lightText,
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryGold),
      ),

      // Card
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Elevated Button - Phoenix gradient style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkBackground,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: deepRed),
        ),
        labelStyle: const TextStyle(color: neutralGray),
        hintStyle: const TextStyle(color: neutralGray),
      ),

      // Chip - Gold accent style
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryGold,
        labelStyle: const TextStyle(color: lightText),
        secondaryLabelStyle: const TextStyle(color: darkBackground),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: primaryGold),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: neutralGray,
        ),
      ),

      // Icon Theme - Gold accent
      iconTheme: const IconThemeData(color: primaryGold),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGold,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: neutralGray,
        thickness: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: darkBackground,
        elevation: 6,
      ),

      // Snackbar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: TextStyle(color: lightText),
        actionTextColor: primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
