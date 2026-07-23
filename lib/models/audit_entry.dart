class AuditEntry {
  final DateTime timestamp;
  final String action;
  final String detail;
  final bool immutable;

  AuditEntry({
    required this.timestamp,
    required this.action,
    required this.detail,
    this.immutable = true,
  });
}