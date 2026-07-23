import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/audit_entry.dart';
import '../theme/app_theme.dart';

class AuditTrailScreen extends StatelessWidget {
  final List<AuditEntry> entries;
  const AuditTrailScreen({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');

    if (entries.isEmpty) {
      return const Center(
        child: Text('No activity yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = entries[i];
        final isApproved = e.action.toLowerCase() == 'approved';
        final isDenied = e.action.toLowerCase() == 'denied';
        final iconColor = isApproved
            ? AppColors.success
            : isDenied
            ? AppColors.danger
            : AppColors.primary;
        final icon = isApproved
            ? Icons.check_circle_outline
            : isDenied
            ? Icons.cancel_outlined
            : Icons.receipt_long_outlined;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(e.detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text(fmt.format(e.timestamp), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    ],
                  ),
                ),
                if (e.immutable)
                  const Tooltip(
                    message: "Can't be edited or deleted",
                    child: Icon(Icons.verified_user_outlined, size: 17, color: AppColors.success),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}