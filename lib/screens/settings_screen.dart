import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'spending_cap_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  // 🚨 SECURITY FIX: The screen now demands the authenticated user ID
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 64),
                SizedBox(height: 12),
                Text('Buddy AI Core', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                Text('Zero-Trust Architecture v1.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildConfigCard(
            title: 'Security Controls',
            icon: Icons.security_rounded,
            children: [
              _buildInteractiveRow(
                label: 'Spending Controls & Limits',
                value: 'Configure',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 🚨 DYNAMIC INJECTION: Passing the real authenticated user
                      builder: (context) => SpendingCapScreen(userId: userId),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border),
              _buildSettingRow('Action Expiry', '15 Minutes'),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigCard(
            title: 'Backend Connection',
            icon: Icons.dns_rounded,
            children: [
              _buildSettingRow('Host TCP Tunnel', '127.0.0.1:8080'),
              const Divider(color: AppColors.border),
              _buildSettingRow('Database Sync', 'Live (PostgreSQL)'),
            ],
          ),
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
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
          Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
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