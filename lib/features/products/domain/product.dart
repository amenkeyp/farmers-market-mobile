class Product {
  final int id;
  final String sku;
  final String name;
  final String? unit;
  final num price;
  final num? ratePerKg;
  final num? stock;
  final int? categoryId;
  final String? categoryName;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    this.unit,
    this.ratePerKg,
    this.stock,
    this.categoryId,
    this.categoryName,
  });

  bool get isCommodity => ratePerKg != null && ratePerKg! > 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: (j['id'] as num).toInt(),
    sku: j['sku'] as String? ?? '',
    name: j['name'] as String? ?? '',
    price: (j['unit_price'] as num?) ?? (j['price'] as num?) ?? 0,
    ratePerKg: j['rate_per_kg'] as num?,
    unit: j['unit'] as String?,
    stock: (j['stock_quantity'] as num?) ?? (j['stock'] as num?),
    categoryId: (j['category_id'] as num?)?.toInt(),
    categoryName: j['category'] is Map
        ? (j['category']['name'] as String?)
        : j['category_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    'unit_price': price,
    'rate_per_kg': ratePerKg,
    'unit': unit,
    'stock_quantity': stock,
    'category_id': categoryId,
    'category_name': categoryName,
  };
}
