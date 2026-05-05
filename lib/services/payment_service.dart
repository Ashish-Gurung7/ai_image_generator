import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_image_generator/core/app_theme.dart';

class PaymentService {
  static Future<void> initiatePremiumPayment({
    required BuildContext context,
    required VoidCallback onPaymentSuccess,
  }) async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Unlock Premium', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: Text(
            'Do you want to purchase the Premium subscription for Rs. 10 to unlock unlimited image generations?',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Purchase'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

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
          content: Text('Payment Successful! Premium unlocked.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
