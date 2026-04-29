import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../domain/cart.dart';

class CartController extends StateNotifier<CartState> {
  CartController() : super(const CartState());

  void add(Product p, {num qty = 1}) {
    final idx = state.items.indexWhere((i) => i.product.id == p.id);
    if (idx >= 0) {
      final updated = [...state.items];
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + qty);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: p, quantity: qty)]);
    }
  }

  void setQty(int productId, num qty) {
    if (qty <= 0) return remove(productId);
    state = state.copyWith(
      items: [
        for (final it in state.items)
          if (it.product.id == productId) it.copyWith(quantity: qty) else it,
      ],
    );
  }

  void remove(int productId) {
    state = state.copyWith(
      items: state.items.where((it) => it.product.id != productId).toList(),
    );
  }

  void setMode(PaymentMode m) => state = state.copyWith(mode: m);
  void setInterestRate(double r) => state = state.copyWith(interestRate: r);
  void setFarmer(int? id) => state =
      id == null ? state.copyWith(clearFarmer: true) : state.copyWith(farmerId: id);

  void clear() => state = const CartState();
}

final cartProvider =
    StateNotifierProvider<CartController, CartState>((_) => CartController());

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).items.fold<num>(0, (a, b) => a + b.quantity).toInt();
});
