import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              _buildSettingRow('Approval Threshold', 'PKR 0 (All Orders)'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}