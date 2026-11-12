import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_signals.dart';
import 'spending_cap_settings_screen.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

/// Wallet: balance, today's spending against the daily and travel limits, sandbox top-up, and recent history.
/// All numbers come from the server; nothing here is computed from guesses.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _service = WalletService();
  final TextEditingController _custom = TextEditingController();

  WalletSummary? _wallet;
  String? _error;
  bool _loading = true;
  bool _busy = false; // a top-up is in flight
  String? _fieldError; // shown under the amount field, never in a banner over it

  static const List<int> _presets = [1000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    AppSignals.approvalsChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppSignals.approvalsChanged.removeListener(_load);
    _custom.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _service.getWallet();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _wallet = r.data;
        _error = null;
      } else {
        _error = r.message;
      }
    });
  }

  /// Why this amount cannot be added right now, or null if it can.
  String? _invalid(int amount, WalletSummary w) {
    if (amount < w.topUpMin) return 'Enter at least PKR ${_pkr(w.topUpMin)}.';
    if (amount > w.topUpMax) return 'One top-up can be at most PKR ${_pkr(w.topUpMax)}.';
    if (w.balance + amount > w.maxBalance) {
      final room = (w.maxBalance - w.balance).floor();
      return room <= 0
          ? 'Your wallet is full (limit PKR ${_pkr(w.maxBalance)}).'
          : 'That goes over the PKR ${_pkr(w.maxBalance)} limit. You can add up to PKR ${_pkr(room)}.';
    }
    return null;
  }

  Future<void> _topUp(int amount) async {
    final w = _wallet;
    if (w == null || _busy) return;
    final problem = _invalid(amount, w);
    if (problem != null) {
      setState(() => _fieldError = problem);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
    });
    final r = await _service.topUp(amount);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _custom.clear();
      FocusScope.of(context).unfocus();
      _snack('Added PKR ${_pkr(amount)} of sandbox money.');
      await _load();
    } else {
      setState(() => _fieldError = r.message);
      await _load(); // the state may have changed (flag off, limit reached)
    }
  }

  void _topUpCustom() {
    final amount = int.tryParse(_custom.text.trim());
    if (amount == null) {
      setState(() => _fieldError = 'Enter a whole number of rupees.');
      return;
    }
    _topUp(amount);
  }

  /// Success messages only. Errors go under the field so they never cover what the user is fixing.
  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ---------- formatting ----------

  static String _pkr(num v) {
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _when(DateTime? d) {
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]}, $h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Wallet', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final w = _wallet;
    if (w == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(_error ?? "Couldn't load your wallet.",
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _balanceCard(w),
          const SizedBox(height: 16),
          _todayCard(w),
          const SizedBox(height: 16),
          if (w.topUpEnabled) ...[_topUpCard(w), const SizedBox(height: 16)],
          _historyCard(w),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  );

  Widget _balanceCard(WalletSummary w) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text('PKR ${_pkr(w.balance)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Sandbox money. It is not real and cannot be withdrawn.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _todayCard(WalletSummary w) {
    final cap = w.dailyCap.toDouble();
    final spent = w.spentToday.toDouble();
    final fraction = cap <= 0 ? 0.0 : (spent / cap).clamp(0.0, 1.0);
    final travelCap = w.travelCap.toDouble();
    final travelFraction = travelCap <= 0 ? 0.0 : (w.travelSpentToday.toDouble() / travelCap).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: fraction >= 1 ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Food, shopping and gifts',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          _kv('Spent today', 'PKR ${_pkr(w.spentToday)}'),
          _kv('Daily limit', 'PKR ${_pkr(w.dailyCap)}'),
          _kv('Left to spend today', 'PKR ${_pkr(w.remainingToday)}'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          const Text('Travel (flights)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: travelFraction,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: travelFraction >= 1 ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _kv('Spent on travel today', 'PKR ${_pkr(w.travelSpentToday)}'),
          _kv('Travel limit', 'PKR ${_pkr(w.travelCap)}'),
          _kv('Left for travel today', 'PKR ${_pkr(w.travelRemainingToday)}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Change limits'),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SpendingCapScreen()));
                if (mounted) _load(); // the limit may have changed
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(v, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    ),
  );

  Widget _topUpCard(WalletSummary w) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add sandbox money',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Up to PKR ${_pkr(w.topUpMax)} at a time. Wallet limit PKR ${_pkr(w.maxBalance)}.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                OutlinedButton(
                  // Disabled when it would break a rule, so the user never taps into a known failure.
                  onPressed: (_busy || _invalid(p, w) != null) ? null : () => _topUp(p),
                  child: Text('+${_pkr(p)}'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // keeps ADD put when an error line appears under the field
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Exact amount (PKR)',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    errorText: _fieldError,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    if (_fieldError != null) setState(() => _fieldError = null);
                  },
                  onSubmitted: (_) => _topUpCustom(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _busy ? null : _topUpCustom,
                child: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ADD'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyCard(WalletSummary w) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent activity',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          if (w.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing yet. Approved orders and top-ups will show up here.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            )
          else
            for (var i = 0; i < w.history.length; i++) ...[
              if (i > 0) const Divider(color: AppColors.border, height: 1),
              _historyRow(w.history[i]),
            ],
        ],
      ),
    );
  }

  Widget _historyRow(WalletEntry e) {
    final sign = e.isTopUp ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(e.isTopUp ? Icons.add_circle_outline : Icons.shopping_bag_outlined,
              color: e.isTopUp ? AppColors.primary : AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_when(e.at), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$sign PKR ${_pkr(e.amount)}',
              style: TextStyle(
                  color: e.isTopUp ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}