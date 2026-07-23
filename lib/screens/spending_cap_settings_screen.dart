import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpendingCapSettingsScreen extends StatefulWidget {
  final double initialCap;
  final void Function(double newCap)? onSave;

  const SpendingCapSettingsScreen({super.key, required this.initialCap, this.onSave});

  @override
  State<SpendingCapSettingsScreen> createState() => _SpendingCapSettingsScreenState();
}

class _SpendingCapSettingsScreenState extends State<SpendingCapSettingsScreen> {
  late double _cap;

  @override
  void initState() {
    super.initState();
    _cap = widget.initialCap;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Monthly spending limit',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  'Rs ${_cap.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _cap,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    label: 'Rs ${_cap.toStringAsFixed(0)}',
                    onChanged: (v) => setState(() => _cap = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Rs 500', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    Text('Rs 10,000', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "This is enforced by Buddy's tool layer on the server — this screen only sets your preference.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => widget.onSave?.call(_cap),
          child: const Text('Save Limit'),
        ),
      ],
    );
  }
}