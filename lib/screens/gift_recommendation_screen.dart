"gift_screen'

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_logo.dart';
import '../widgets/common.dart';

class GiftsScreen extends StatelessWidget {
const GiftsScreen({super.key});

@override
Widget build(BuildContext context) {
final gifts = [
('Scented candle set', 'Rs 1,200', 'For Ayesha · Birthday'),
('Perfume: Janan set', 'Rs 2,800', 'For Janan · Just because'),
('Cricket bat mini trophy', 'Rs 950', 'For Bilal · Congrats'),
];

return Scaffold(
appBar: const BuddyAppBar(title: 'Gift Ideas', trailing: UserAvatar()),
body: ListView.separated(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
itemCount: gifts.length,
separatorBuilder: (_, __) => const SizedBox(height: 12),
itemBuilder: (context, i) {
final g = gifts[i];
return TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: 1),
duration: Duration(milliseconds: 350 + i * 70),
curve: Curves.easeOutCubic,
builder: (context, t, child) => Opacity(opacity: t, child: Transform.scale(scale: 0.96 + 0.04 * t, child: child)),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppColors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
),
child: Row(
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(gradient: AppColors.redGradient, borderRadius: BorderRadius.circular(14)),
child: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
const SizedBox(height: 2),
Text(g.$3, style: const TextStyle(color: AppColors.grey, fontSize: 12.5)),
],
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text(g.$2, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRed)),
const SizedBox(height: 6),
ReactiveButton(
onTap: () {
final amount = double.parse(g.$2.replaceAll(RegExp(r'[^0-9.]'), ''));
AppState.instance.requestApproval(g.$1, amount);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Sent "${g.$1}" for approval')),
);
},
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
child: const Text('Send', style: TextStyle(color: Colors.white, fontSize: 12)),
),
),
],
),
],
),
),
);
},
),
);
}
}
