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
    // Dig into the nested payload if your backend wraps it, otherwise use the root
    final payload = json['payload'] ?? json;

    return AuditEntry(
      id: json['id'] as int, // The real database primary key
      brand: payload['brand'] as String,
      item: payload['item'] as String,
      cost: (payload['cost'] as num).toDouble(),
      // Strict parsing of the ISO 8601 string from Spring Boot
      timestamp: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
    );
  }
}