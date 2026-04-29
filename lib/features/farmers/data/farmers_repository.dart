import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/farmer.dart';

class FarmersRepository {
  FarmersRepository(this._api, this._sync, this._isOnline);
  final ApiClient _api;
  final SyncService _sync;
  final bool Function() _isOnline;

  Future<List<Farmer>> search(String query) async {
    final box = HiveBoxes.box(HiveBoxes.farmers);

    Future<List<Farmer>> fromCache() async {
      final all = box.values
          .whereType<Map>()
          .map((m) => Farmer.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where((f) =>
              f.identifier.toLowerCase().contains(q) ||
              f.fullName.toLowerCase().contains(q) ||
              (f.phone ?? '').contains(q))
          .toList();
    }

    if (!_isOnline()) return fromCache();

    try {
      final raw = await _api.request<dynamic>(
        '/farmers',
        query: query.isEmpty ? null : {'search': query},
      );
      final list = _extractList(raw);
      final farmers =
          list.map((m) => Farmer.fromJson(Map<String, dynamic>.from(m))).toList();
      // refresh cache
      for (final f in farmers) {
        await box.put(f.id, f.toJson());
      }
      return farmers;
    } on Failure {
      return fromCache();
    }
  }

  Future<Farmer> getById(int id) async {
    final box = HiveBoxes.box(HiveBoxes.farmers);
    if (_isOnline()) {
      try {
        final raw = await _api.request<Map<String, dynamic>>('/farmers/$id');
        final f = Farmer.fromJson(raw);
        await box.put(f.id, f.toJson());
        return f;
      } on Failure {/* fall through */}
    }
    final cached = box.get(id);
    if (cached is Map) {
      return Farmer.fromJson(Map<String, dynamic>.from(cached));
    }
    throw Failure.unknown('Producteur introuvable hors ligne.');
  }

  Future<Farmer?> create(Map<String, dynamic> body) async {
    if (!_isOnline()) {
      await _sync.enqueue(
        method: 'POST',
        path: '/farmers',
        body: body,
        label: 'Création producteur ${body['first_name']} ${body['last_name']}',
      );
      return null;
    }
    final raw = await _api.request<Map<String, dynamic>>(
      '/farmers',
      method: 'POST',
      body: body,
    );
    final f = Farmer.fromJson(raw);
    await HiveBoxes.box(HiveBoxes.farmers).put(f.id, f.toJson());
    return f;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }
}

final farmersRepositoryProvider = Provider<FarmersRepository>((ref) {
  return FarmersRepository(
    ref.read(apiClientProvider),
    ref.read(syncServiceProvider),
    () => ref.read(isOnlineProvider),
  );
});
