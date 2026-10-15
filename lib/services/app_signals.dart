import 'package:flutter/foundation.dart';

/// A message for the chat. Each notice is a new object, so identical text still notifies listeners.
class ChatNotice {
  final String text;
  ChatNotice(this.text);
}

/// Tiny cross-screen signals so tabs inside the IndexedStack refetch when they matter.
class AppSignals {
  AppSignals._();
  static final ValueNotifier<int> approvalsChanged = ValueNotifier<int>(0);
  static final ValueNotifier<int> auditChanged = ValueNotifier<int>(0);
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  static final ValueNotifier<int?> focusActionId = ValueNotifier<int?>(null);
  static final ValueNotifier<ChatNotice?> chatNotice = ValueNotifier<ChatNotice?>(null);

  static void refreshApprovals() => approvalsChanged.value++;
  static void refreshAudit() => auditChanged.value++;
  static void notifyChat(String text) => chatNotice.value = ChatNotice(text);
}