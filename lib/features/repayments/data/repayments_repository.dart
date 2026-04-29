import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_service.dart';

class RepaymentResult {
  final bool queued;
  final Map<String, dynamic>? data;
  const RepaymentResult({required this.queued, this.data});
}

class RepaymentsRepository {
  RepaymentsRepository(this._api, this._sync, this._isOnline);
  final ApiClient _api;
  final SyncService _sync;
  final bool Function() _isOnline;

  Future<RepaymentResult> pay({
    required int farmerId,
    num? amountFcfa,
    num? commodityKg,
    num? commodityRate,
    String? commodityName,
    String method = 'cash',
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'farmer_id': farmerId,
      if (amountFcfa != null) 'amount': amountFcfa,
      if (commodityKg != null) 'commodity_kg': commodityKg,
      if (commodityRate != null) 'commodity_rate': commodityRate,
      if (commodityName != null && commodityName.isNotEmpty)
        'commodity_name': commodityName,
      'method': commodityKg != null ? 'commodity' : method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    if (!_isOnline()) {
      await _sync.enqueue(
        method: 'POST',
        path: '/repayments',
        body: body,
        label:
            'Remboursement ${(amountFcfa ?? (commodityKg ?? 0) * (commodityRate ?? 0)).toStringAsFixed(0)} FCFA',
      );
      return const RepaymentResult(queued: true);
    }
    final res = await _api.request<Map<String, dynamic>>(
      '/repayments',
      method: 'POST',
      body: body,
    );
    return RepaymentResult(queued: false, data: res);
  }
}

final repaymentsRepositoryProvider = Provider<RepaymentsRepository>((ref) {
  return RepaymentsRepository(
    ref.read(apiClientProvider),
    ref.read(syncServiceProvider),
    () => ref.read(isOnlineProvider),
  );
});
