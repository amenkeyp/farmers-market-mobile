import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../checkout/presentation/cart_controller.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'products_providers.dart';

/// Tree-based product browser. Tap a category to drill down; leaf categories
/// (or any node) display matching products. Smooth `AnimatedSwitcher`
/// transitions between levels.
class ProductsBrowseScreen extends ConsumerStatefulWidget {
  const ProductsBrowseScreen({super.key});

  @override
  ConsumerState<ProductsBrowseScreen> createState() =>
      _ProductsBrowseScreenState();
}

class _ProductsBrowseScreenState extends ConsumerState<ProductsBrowseScreen> {
  final List<Category> _stack = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pushCategory(Category c) {
    setState(() => _stack.add(c));
    ref.read(productFilterProvider.notifier).state =
        ProductFilter(categoryId: c.id, search: _searchCtrl.text);
  }

  void _popCategory() {
    if (_stack.isEmpty) return;
    setState(() => _stack.removeLast());
    final cat = _stack.isEmpty ? null : _stack.last;
    ref.read(productFilterProvider.notifier).state =
        ProductFilter(categoryId: cat?.id, search: _searchCtrl.text);
  }

  Category? get _current => _stack.isEmpty ? null : _stack.last;

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(categoriesTreeProvider);
    final products = ref.watch(productsListProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _stack.isNotEmpty
            ? IconButton(
                onPressed: _popCategory,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(_current?.name ?? 'Catalogue'),
        actions: [
          if (cartCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('$cartCount',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ref.read(productFilterProvider.notifier).state =
                    ProductFilter(categoryId: _current?.id, search: v);
              },
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit (nom ou SKU)',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          // Categories row (children of current node)
          tree.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Skeleton(height: 44, radius: 999),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (roots) {
              final list = _current?.children ?? roots;
              if (list.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _pushCategory(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              child: products.when(
                loading: () => const ListSkeleton(),
                error: (e, _) => EmptyState(
                  title: 'Erreur',
                  message: e.toString(),
                  icon: Icons.error_outline_rounded,
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      title: 'Aucun produit',
                      message: 'Aucun produit dans cette catégorie.',
                      icon: Icons.inventory_2_outlined,
                    );
                  }
                  return _ProductsGrid(products: list, key: ValueKey(_current?.id ?? 'root'));
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: cartCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: Text('Caisse ($cartCount)'),
            ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductCard(product: products[i]),
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider.select(
        (c) => c.items.where((it) => it.product.id == product.id).fold<num>(0, (a, b) => a + b.quantity)));
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => ref.read(cartProvider.notifier).add(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            product.sku,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.money(product.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (qty > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '×${Formatters.qty(qty)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
