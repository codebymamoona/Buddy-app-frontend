import 'package:flutter/material.dart';
import '../models/spending_cap.dart';
import '../theme/app_theme.dart';

class ApprovalScreen extends StatelessWidget {
  final String itemDescription;
  final double amount;
  final SpendingCap cap;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const ApprovalScreen({
    super.key,
    required this.itemDescription,
    required this.amount,
    required this.cap,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final overCap = cap.usedFraction > 0.9;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pending_actions, color: AppColors.warning, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Buddy wants to spend',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Monthly cap usage',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Rs ${cap.used.toStringAsFixed(0)} / Rs ${cap.limit.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: overCap ? AppColors.danger : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: cap.usedFraction.toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.bg,
                      color: overCap ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Approve'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onDeny,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Deny'),
          ),
        ],
      ),
    );
  }
}