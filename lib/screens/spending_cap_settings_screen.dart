import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SpendingCapScreen extends StatefulWidget {
  const SpendingCapScreen({super.key});

  @override
  State<SpendingCapScreen> createState() => _SpendingCapScreenState();
}

class _SpendingCapScreenState extends State<SpendingCapScreen> {
  final AppState _state = AppState.instance;

  late double _monthlyCap = _state.monthlyCap;
  late double _threshold = _state.approvalThreshold;
  late bool _autoApprove = _state.autoApproveSmall;
  late final Map<String, double> _categoryDraft = Map.of(_state.categoryCaps);

  void _save() {
    _state.updateMonthlyCap(_monthlyCap);
    _state.updateApprovalThreshold(_threshold);
    _state.setAutoApproveSmall(_autoApprove);
    for (final entry in _categoryDraft.entries) {
      _state.updateCategoryCap(entry.key, entry.value);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spending cap settings saved.')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _state.spent;
    final ratio = _monthlyCap <= 0 ? 0.0 : (totalSpent / _monthlyCap).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: const BuddyAppBar(title: 'Spending Cap'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ---- Overall monthly cap ----
          FormCard(
            children: [
              const SectionHeader(icon: Icons.account_balance_wallet_outlined, title: 'Monthly cap'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rs ${totalSpent.toStringAsFixed(0)} spent', style: const TextStyle(color: AppColors.grey, fontSize: 12.5)),
                  Text('Rs ${_monthlyCap.toStringAsFixed(0)} cap',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 9,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 18),
              Slider(
                value: _monthlyCap,
                min: 500,
                max: 10000,
                divisions: 19,
                activeColor: AppColors.primary,
                label: 'Rs ${_monthlyCap.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _monthlyCap = v),
              ),
              const Align(
                alignment: Alignment.center,
                child: Text('Drag to set Buddy\'s total monthly budget', style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- Approval rules ----
          FormCard(
            children: [
              const SectionHeader(icon: Icons.rule_rounded, title: 'Approval rules'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto-approve small orders', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: _autoApprove,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _autoApprove = v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _autoApprove
                    ? 'Orders up to Rs ${_threshold.toStringAsFixed(0)} go through instantly — everything above still needs your approval.'
                    : 'Every order Buddy wants to place will wait for your approval, regardless of amount.',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _autoApprove ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_autoApprove,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Require approval above', style: TextStyle(fontSize: 13.5)),
                          Text('Rs ${_threshold.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _threshold.clamp(50, 1000).toDouble(),
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        activeColor: AppColors.primary,
                        label: 'Rs ${_threshold.toStringAsFixed(0)}',
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
          FormCard(
            children: [
              const SectionHeader(icon: Icons.pie_chart_outline_rounded, title: 'Category caps'),
              const SizedBox(height: 10),
              ..._categoryDraft.keys.map((category) => _CategoryCapRow(
                category: category,
                spent: _state.categorySpent[category] ?? 0,
                cap: _categoryDraft[category]!,
                onChanged: (v) => setState(() => _categoryDraft[category] = v),
              )),
            ],
          ),
          const SizedBox(height: 24),

          PrimaryButton(label: 'Save spending cap', icon: Icons.check_rounded, onPressed: _save),
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

  const _CategoryCapRow({
    required this.category,
    required this.spent,
    required this.cap,
    required this.onChanged,
  });

  IconData get _icon {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Gifts':
        return Icons.card_giftcard_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = cap <= 0 ? 0.0 : (spent / cap).clamp(0.0, 1.0).toDouble();
    final over = spent > cap;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              Text(
                'Rs ${spent.toStringAsFixed(0)} / Rs ${cap.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: over ? AppColors.danger : AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(over ? AppColors.danger : AppColors.primary),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 2),
            child: Slider(
              value: cap.clamp(100, 3000).toDouble(),
              min: 100,
              max: 3000,
              divisions: 29,
              activeColor: AppColors.primary,
              label: 'Rs ${cap.toStringAsFixed(0)}',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
