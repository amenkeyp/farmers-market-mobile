import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/category.dart';
import '../domain/product.dart';

class ProductsRepository {
  ProductsRepository(this._api, this._isOnline);
  final ApiClient _api;
  final bool Function() _isOnline;

  Future<List<Category>> categoriesTree() async {
    final box = HiveBoxes.box(HiveBoxes.categories);
    if (_isOnline()) {
      try {
        final raw = await _api.request<dynamic>('/categories', query: {'tree': 1});
        final list = _list(raw);
        final cats = list
            .whereType<Map>()
            .map((m) => Category.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        await box.put('tree', cats.map((c) => c.toJson()).toList());
        return cats;
      } on Failure {/* fallthrough */}
    }
    final cached = box.get('tree');
    if (cached is List) {
      return cached
          .whereType<Map>()
          .map((m) => Category.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  Future<List<Product>> products({
    int? categoryId,
    String? search,
  }) async {
    final box = HiveBoxes.box(HiveBoxes.products);
    final query = <String, dynamic>{};
    if (categoryId != null) query['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) query['search'] = search;

    Future<List<Product>> fromCache() async {
      final all = box.values
          .whereType<Map>()
          .map((m) => Product.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return all.where((p) {
        final okCat = categoryId == null || p.categoryId == categoryId;
        final okSearch = search == null || search.isEmpty ||
            p.name.toLowerCase().contains(search.toLowerCase()) ||
            p.sku.toLowerCase().contains(search.toLowerCase());
        return okCat && okSearch;
      }).toList();
    }

    if (!_isOnline()) return fromCache();
    try {
      final raw = await _api.request<dynamic>('/products', query: query);
      final list = _list(raw);
      final products = list
          .whereType<Map>()
          .map((m) => Product.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      for (final p in products) {
        await box.put(p.id, p.toJson());
      }
      return products;
    } on Failure {
      return fromCache();
    }
  }

  List<dynamic> _list(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(
    ref.read(apiClientProvider),
    () => ref.read(isOnlineProvider),
  );
});
