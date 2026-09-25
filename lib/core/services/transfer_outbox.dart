import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-side outbox for transfer requests the backend refuses (403).
/// No endpoint is invented: entries wait on the phone as "pending" and
/// can be re-sent with [TransferService.requestTransfer] once the
/// `transfer:manage` permission is granted. Honest by design — the UI
/// labels these "On this device • not sent".
class OutboxTransfer {
  final String id;
  final String assetId;
  final String toLocationId;
  final String? reason;
  final String createdAt;

  const OutboxTransfer({
    required this.id,
    required this.assetId,
    required this.toLocationId,
    this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'toLocationId': toLocationId,
        if (reason != null) 'reason': reason,
        'createdAt': createdAt,
      };

  factory OutboxTransfer.fromJson(Map<String, dynamic> json) =>
      OutboxTransfer(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        toLocationId: (json['toLocationId'] ?? '').toString(),
        reason: json['reason']?.toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
      );
}

class TransferOutbox {
  static const _key = 'ast_transfer_outbox';

  static Future<List<OutboxTransfer>> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) =>
              OutboxTransfer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(OutboxTransfer t) async {
    final cur = await load();
    cur.removeWhere((e) => e.id == t.id);
    cur.insert(0, t);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(cur.map((e) => e.toJson()).toList()));
  }

  static Future<void> remove(String id) async {
    final cur = await load();
    cur.removeWhere((e) => e.id == id);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(cur.map((e) => e.toJson()).toList()));
  }
}
