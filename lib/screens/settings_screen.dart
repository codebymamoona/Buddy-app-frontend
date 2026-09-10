import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'spending_cap_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 56),
                SizedBox(height: 12),
                Text('Buddy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textPrimary)),
                Text('Version 1.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildConfigCard(
            title: 'Spending controls',
            icon: Icons.security_rounded,
            children: [
              _buildInteractiveRow(
                label: 'Spending limit',
                value: 'Configure',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpendingCapScreen(userId: userId),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border),
              _buildSettingRow('Approval expiry', '15 minutes'),
            ],
          ),
          // Removed: a "Backend Connection" card previously showed the raw
          // host, port, and database engine (127.0.0.1:8080, PostgreSQL)
          // directly in user-facing Settings. That's infrastructure detail
          // with no value to a real user and a real disclosure risk once
          // this points at anything other than localhost. If you need this
          // for testing, put it behind a developer-only debug screen, not
          // here.
        ],
      ),
    );
  }

  Widget _buildConfigCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInteractiveRow({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}