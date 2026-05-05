import 'package:flutter/material.dart';

class AppTheme {
  // Core palette - Deep & Premium
  static const Color bgDark = Color(0xFF0F111A);
  static const Color bgCard = Color(0xFF1A1D2E);
  static const Color bgCardLight = Color(0xFF242942);
  static const Color borderColor = Color(0xFF2D3250);
  
  // Vibrant Accents
  static const Color accentCyan = Color(0xFF00F2FF);
  static const Color accentMint = Color(0xFF00FFB2);
  static const Color accentPurple = Color(0xFF8E66FF);
  static const Color accentRose = Color(0xFFFF4D97);
  
  static const Color textPrimary = Color(0xFFF8F9FF);
  static const Color textSecondary = Color(0xFF9499C3);
  static const Color textHint = Color(0xFF5C628D);
  static const Color error = Color(0xFFFF5252);

  // Light palette - Soft & Clean
  static const Color bgLight = Color(0xFFF4F7FF);
  static const Color bgCardWhite = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1C29);
  static const Color textSecondaryLight = Color(0xFF6B728E);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentCyan, accentMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accentPurple, accentRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentCyan.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: accentCyan,
      secondary: accentMint,
      surface: bgCard,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accentCyan, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: accentCyan,
      secondary: accentMint,
      surface: bgCardWhite,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: bgCardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimaryLight,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accentCyan, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textSecondaryLight, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}

