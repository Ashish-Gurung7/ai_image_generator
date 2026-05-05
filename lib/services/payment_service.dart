import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_image_generator/core/app_theme.dart';

class PaymentService {
  static Future<void> initiatePremiumPayment({
    required BuildContext context,
    required VoidCallback onPaymentSuccess,
  }) async {
    // SIMULATED FLOW: We show a loading indicator then immediately succeed.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context); // Close loading indicator
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! Premium unlocked.'),
          backgroundColor: AppTheme.accentMint,
        ),
      );
      
      onPaymentSuccess();
    }
  }

  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPremium') ?? false;
  }
}
