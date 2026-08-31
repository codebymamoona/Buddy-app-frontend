"APPROVAL SCREEN"

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/approval.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ApprovalScreen extends StatefulWidget {
const ApprovalScreen({super.key});

@override
State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
final AppState _state = AppState.instance;

@override
void initState() {
super.initState();
_state.addListener(_refresh);
}

@override
void dispose() {
_state.removeListener(_refresh);
super.dispose();
}

void _refresh() => setState(() {});

@override
Widget build(BuildContext context) {
final pending = _state.pendingApprovals;
return Scaffold(
appBar: const BuddyAppBar(title: 'Approval Needed', trailing: UserAvatar()),
body: pending.isEmpty
? _EmptyState()
    : ListView.builder(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
itemCount: pending.length,
itemBuilder: (context, i) => _ApprovalCard(request: pending[i]),
),
);
}
}

class _ApprovalCard extends StatelessWidget {
final ApprovalRequest request;
const _ApprovalCard({required this.request});

@override
Widget build(BuildContext context) {
final state = AppState.instance;
final usage = state.spent;
final cap = state.monthlyCap;
final ratio = (usage / cap).clamp(0.0, 1.0);

return TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: 1),
duration: const Duration(milliseconds: 420),
curve: Curves.easeOutCubic,
builder: (context, t, child) => Opacity(
opacity: t,
child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
),
child: Column(
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
decoration: BoxDecoration(
color: AppColors.white,
borderRadius: BorderRadius.circular(24),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
),
child: Column(
children: [
Container(
width: 64,
height: 64,
decoration: BoxDecoration(color: const Color(0xFFFCEBD8), borderRadius: BorderRadius.circular(20)),
child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFE08A1F), size: 30),
),
const SizedBox(height: 18),
const Text('Buddy wants to spend', style: TextStyle(color: AppColors.grey, fontSize: 13.5)),
const SizedBox(height: 6),
Text('Rs ${request.amount.toStringAsFixed(0)}',
style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.pureBlack)),
const SizedBox(height: 6),
Text(request.title, style: const TextStyle(color: AppColors.pureBlack, fontSize: 14.5), textAlign: TextAlign.center),
],
),
),
const SizedBox(height: 16),
Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text('Monthly cap usage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
Text('Rs ${usage.toStringAsFixed(0)} / Rs ${cap.toStringAsFixed(0)}',
style: const TextStyle(color: AppColors.grey, fontSize: 12.5)),
],
),
const SizedBox(height: 10),
ClipRRect(
borderRadius: BorderRadius.circular(20),
child: TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: ratio),
duration: const Duration(milliseconds: 700),
curve: Curves.easeOutCubic,
builder: (context, value, _) => LinearProgressIndicator(
value: value,
minHeight: 9,
backgroundColor: AppColors.border,
valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
),
),
),
],
),
),
const SizedBox(height: 22),
PrimaryButton(
label: 'Approve',
icon: Icons.check_rounded,
onPressed: () => AppState.instance.approve(request),
),
const SizedBox(height: 12),
_DenyButton(onPressed: () => AppState.instance.deny(request)),
],
),
);
}
}

class _DenyButton extends StatelessWidget {
final VoidCallback onPressed;
const _DenyButton({required this.onPressed});

@override
Widget build(BuildContext context) {
return SecondaryButton(label: '✕  Deny', onPressed: onPressed, color: AppColors.danger);
}
}

class _EmptyState extends StatelessWidget {
@override
Widget build(BuildContext context) {
return Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 84,
height: 84,
decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.08), shape: BoxShape.circle),
child: const Icon(Icons.task_alt_rounded, color: AppColors.primaryRed, size: 40),
),
const SizedBox(height: 18),
const Text('All caught up!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
const SizedBox(height: 6),
const Text('No approvals waiting right now.', style: TextStyle(color: AppColors.grey)),
],
),
);
}
}
