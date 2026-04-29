import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../errors/failure.dart';
import '../network/connectivity_service.dart';
import '../storage/hive_boxes.dart';

/// A queued mutation. Only POST/PUT/PATCH/DELETE are queued — never reads.
class QueuedOp {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final String label;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  QueuedOp({
    required this.id,
    required this.method,
    required this.path,
    required this.body,
    required this.label,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  factory QueuedOp.fromJson(Map<dynamic, dynamic> j) => QueuedOp(
        id: j['id'] as String,
        method: j['method'] as String,
        path: j['path'] as String,
        body: Map<String, dynamic>.from(j['body'] as Map),
        label: j['label'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        attempts: (j['attempts'] as int?) ?? 0,
        lastError: j['lastError'] as String?,
      );

  QueuedOp copyWith({int? attempts, String? lastError}) => QueuedOp(
        id: id,
        method: method,
        path: path,
        body: body,
        label: label,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError,
      );
}

/// Drains queued mutations FIFO when online. Each op carries a stable
/// `client_uuid` (in body) so the backend can dedupe replays.
class SyncService {
  SyncService(this._ref) {
    _ref.listen<bool>(isOnlineProvider, (_, online) {
      if (online) unawaited(drain());
    });
  }

  final Ref _ref;
  bool _running = false;
  static const _uuid = Uuid();

  Future<void> enqueue({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    final box = HiveBoxes.box(HiveBoxes.offlineQueue);
    final op = QueuedOp(
      id: _uuid.v4(),
      method: method,
      path: path,
      body: {...body, 'client_uuid': _uuid.v4()},
      label: label,
      createdAt: DateTime.now(),
    );
    await box.put(op.id, op.toJson());
    _ref.invalidate(pendingSyncCountProvider);
    unawaited(drain());
  }

  List<QueuedOp> pending() {
    final box = HiveBoxes.box(HiveBoxes.offlineQueue);
    final ops = box.values
        .whereType<Map>()
        .map(QueuedOp.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> drain() async {
    if (_running) return;
    if (!_ref.read(isOnlineProvider)) return;
    _running = true;
    try {
      final api = _ref.read(apiClientProvider);
      final box = HiveBoxes.box(HiveBoxes.offlineQueue);
      for (final op in pending()) {
        try {
          await api.request<dynamic>(op.path, method: op.method, body: op.body);
          await box.delete(op.id);
        } on Failure catch (e) {
          if (e.offline) break; // lost connection mid-drain
          // 4xx => giveUp ; 5xx/unknown => retry later, bump attempts
          final permanent = e.statusCode != null &&
              e.statusCode! >= 400 &&
              e.statusCode! < 500 &&
              e.statusCode != 408 &&
              e.statusCode != 429;
          if (permanent) {
            await box.delete(op.id);
          } else {
            await box.put(op.id,
                op.copyWith(attempts: op.attempts + 1, lastError: e.message).toJson());
            break;
          }
        }
      }
    } finally {
      _running = false;
      _ref.invalidate(pendingSyncCountProvider);
    }
  }
}

final syncServiceProvider = Provider<SyncService>(SyncService.new);

final pendingSyncCountProvider = Provider<int>((ref) {
  // Recomputed when invalidated by the SyncService.
  return ref.read(syncServiceProvider).pending().length;
});
