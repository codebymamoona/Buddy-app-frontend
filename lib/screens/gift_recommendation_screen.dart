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
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.engineering_rounded, color: AppColors.warning, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Gift Engine Offline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'GiftDelegatorTool is not yet implemented in the Spring Boot backend. Hardcoded mocks have been disabled for security testing.',
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