import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/app_mode.dart';

/// One row of wallet history. `kind` is SPEND or TOPUP.
class WalletEntry {
  final String kind;
  final String label;
  final num amount;
  final DateTime? at;
  final num? balanceAfter;

  const WalletEntry({
    required this.kind,
    required this.label,
    required this.amount,
    required this.at,
    required this.balanceAfter,
  });

  bool get isTopUp => kind == 'TOPUP';

  factory WalletEntry.fromJson(Map<String, dynamic> j) => WalletEntry(
    kind: (j['kind'] ?? 'SPEND').toString(),
    label: (j['label'] ?? '').toString(),
    amount: (j['amount'] as num?) ?? 0,
    // The server sends local time with no zone suffix; DateTime.parse treats it as local. Do not convert again.
    at: DateTime.tryParse((j['at'] ?? '').toString()),
    balanceAfter: j['balanceAfter'] as num?,
  );
}

class WalletSummary {
  final num balance;
  final num dailyCap;
  final num spentToday;
  final num remainingToday;
  final num travelCap;
  final num travelSpentToday;
  final num travelRemainingToday;
  final num maxBalance;
  final bool topUpEnabled;
  final num topUpMin;
  final num topUpMax;
  final List<WalletEntry> history;

  const WalletSummary({
    required this.balance,
    required this.dailyCap,
    required this.spentToday,
    required this.remainingToday,
    required this.travelCap,
    required this.travelSpentToday,
    required this.travelRemainingToday,
    required this.maxBalance,
    required this.topUpEnabled,
    required this.topUpMin,
    required this.topUpMax,
    required this.history,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> j) {
    final top = (j['topUp'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final hist = (j['history'] as List?) ?? const [];
    return WalletSummary(
      balance: (j['balance'] as num?) ?? 0,
      dailyCap: (j['dailyCap'] as num?) ?? 0,
      spentToday: (j['spentToday'] as num?) ?? 0,
      remainingToday: (j['remainingToday'] as num?) ?? 0,
      travelCap: (j['travelCap'] as num?) ?? 0,
      travelSpentToday: (j['travelSpentToday'] as num?) ?? 0,
      travelRemainingToday: (j['travelRemainingToday'] as num?) ?? 0,
      maxBalance: (j['maxBalance'] as num?) ?? 0,
      topUpEnabled: top['enabled'] == true,
      topUpMin: (top['min'] as num?) ?? 1,
      topUpMax: (top['max'] as num?) ?? 0,
      history: hist.whereType<Map>().map((e) => WalletEntry.fromJson(e.cast<String, dynamic>())).toList(),
    );
  }
}

class WalletResult<T> {
  final bool ok;
  final int status;
  final String message;
  final T? data;
  const WalletResult(this.ok, this.status, this.message, [this.data]);
}

/// Wallet API calls. Kept separate from ApiService on purpose so the wallet feature never edits that file.
class WalletService {
  final http.Client _client;
  WalletService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/wallet
  Future<WalletResult<WalletSummary>> getWallet() async {
    if (AppMode.useMock) {
      return const WalletResult(false, 0, "The wallet isn't available in demo mode.");
    }
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/wallet'),
        headers: await ApiConfig.authHeaders(),
      );
      final code = response.statusCode;
      if (code == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return WalletResult(true, code, '', WalletSummary.fromJson(body));
      }
      if (code == 401) return WalletResult(false, code, 'Your session expired. Please sign in again.');
      return WalletResult(false, code, "Couldn't load your wallet. Pull down to retry.");
    } catch (_) {
      return const WalletResult(false, 0, "Couldn't reach the server. Pull down to retry.");
    }
  }

  /// POST /api/wallet/topup  (sandbox only; the server returns 404 when the flag is off).
  /// Whole rupees only. Messages are written here, not taken from the server, so they are always readable.
  ///
  /// Important: when the app cannot read the reply (status 0, or a 5xx), the server MAY have applied the
  /// top-up. Those cases must never claim "nothing was added"; they tell the user to check the balance.
  Future<WalletResult<num>> topUp(int amount) async {
    if (AppMode.useMock) {
      return const WalletResult(false, 0, "The wallet isn't available in demo mode.");
    }
    const unconfirmed = "We couldn't confirm that top-up. Check your balance below before trying again.";
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/wallet/topup'),
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode({'amount': amount}),
      );
      final code = response.statusCode;
      debugPrint('WALLET topup amount=$amount -> $code body=${response.body}');
      if (code == 200) {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          return WalletResult(true, code, '', (body['balance'] as num?) ?? 0);
        } catch (e) {
          // The server said 200 (the money moved) but the body was unreadable. Treat it as success.
          debugPrint('WALLET topup: 200 but unreadable body: $e');
          return const WalletResult(true, 200, '', 0);
        }
      }
      switch (code) {
        case 400:
          return WalletResult(false, code, 'Enter a whole amount within the allowed range.');
        case 401:
          return WalletResult(false, code, 'Your session expired. Please sign in again.');
        case 404:
          return WalletResult(false, code, 'Sandbox top-up is turned off.');
        case 422:
          return WalletResult(false, code, 'That would go over the wallet limit.');
        default:
          return WalletResult(false, code, unconfirmed);
      }
    } catch (e) {
      debugPrint('WALLET topup amount=$amount threw ${e.runtimeType}: $e');
      return const WalletResult(false, 0, unconfirmed);
    }
  }

  /// GET /api/users/me/travel-cap  (the server answers with a bare number)
  Future<WalletResult<double>> getTravelCap() async {
    if (AppMode.useMock) {
      return const WalletResult(false, 0, "The travel limit isn't available in demo mode.");
    }
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me/travel-cap'),
        headers: await ApiConfig.authHeaders(),
      );
      final code = response.statusCode;
      if (code == 200) {
        final v = double.tryParse(response.body.trim());
        if (v != null) return WalletResult(true, code, '', v);
        return WalletResult(false, code, "Couldn't read your travel limit.");
      }
      if (code == 401) return WalletResult(false, code, 'Your session expired. Please sign in again.');
      return WalletResult(false, code, "Couldn't load your travel limit.");
    } catch (_) {
      return const WalletResult(false, 0, "Couldn't reach the server.");
    }
  }

  /// PUT /api/users/me/travel-cap
  Future<WalletResult<double>> updateTravelCap(double cap) async {
    if (AppMode.useMock) {
      return const WalletResult(false, 0, "The travel limit isn't available in demo mode.");
    }
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/users/me/travel-cap'),
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode({'cap': cap}),
      );
      final code = response.statusCode;
      debugPrint('WALLET travel-cap $cap -> $code');
      if (code == 200) return WalletResult(true, code, '', cap);
      if (code == 400) return WalletResult(false, code, 'That travel limit is not valid.');
      if (code == 401) return WalletResult(false, code, 'Your session expired. Please sign in again.');
      return WalletResult(false, code, "Couldn't save the travel limit. Check the value shown and try again.");
    } catch (e) {
      debugPrint('WALLET travel-cap $cap threw ${e.runtimeType}: $e');
      return const WalletResult(false, 0, "Couldn't save the travel limit. Check the value shown and try again.");
    }
  }
}