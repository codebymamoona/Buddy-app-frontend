import 'package:flutter/foundation.dart';

/// Single source of truth for spending caps, category budgets, and
/// approval rules on the client side.
///
/// IMPORTANT: this is a UI-side reflection of budget state for display and
/// slider interactions only. It is NOT the authority on what has actually
/// been spent or approved — that lives in the backend's `pending_actions`
/// / `audit_log` tables. Never let a screen decide whether to execute a
/// spend based on this class; the HITL gate and spending-cap enforcement
/// happen server-side in the tool base class, regardless of what this
/// singleton shows the user.
class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  double _monthlyCap = 2000;
  double _approvalThreshold = 500;
  bool _autoApproveSmall = false;
  double _spent = 450;

  final Map<String, double> _categoryCaps = {
    'Food': 1000,
    'Gifts': 800,
    'Travel': 1500,
  };

  final Map<String, double> _categorySpent = {
    'Food': 450,
    'Gifts': 0,
    'Travel': 0,
  };

  double get monthlyCap => _monthlyCap;
  double get approvalThreshold => _approvalThreshold;
  bool get autoApproveSmall => _autoApproveSmall;
  double get spent => _spent;
  Map<String, double> get categoryCaps => Map.unmodifiable(_categoryCaps);
  Map<String, double> get categorySpent => Map.unmodifiable(_categorySpent);

  void updateMonthlyCap(double value) {
    _monthlyCap = value;
    notifyListeners();
  }

  void updateApprovalThreshold(double value) {
    _approvalThreshold = value;
    notifyListeners();
  }

  void setAutoApproveSmall(bool value) {
    _autoApproveSmall = value;
    notifyListeners();
  }

  void updateCategoryCap(String category, double value) {
    _categoryCaps[category] = value;
    notifyListeners();
  }

  /// Call this ONLY after the backend confirms an order was actually
  /// approved and executed (i.e. after your approval endpoint returns
  /// success) — never optimistically on button-tap. This keeps the
  /// displayed "spent" figure honest relative to the audit log.
  void recordSpend(String category, double amount) {
    _spent += amount;
    _categorySpent[category] = (_categorySpent[category] ?? 0) + amount;
    notifyListeners();
  }
}