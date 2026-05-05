import 'package:ai_image_generator/core/app_theme.dart';
import 'package:ai_image_generator/views/onboarding/onboarding_screen.dart';
import 'package:ai_image_generator/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

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
    return KhaltiScope(
      publicKey: dotenv.env['KHALTI_PUBLIC_KEY'] ?? '',
      builder: (context, navigatorKey) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeMode,
          builder: (context, mode, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('ne', 'NP'),
              ],
              localizationsDelegates: const [
                KhaltiLocalizations.delegate,
              ],
              title: 'AI Art Studio',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              debugShowCheckedModeBanner: false,
              home: const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}
