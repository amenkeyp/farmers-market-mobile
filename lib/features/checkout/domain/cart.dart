import '../../products/domain/product.dart';

class CartItem {
  final Product product;
  final num quantity;
  const CartItem({required this.product, required this.quantity});

  num get subtotal => product.price * quantity;

  CartItem copyWith({num? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

enum PaymentMode { cash, credit }

class CartState {
  final List<CartItem> items;
  final PaymentMode mode;
  final double interestRate; // e.g. 0.05 for 5%
  final int? farmerId;

  const CartState({
    this.items = const [],
    this.mode = PaymentMode.cash,
    this.interestRate = 0.05,
    this.farmerId,
  });

  num get subtotal =>
      items.fold<num>(0, (acc, it) => acc + it.subtotal);

  num get interestAmount =>
      mode == PaymentMode.credit ? (subtotal * interestRate) : 0;

  num get total => subtotal + interestAmount;

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    PaymentMode? mode,
    double? interestRate,
    int? farmerId,
    bool clearFarmer = false,
  }) =>
      CartState(
        items: items ?? this.items,
        mode: mode ?? this.mode,
        interestRate: interestRate ?? this.interestRate,
        farmerId: clearFarmer ? null : (farmerId ?? this.farmerId),
      );
}
