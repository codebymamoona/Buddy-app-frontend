import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'spending_cap_settings_screen.dart';
import '../config/app_mode.dart';

class SettingsScreen extends StatelessWidget {
  final String userId; // 🚨 FIXED: Now accepts the ID from main.dart

  const SettingsScreen({super.key, required this.userId});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use Buddy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // AuthGate listens to authStateChanges() and swaps to the login screen
      // on its own — no navigation needed here.
      if (AppMode.useMock) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log out is disabled in mock mode.')),
          );
        }
        return;
      }
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AppMode.useMock
        ? 'demo@buddy.app'
        : (FirebaseAuth.instance.currentUser?.email ?? 'Unknown');

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
                      builder: (context) => const SpendingCapScreen(),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border),
              _buildSettingRow('Approval expiry', '15 minutes'),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigCard(
            title: 'Account',
            icon: Icons.person_outline_rounded,
            children: [
              _buildSettingRow('Signed in as', email),
              const Divider(color: AppColors.border),
              InkWell(
                onTap: () => _confirmLogout(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Log out',
                        style: TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Removed: a "Backend Connection" card previously showed the raw
          // host, port, and database engine directly in user-facing Settings.
          // That's infrastructure detail with no value to a real user and a
          // real disclosure risk once this points at anything other than
          // localhost. If you need this for testing, put it behind a
          // developer-only debug screen, not here.
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
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
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