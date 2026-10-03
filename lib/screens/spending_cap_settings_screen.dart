import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SpendingCapScreen extends StatefulWidget {
  const SpendingCapScreen({super.key});

  @override
  State<SpendingCapScreen> createState() => _SpendingCapScreenState();
}

class _SpendingCapScreenState extends State<SpendingCapScreen> {
  final ApiService _api = ApiService();
  double _dailyCap = 5000;
  bool _isSaving = false;
  bool _isLoading = true;

  final bool _autoApproveLocked = true;
  final bool _categoryFirewallsLocked = true;

  double _threshold = 200;
  bool _autoApproveDraft = false;
  final Map<String, double> _categoryDraft = {
    'Food': 2000,
    'Clothing': 2000,
    'Travel': 1000,
  };

  @override
  void initState() {
    super.initState();
    _fetchCurrentCap();
  }

  Future<void> _fetchCurrentCap() async {
    try {
      final cap = await _api.getSpendingCap();
      if (!mounted) return;
      setState(() {
        if (cap != null) _dailyCap = cap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load your current cap. Showing default.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _saveCap() async {
    setState(() => _isSaving = true);
    try {
      final success = await _api.updateSpendingCap(_dailyCap);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily spending cap updated.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your cap.'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error: cannot reach the server.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Spending Controls',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildConfigCard(
            title: 'Daily Spending Cap',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Text(
                'PKR ${_dailyCap.toStringAsFixed(0)} cap per day',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _dailyCap,
                min: 500,
                max: 20000,
                divisions: 39,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: 'PKR ${_dailyCap.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _dailyCap = v),
              ),
              const Align(
                alignment: Alignment.center,
                child: Text('Drag to set your daily approval limit',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildConfigCard(
            title: 'Zero-Trust Rules',
            icon: Icons.rule_rounded,
            locked: _autoApproveLocked,
            lockedLabel: 'Pending supervisor sign-off \u2014 every order requires approval for now',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto-approve micro-orders', style: TextStyle(color: Colors.white, fontSize: 14)),
                  Switch(
                    value: _autoApproveDraft,
                    activeColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    onChanged: _autoApproveLocked ? null : (v) => setState(() => _autoApproveDraft = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _autoApproveDraft
                    ? 'Orders up to PKR ${_threshold.toStringAsFixed(0)} bypass manual approval.'
                    : 'Every single AI transaction requires your explicit authorization.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _autoApproveDraft ? 1 : 0.3,
                child: IgnorePointer(
                  ignoring: true,
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
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildConfigCard(
            title: 'Category Firewalls',
            icon: Icons.pie_chart_outline_rounded,
            locked: _categoryFirewallsLocked,
            lockedLabel: 'Coming in a future phase \u2014 not enforced yet',
            children: _categoryDraft.keys
                .map((category) => _CategoryCapRow(
              category: category,
              spent: 0,
              cap: _categoryDraft[category]!,
              onChanged: (v) {},
            ))
                .toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveCap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                'SAVE DAILY CAP',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool locked = false,
    String? lockedLabel,
  }) {
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
              if (locked) ...[
                const Spacer(),
                const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 16),
              ],
            ],
          ),
          if (locked && lockedLabel != null) ...[
            const SizedBox(height: 6),
            Text(lockedLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),
          Opacity(
            opacity: locked ? 0.5 : 1.0,
            child: IgnorePointer(ignoring: locked, child: Column(children: children)),
          ),
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
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Clothing':
        return Icons.shopping_bag_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = cap <= 0 ? 0.0 : (spent / cap).clamp(0.0, 1.0).toDouble();

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
                'PKR ${cap.toStringAsFixed(0)} cap',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}