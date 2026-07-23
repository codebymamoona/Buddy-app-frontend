import 'package:flutter/material.dart';
import '../models/gift_idea.dart';
import '../theme/app_theme.dart';

class GiftRecommendationScreen extends StatelessWidget {
  final String friendName;
  final List<GiftIdea> ideas;
  final void Function(GiftIdea idea)? onOrder;

  const GiftRecommendationScreen({
    super.key,
    required this.friendName,
    required this.ideas,
    this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Suggested for $friendName',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        ...ideas.map((idea) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(idea.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 4),
                        Text('Rs ${idea.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Text(idea.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => onOrder?.call(idea),
                            child: const Text('Order this →'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}