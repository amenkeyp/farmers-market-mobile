import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/products_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';

final categoriesTreeProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(productsRepositoryProvider).categoriesTree();
});

class ProductFilter {
  final int? categoryId;
  final String search;
  const ProductFilter({this.categoryId, this.search = ''});

  @override
  bool operator ==(Object other) =>
      other is ProductFilter && other.categoryId == categoryId && other.search == search;

  @override
  int get hashCode => Object.hash(categoryId, search);
}

final productFilterProvider =
    StateProvider<ProductFilter>((_) => const ProductFilter());

final productsListProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final f = ref.watch(productFilterProvider);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return ref.read(productsRepositoryProvider).products(
        categoryId: f.categoryId,
        search: f.search,
      );
});
