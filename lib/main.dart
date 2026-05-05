import 'package:ai_image_generator/core/app_theme.dart';
import 'package:ai_image_generator/views/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark status bar to match the dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KhaltiScope(
      publicKey: 'test_public_key_dc74e0fd57cb46cd93832aee0a390234', // Test public key
      builder: (context, navigatorKey) {
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
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
