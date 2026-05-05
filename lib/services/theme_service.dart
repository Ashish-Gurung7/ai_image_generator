import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    } else {
      themeMode.value = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    }
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;
}
