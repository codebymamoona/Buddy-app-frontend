import 'dart:convert';

class AuditEntry {
  final int id;
  final String brand;
  final String item;
  final double cost;
  final DateTime timestamp;
  final String status;

  AuditEntry({
    required this.id,
    required this.brand,
    required this.item,
    required this.cost,
    required this.timestamp,
    required this.status,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    // detailsJson is JSON for drafted/executed rows but a plain sentence for
    // rejected/expired/failed rows. Never assume it parses.
    Map<String, dynamic> details = {};
    String note = '';
    final raw = json['detailsJson'] ?? json['details_json'];
    if (raw is Map) {
      details = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          details = Map<String, dynamic>.from(decoded);
        } else {
          note = raw.trim();
        }
      } catch (_) {
        note = raw.trim();
      }
    }

    final idValue = json['actionId'] ?? json['id'];
    final createdRaw = json['createdAt'] ?? json['created_at'];

    return AuditEntry(
      id: idValue is num ? idValue.toInt() : 0,
      brand: details['brand']?.toString() ?? 'System',
      item: details['item']?.toString() ?? (note.isNotEmpty ? note : 'Unknown Item'),
      cost: double.tryParse('${details['cost'] ?? 0}') ?? 0.0,
      // A missing timestamp shows as 1970 on purpose: obviously wrong beats plausibly wrong.
      timestamp: DateTime.tryParse('${createdRaw ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['eventType'] ?? json['status'] ?? 'UNKNOWN').toString(),
    );
  }
}