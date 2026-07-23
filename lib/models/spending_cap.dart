class SpendingCap {
  final double limit;
  final double used;
  SpendingCap({required this.limit, required this.used});

  double get remaining => limit - used;
  double get usedFraction => limit == 0 ? 0 : (used / limit).clamp(0, 1);
}