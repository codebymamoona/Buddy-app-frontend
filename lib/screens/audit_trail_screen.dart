"Audit_screen"

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/approval.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AuditScreen extends StatefulWidget {
const AuditScreen({super.key});

@override
State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
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
final items = _state.activity;
return Scaffold(
appBar: const BuddyAppBar(title: 'Activity Log', trailing: UserAvatar()),
body: items.isEmpty
? const Center(child: Text('No activity yet', style: TextStyle(color: AppColors.grey)))
    : ListView.separated(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
itemCount: items.length,
separatorBuilder: (_, __) => const SizedBox(height: 12),
itemBuilder: (context, i) => _ActivityTile(entry: items[i], delay: i),
),
);
}
}

class _ActivityTile extends StatelessWidget {
final ActivityEntry entry;
final int delay;
const _ActivityTile({required this.entry, required this.delay});

({IconData icon, Color color, String label}) get _visual {
switch (entry.kind) {
case ActivityKind.denied:
return (icon: Icons.close_rounded, color: AppColors.danger, label: 'Denied');
case ActivityKind.approved:
return (icon: Icons.check_rounded, color: AppColors.success, label: 'Approved');
case ActivityKind.orderPlaced:
return (icon: Icons.storefront_rounded, color: AppColors.primaryRed, label: 'Order placed');
}
}

String _formatTime(DateTime t) {
final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
final m = t.minute.toString().padLeft(2, '0');
final ampm = t.hour >= 12 ? 'PM' : 'AM';
return '${t.month}/${t.day} · $h:$m $ampm';
}

@override
Widget build(BuildContext context) {
final v = _visual;
return TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: 1),
duration: Duration(milliseconds: 380 + delay * 60),
curve: Curves.easeOutCubic,
builder: (context, t, child) => Opacity(
opacity: t,
child: Transform.translate(offset: Offset((1 - t) * 24, 0), child: child),
),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppColors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
),
child: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(color: v.color.withOpacity(0.12), shape: BoxShape.circle),
child: Icon(v.icon, color: v.color, size: 20),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(v.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
const SizedBox(height: 2),
Text(entry.title, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
const SizedBox(height: 2),
Text(_formatTime(entry.time), style: const TextStyle(color: Color(0xFFB6B6BA), fontSize: 11.5)),
],
),
),
Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
],
),
),
);
}
}
