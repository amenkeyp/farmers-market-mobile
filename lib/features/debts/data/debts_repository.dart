import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/debt.dart';

class DebtsRepository {
  DebtsRepository(this._api, this._isOnline);
  final ApiClient _api;
  final bool Function() _isOnline;

  Future<List<Debt>> list({int? farmerId, bool openOnly = true}) async {
    final box = HiveBoxes.box(HiveBoxes.debts);
    final query = <String, dynamic>{
      if (openOnly) 'open_only': 1,
      if (farmerId != null) 'farmer_id': farmerId,
      'sort': 'fifo',
    };

    Future<List<Debt>> fromCache() async {
      final all = box.values
          .whereType<Map>()
          .map((m) => Debt.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return all.where((d) {
        final okFarmer = farmerId == null || d.farmerId == farmerId;
        final okOpen = !openOnly || d.remainingAmount > 0;
        return okFarmer && okOpen;
      }).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(1970))
            .compareTo(b.createdAt ?? DateTime(1970)));
    }

    if (!_isOnline()) return fromCache();
    try {
      final raw = await _api.request<dynamic>('/debts', query: query);
      final list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
      final debts = list
          .whereType<Map>()
          .map((m) => Debt.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      // refresh cache for these farmer's debts
      if (farmerId != null) {
        final keys = box.keys.where((k) {
          final v = box.get(k);
          return v is Map && (v['farmer_id'] as num?)?.toInt() == farmerId;
        }).toList();
        await box.deleteAll(keys);
      }
      for (final d in debts) {
        await box.put(d.id, d.toJson());
      }
      return debts;
    } on Failure {
      return fromCache();
    }
  }
}

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return DebtsRepository(
    ref.read(apiClientProvider),
    () => ref.read(isOnlineProvider),
  );
});
