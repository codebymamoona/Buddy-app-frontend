import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class AuditTrailScreen extends StatefulWidget {
  final String userId; // 🚨 ZERO-TRUST INJECTION

  const AuditTrailScreen({super.key, required this.userId});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  List<dynamic> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      // 🚨 SECURE TUNNEL + DYNAMIC ID
      final response = await http.get(Uri.parse('http://127.0.0.1:8080/api/audit-log?userId=${widget.userId}'));

      if (response.statusCode == 200) {
        setState(() {
          _auditLogs = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
      return "Unknown Time";
    }
  }

  ({IconData icon, Color color, String label}) _getVisualConfig(String eventType) {
    switch (eventType.toUpperCase()) {
      case "REJECTED":
        return (icon: Icons.block_rounded, color: AppColors.danger, label: 'Blocked by User');
      case "APPROVED":
        return (icon: Icons.verified_rounded, color: AppColors.success, label: 'Authorized');
      case "DRAFTED":
      default:
        return (icon: Icons.pending_actions_rounded, color: AppColors.warning, label: 'AI Drafted Order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auditLogs.isEmpty
          ? const Center(child: Text('No audit records found.', style: TextStyle(color: AppColors.textSecondary)))
          : RefreshIndicator(
        onRefresh: _fetchAuditLogs,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _auditLogs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = _auditLogs[index];

            // 🚨 MATCHING THE EXACT JSON KEYS FROM SPRING BOOT 'AuditLogResponse' DTO
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
                      color: v.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(v.icon, color: v.color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          log['detail'] ?? 'No payload data', // 🚨 'detail' instead of 'detailsJson'
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(log['timestamp'] ?? ''), // 🚨 'timestamp' instead of 'createdAt'
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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
}