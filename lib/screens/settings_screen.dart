"settings_screen"

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
const SettingsScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: const BuddyAppBar(title: 'Settings'),
body: ListView(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
children: [
Center(
child: Column(
children: [
Image.asset('assets/images/logo_transparent.png', height: 96),
const SizedBox(height: 10),
const Text('Buddy AI Agent', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
const Text('Your AI buddy for every important moment.',
style: TextStyle(color: AppColors.grey, fontSize: 12.5), textAlign: TextAlign.center),
],
),
),
const SizedBox(height: 26),
FormCard(
children: [
const SectionHeader(icon: Icons.account_balance_wallet_outlined, title: 'Spending controls'),
const SizedBox(height: 14),
_SettingRow(label: 'Monthly cap (Rs)', value: AppState.instance.monthlyCap.toStringAsFixed(0)),
const Divider(height: 26),
const _SettingRow(label: 'Require approval above', value: 'Rs 200'),
const Divider(height: 26),
_SwitchRow(label: 'Auto-approve small orders'),
],
),
const SizedBox(height: 18),
FormCard(
children: [
const SectionHeader(icon: Icons.notifications_outlined, title: 'Notifications'),
const SizedBox(height: 14),
_SwitchRow(label: 'Push notifications', initial: true),
const Divider(height: 26),
_SwitchRow(label: 'Birthday reminders', initial: true),
],
),
const SizedBox(height: 18),
FormCard(
children: [
const SectionHeader(icon: Icons.palette_outlined, title: 'Appearance'),
const SizedBox(height: 14),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text('Dark theme', style: TextStyle(fontSize: 14)),
Row(
children: [
Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
const SizedBox(width: 6),
const Text('Always on', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
],
),
],
),
],
),
],
),
);
}
}

class _SettingRow extends StatelessWidget {
final String label;
final String value;
const _SettingRow({required this.label, required this.value});

@override
Widget build(BuildContext context) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(label, style: const TextStyle(fontSize: 14)),
Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRed)),
],
);
}
}

class _SwitchRow extends StatefulWidget {
final String label;
final bool initial;
final ValueChanged<bool>? onChanged;
const _SwitchRow({required this.label, this.initial = false, this.onChanged});

@override
State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
late bool value = widget.initial;

@override
Widget build(BuildContext context) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(widget.label, style: const TextStyle(fontSize: 14)),
Switch(
value: value,
activeColor: AppColors.primaryRed,
onChanged: (v) {
setState(() => value = v);
widget.onChanged?.call(v);
},
),
],
);
}
}
