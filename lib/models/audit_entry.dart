import 'dart:convert';

class AuditEntry {
  final int id;
  final String brand;
  final String item;
  final double cost;
  final DateTime timestamp;
  final String status;
  final String? reason;

  AuditEntry({
    required this.id,
    required this.brand,
    required this.item,
    required this.cost,
    required this.timestamp,
    required this.status,
    this.reason,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    // Spring Boot sends the audit details as a JSON string (sometimes plain text).
    final raw = (json['detailsJson'] ?? json['details_json'] ?? '{}').toString();

    Map<String, dynamic> details = {};
    String? plainText;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        details = Map<String, dynamic>.from(decoded);
      } else {
        plainText = raw;
      }
    } catch (_) {
      plainText = raw; // not JSON: keep it as the reason text
    }

    final createdAt = (json['createdAt'] ?? json['created_at'])?.toString();

    return AuditEntry(
      id: (json['actionId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      brand: details['brand']?.toString() ?? 'System',
      item: details['item']?.toString() ?? 'Unknown Item',
      cost: (details['cost'] as num?)?.toDouble() ?? 0.0,
      timestamp: (createdAt != null ? DateTime.tryParse(createdAt) : null) ?? DateTime.now(),
      status: (json['eventType'] ?? json['status'] ?? 'UNKNOWN').toString(),
      reason: details['reason']?.toString() ?? plainText,
    );
  }
}