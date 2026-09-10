import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GiftRecommendationScreen extends StatelessWidget {
  const GiftRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: AppColors.warning, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              "Gift suggestions aren't ready yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "We're still building this. Check back soon.",
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}