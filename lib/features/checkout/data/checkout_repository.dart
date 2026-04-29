import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/cart.dart';

class CheckoutResult {
  final bool queued;
  final Map<String, dynamic>? transaction;
  const CheckoutResult({required this.queued, this.transaction});
}

class CheckoutRepository {
  CheckoutRepository(this._api, this._sync, this._isOnline);
  final ApiClient _api;
  final SyncService _sync;
  final bool Function() _isOnline;

  Future<CheckoutResult> checkout(CartState cart, {String? notes}) async {
    assert(cart.farmerId != null, 'Farmer is required for checkout');
    final body = <String, dynamic>{
      'farmer_id': cart.farmerId,
      'type': cart.mode == PaymentMode.cash ? 'cash' : 'credit',
      if (cart.mode == PaymentMode.credit) 'interest_rate': cart.interestRate,
      'items': [
        for (final it in cart.items)
          {'product_id': it.product.id, 'quantity': it.quantity},
      ],
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    if (!_isOnline()) {
      await _sync.enqueue(
        method: 'POST',
        path: '/transactions',
        body: body,
        label: 'Vente — ${cart.items.length} article(s)',
      );
      return const CheckoutResult(queued: true);
    }

    final res =
        await _api.request<Map<String, dynamic>>('/transactions', method: 'POST', body: body);
    return CheckoutResult(queued: false, transaction: res);
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(
    ref.read(apiClientProvider),
    ref.read(syncServiceProvider),
    () => ref.read(isOnlineProvider),
  );
});
