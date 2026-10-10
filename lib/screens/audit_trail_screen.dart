import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_signals.dart';

class AuditTrailScreen extends StatefulWidget {
  final String userId; // 🚨 FIXED: Now accepts the ID from main.dart

  const AuditTrailScreen({super.key, required this.userId});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _auditLogs = [];
  bool _isLoading = true;
  String? _loadError;

  @override
    void initState() {
      super.initState();
      AppSignals.auditChanged.addListener(_onSignal);
      _fetchAuditLogs();
    }

    @override
      void dispose() {
        AppSignals.auditChanged.removeListener(_onSignal);
        super.dispose();
      }

      void _onSignal() => _fetchAuditLogs(silent: true);

    Future<void> _fetchAuditLogs({bool silent = false}) async {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _loadError = null;
        });
      }
      try {
        final logs = await _api.getAuditLog();
        if (!mounted) return;
        setState(() {
          _auditLogs = logs;
          _isLoading = false;
          _loadError = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (!silent) _loadError = 'Could not load your activity.';
        });
      }
    }

  String _formatTime(String rawIsoDate) {
    try {
      final t = DateTime.parse(rawIsoDate).toLocal();
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      final ampm = t.hour >= 12 ? 'PM' : 'AM';
      return '${t.month}/${t.day} \u00b7 $h:$m $ampm';
    } catch (e) {
      return "Unknown time";
    }
  }

  ({IconData icon, Color color, String label}) _getVisualConfig(String eventType) {
    switch (eventType.toUpperCase()) {
      case "REJECTED":
      case "DENIED":
        return (icon: Icons.block_rounded, color: AppColors.danger, label: 'Denied');
      case "APPROVED":
      case "EXECUTED":
      case "COMPLETED":
        return (icon: Icons.verified_rounded, color: AppColors.success, label: 'Approved');
      case "FAILED":
        return (icon: Icons.error_outline_rounded, color: AppColors.danger, label: 'Could not complete');
      case "EXPIRED":
        return (icon: Icons.timer_off_rounded, color: AppColors.textMuted, label: 'Expired');
      case "DRAFTED":
      case "PENDING":
      default:
        return (icon: Icons.pending_actions_rounded, color: AppColors.warning, label: 'Drafted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState()
          : _auditLogs.isEmpty
      // 🚨 FIXED: Reverted the empty state back to a simple string
          ? const Center(
          child: Text('No activity yet.', style: TextStyle(color: AppColors.textSecondary)))
          : RefreshIndicator(
        onRefresh: _fetchAuditLogs,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _auditLogs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = _auditLogs[index];

            // 🚨 FIXED: The status check is here inside the builder
            final v = _getVisualConfig(log['eventType'] ?? log['action'] ?? 'DRAFTED');

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: v.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(v.icon, color: v.color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          // 🚨 FIXED: The detail check belongs down here where 'log' actually exists
                          log['detailsJson'] ?? log['payload'] ?? log['detail'] ?? 'No details available',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(log['timestamp'] ?? ''),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
          OutlinedButton(onPressed: _fetchAuditLogs, child: const Text('Retry')),
        ],
      ),
    );
  }
}