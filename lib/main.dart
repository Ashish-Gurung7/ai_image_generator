import 'package:ai_image_generator/core/app_theme.dart';
import 'package:ai_image_generator/views/onboarding/onboarding_screen.dart';
import 'package:ai_image_generator/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: ThemeService.isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: ThemeService.isDark ? AppTheme.bgDark : AppTheme.bgLight,
    systemNavigationBarIconBrightness: ThemeService.isDark ? Brightness.light : Brightness.dark,
  ));

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'AI Art Studio',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
