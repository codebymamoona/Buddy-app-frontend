import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_signals.dart';

class ApprovalScreen extends StatefulWidget {
  final String userId;

  const ApprovalScreen({super.key, required this.userId});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _Outcome {
  final String title;
  final String detail;
  final bool success;
  const _Outcome(this.title, this.detail, this.success);
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _pendingActions = [];
  final List<_Outcome> _outcomes = [];
  bool _isLoading = true;
  String? _loadError;
  final Set<int> _submittingIds = {};

  @override
  void initState() {
    super.initState();
    AppSignals.approvalsChanged.addListener(_onApprovalsChanged);
    AppSignals.focusActionId.addListener(_onFocusChanged);
    _fetchPendingActions();
  }

  @override
  void dispose() {
    AppSignals.approvalsChanged.removeListener(_onApprovalsChanged);
    AppSignals.focusActionId.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onApprovalsChanged() => _fetchPendingActions(silent: true);
  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchPendingActions({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final actions = await _api.getPendingActions();
      if (!mounted) return;
      final list = actions.map((a) => Map<String, dynamic>.from(a as Map)).toList();
      AppSignals.pendingCount.value = list.length;
      setState(() {
        _pendingActions = list;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent || _pendingActions.isEmpty) {
          _loadError = 'Could not load pending actions.';
        }
      });
    }
  }

  Future<void> _submitDecision(Map<String, dynamic> action, String decision) async {
    final id = (action['id'] as num).toInt();
    final approving = decision == "APPROVE";
    final description = _describe(action);
    setState(() => _submittingIds.add(id));

    final result = await _api.submitActionDecisionDetailed(id, decision);
    if (!mounted) return;

    setState(() {
      _submittingIds.remove(id);
      if (result.ok) {
        _outcomes.insert(
            0, _Outcome(approving ? 'Order approved' : 'Order denied', description, true));
      } else {
        _outcomes.insert(
            0,
            _Outcome("Couldn't ${approving ? 'approve' : 'deny'} this order",
                '$description\n${result.message}', false));
      }
    });
    AppSignals.notifyChat(result.ok
        ? (approving
        ? 'Order approved: $description. Your order is being processed, please wait.'
        : 'Order denied: $description. Nothing was charged.')
        : "I couldn't complete that: ${result.message} ($description)");
    if (AppSignals.focusActionId.value == id) AppSignals.focusActionId.value = null;
    AppSignals.refreshAudit();
    await _fetchPendingActions(silent: true);
  }

  // ---------- helpers ----------

  Map<String, dynamic> _payloadOf(Map<String, dynamic> action) {
    final raw = action['payload']?.toString() ?? '{}';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {"Details": raw};
  }

  String _pkr(num v) {
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return 'PKR ${parts.length > 1 ? '$whole.${parts[1]}' : whole}';
  }

  String _clock(Object? iso) {
    if (iso == null) return '—';
    try {
      final t = DateTime.parse(iso.toString());
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '—';
    }
  }

  String _describe(Map<String, dynamic> action) {
    final p = _payloadOf(action);
    final cost = (action['cost'] as num?) ?? 0;
    final notes = p['notes']?.toString() ?? '';
    String what;
    if (p['airline'] != null && p['origin'] != null) {
      what = 'Flight ${p['origin']} → ${p['destination']} · ${p['airline']}';
    } else if (p['item'] != null) {
      final extra = [p['size'], p['color']].where((v) => v != null).join(' ');
      what = '${extra.isNotEmpty ? '$extra ' : ''}${p['item']}${p['brand'] != null ? ' · ${p['brand']}' : ''}';
    } else {
      what = '${action['toolName'] ?? 'Action'}';
    }
    return '$what${notes.isNotEmpty ? ' ($notes)' : ''} · ${_pkr(cost)} · Ref #${action['id']}';
  }

  List<Map<String, dynamic>> _ordered() {
    final focus = AppSignals.focusActionId.value;
    final focused = _pendingActions.where((a) => (a['id'] as num).toInt() == focus);
    final rest = _pendingActions.where((a) => (a['id'] as num).toInt() != focus);
    return [...focused, ...rest];
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: AppColors.bg, body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(backgroundColor: AppColors.bg, body: _buildErrorState());
    }

    final ordered = _ordered();
    final focus = AppSignals.focusActionId.value;
    final children = <Widget>[
      ..._outcomes.map(_buildOutcomeBanner),
      ...ordered.map((a) => _buildReceiptCard(a, focused: (a['id'] as num).toInt() == focus)),
      if (ordered.isEmpty) _buildEmptyHint(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetchPendingActions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildOutcomeBanner(_Outcome o) {
    final color = o.success ? AppColors.success : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(o.success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(o.detail,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _outcomes.remove(o)),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> action, {required bool focused}) {
    final id = (action['id'] as num).toInt();
    final payload = _payloadOf(action);
    final cost = (action['cost'] as num?)?.toDouble() ?? 0.0;
    final isFood = payload['item'] != null && payload['brand'] != null;
    final qty = (payload['quantity'] as num?)?.toInt() ?? 1;
    final notes = payload['notes']?.toString() ?? '';
    final isSubmitting = _submittingIds.contains(id);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: focused ? AppColors.primary : AppColors.border, width: focused ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Order summary',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('Ref #$id',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            if (focused) ...[
              const SizedBox(height: 8),
              const Text('From your chat',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const Divider(height: 28, color: AppColors.border),
            if (isFood) ...[
              Text('${payload['brand']}',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _row('$qty × ${payload['item']}', _pkr(cost)),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Note: $notes',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ] else ...[
              Text('${action['toolName'] ?? 'Buddy AI'}',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...payload.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${e.key}: ${e.value}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              )),
            ],
            const Divider(height: 28, color: AppColors.border),
            _row('Total', _pkr(cost), bold: true),
            const SizedBox(height: 12),
            Text(
              'Drafted ${_clock(action['createdAt'])} · Expires ${_clock(action['expiresAt'])}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text('Nothing is charged until you approve.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : () => _submitDecision(action, "REJECT"),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger),
                    child: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () => _submitDecision(action, "APPROVE"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: isSubmitting
                        ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Approve ${_pkr(cost)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    final style = TextStyle(
      color: bold ? AppColors.primary : AppColors.textPrimary,
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(left, style: style)),
        const SizedBox(width: 12),
        Text(right, style: style),
      ],
    );
  }

  Widget _buildEmptyHint() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, color: AppColors.success, size: 48),
          SizedBox(height: 16),
          Text('Nothing waiting on you',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('No actions are pending approval.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_loadError ?? 'Something went wrong.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _fetchPendingActions, child: const Text('Retry')),
        ],
      ),
    );
  }
}