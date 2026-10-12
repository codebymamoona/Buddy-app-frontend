/// Compile-time switches, set with --dart-define. Nothing here is on by default.
class AppMode {
  AppMode._();

  static const bool useMock = bool.fromEnvironment('USE_MOCK');
  static const int mockDelayMs = int.fromEnvironment('MOCK_DELAY_MS', defaultValue: 900);
  /// MOCK_START=login shows the login screen instead of the app, for restyling it.
  static const String start = String.fromEnvironment('MOCK_START');
  static const String _fail = String.fromEnvironment('MOCK_FAIL');
  static const String _empty = String.fromEnvironment('MOCK_EMPTY');

  /// Endpoint names: chat, pending, audit, decision, cap
  static bool fails(String endpoint) => _has(_fail, endpoint);
  static bool isEmpty(String endpoint) => _has(_empty, endpoint);

  static bool _has(String list, String name) =>
      list.split(',').map((s) => s.trim()).contains(name);
}