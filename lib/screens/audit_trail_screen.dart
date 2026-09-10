import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class AuditTrailScreen extends StatefulWidget {
  // Required real user ID — no hardcoded fallback. Caller must pass the
  // actual logged-in user's identity.
  final String userId;

  const AuditTrailScreen({super.key, required this.userId});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  List<dynamic> _auditLogs = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      // Plain HTTP to localhost — fine for local dev, NOT a secure channel.
      // Move to HTTPS + auth header before this talks to anything but
      // 127.0.0.1.
      final response =
      await http.get(Uri.parse('http://127.0.0.1:8080/api/audit-log?userId=${widget.userId}'));

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _auditLogs = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadError = 'Could not load your activity.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Network error: cannot reach the server.';
      });
    }
  }

  String _formatTime(String rawIsoDate) {
    try {
      final t = DateTime.parse(rawIsoDate).toLocal();
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      final ampm = t.hour >= 12 ? 'PM' : 'AM';
      return '${t.month}/${t.day} · $h:$m $ampm';
    } catch (e) {
      return "Unknown time";
    }
  }

  ({IconData icon, Color color, String label}) _getVisualConfig(String eventType) {
    switch (eventType.toUpperCase()) {
      case "REJECTED":
        return (icon: Icons.block_rounded, color: AppColors.danger, label: 'Denied');
      case "APPROVED":
        return (icon: Icons.verified_rounded, color: AppColors.success, label: 'Approved');
      case "DRAFTED":
      default:
        return (icon: Icons.pending_actions_rounded, color: AppColors.warning, label: 'Drafted, waiting on you');
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

            // Verify these keys against the real AuditLogResponse
            // DTO — if the backend actually sends detailsJson /
            // createdAt, these fallbacks will render silently
            // wrong instead of erroring.
            final v = _getVisualConfig(log['action'] ?? 'DRAFTED');

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
                          log['detail'] ?? 'No details available',
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