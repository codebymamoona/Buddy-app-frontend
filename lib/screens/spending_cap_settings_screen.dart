import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class SpendingCapScreen extends StatefulWidget {
  final String userId; // Pass this from your auth state

  const SpendingCapScreen({super.key, required this.userId});

  @override
  State<SpendingCapScreen> createState() => _SpendingCapScreenState();
}

class _SpendingCapScreenState extends State<SpendingCapScreen> {
  // 🚨 Default UI values. In a full implementation, you fetch these via GET request in initState
  double _monthlyCap = 5000;
  double _threshold = 200;
  bool _autoApprove = false;

  final Map<String, double> _categoryDraft = {
    'Food': 2000,
    'Clothing': 2000,
    'Travel': 1000,
  };

  bool _isSaving = false;

  Future<void> _saveToVault() async {
    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/settings/spending-cap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": widget.userId,
          "monthlyCap": _monthlyCap,
          "autoApproveThreshold": _autoApprove ? _threshold : 0.0,
          "categoryCaps": _categoryDraft,
        }),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SECURITY PROTOCOL: Caps locked in PostgreSQL vault.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Network Error: Cannot reach Zero-Trust backend.'),
            backgroundColor: AppColors.danger
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock spent value for UI preview - backend should calculate real spend
    const double totalSpent = 1200.0;
    final ratio = _monthlyCap <= 0 ? 0.0 : (totalSpent / _monthlyCap).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Spending Controls', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ---- Overall monthly cap ----
          _buildConfigCard(
            title: 'Global Monthly Cap',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PKR 1200 spent', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('PKR ${_monthlyCap.toStringAsFixed(0)} cap',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: _monthlyCap,
                min: 500,
                max: 20000,
                divisions: 39,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: 'PKR ${_monthlyCap.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _monthlyCap = v),
              ),
              const Align(
                alignment: Alignment.center,
                child: Text('Drag to set AI total monthly budget', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- Approval rules ----
          _buildConfigCard(
            title: 'Zero-Trust Rules',
            icon: Icons.rule_rounded,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto-approve micro-orders', style: TextStyle(color: Colors.white, fontSize: 14)),
                  Switch(
                    value: _autoApprove,
                    activeColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    onChanged: (v) => setState(() => _autoApprove = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _autoApprove
                    ? 'Orders up to PKR ${_threshold.toStringAsFixed(0)} bypass manual approval.'
                    : 'Every single AI transaction requires your explicit authorization.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _autoApprove ? 1 : 0.3,
                child: IgnorePointer(
                  ignoring: !_autoApprove,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Approval Threshold', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                          Text('PKR ${_threshold.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _threshold.clamp(50, 5000).toDouble(),
                        min: 50,
                        max: 5000,
                        divisions: 99,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        label: 'PKR ${_threshold.toStringAsFixed(0)}',
                        onChanged: (v) => setState(() => _threshold = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- Per-category caps ----
          _buildConfigCard(
            title: 'Category Firewalls',
            icon: Icons.pie_chart_outline_rounded,
            children: _categoryDraft.keys.map((category) => _CategoryCapRow(
              category: category,
              spent: category == 'Food' ? 700 : 0, // Mock spend for demo
              cap: _categoryDraft[category]!,
              onChanged: (v) => setState(() => _categoryDraft[category] = v),
            )).toList(),
          ),
          const SizedBox(height: 28),

          // ---- Save Button ----
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveToVault,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                'ENFORCE LIMITS',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _CategoryCapRow extends StatelessWidget {
  final String category;
  final double spent;
  final double cap;
  final ValueChanged<double> onChanged;

  const _CategoryCapRow({required this.category, required this.spent, required this.cap, required this.onChanged});

  IconData get _icon {
    switch (category) {
      case 'Food': return Icons.restaurant_rounded;
      case 'Clothing': return Icons.shopping_bag_rounded;
      case 'Travel': return Icons.flight_takeoff_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = cap <= 0 ? 0.0 : (spent / cap).clamp(0.0, 1.0).toDouble();
    final over = spent > cap;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
              Text(
                'PKR ${spent.toStringAsFixed(0)} / PKR ${cap.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: over ? AppColors.danger : AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(over ? AppColors.danger : AppColors.primary),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
            child: Slider(
              value: cap.clamp(500, 10000).toDouble(),
              min: 500,
              max: 10000,
              divisions: 19,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              label: 'PKR ${cap.toStringAsFixed(0)}',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}