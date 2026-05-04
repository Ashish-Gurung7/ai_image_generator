import 'package:flutter/material.dart';

class AppTheme {
  // Core palette
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color bgCard = Color(0xFF111630);
  static const Color bgCardLight = Color(0xFF1A1F3D);
  static const Color surfaceLight = Color(0xFF222752);
  static const Color borderColor = Color(0xFF2A2F5A);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentMint = Color(0xFF00E676);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8E92B4);
  static const Color textHint = Color(0xFF545880);
  static const Color error = Color(0xFFFF5252);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentCyan, accentMint],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [bgCard, bgCardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentCyan, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
