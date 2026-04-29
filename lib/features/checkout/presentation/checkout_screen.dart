import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../farmers/presentation/farmers_providers.dart';
import '../data/checkout_repository.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.farmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un producteur.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ref.read(checkoutRepositoryProvider).checkout(cart);
      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(farmerSearchResultsProvider);
      _showSuccess(res.queued);
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess(bool queued) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              queued ? 'Vente mise en file d’attente' : 'Vente enregistrée',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              queued
                  ? 'Synchronisation automatique au retour de la connexion.'
                  : 'La transaction a été enregistrée avec succès.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Terminer',
              icon: Icons.done_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Vider'),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? EmptyState(
              title: 'Panier vide',
              message: 'Ajoutez des produits depuis le catalogue.',
              icon: Icons.shopping_cart_outlined,
              action: FilledButton.icon(
                onPressed: () => context.go('/catalog'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Parcourir le catalogue'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 200),
              children: [
                _FarmerSelector(),
                const SizedBox(height: 12),
                ...cart.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ItemRow(item: it),
                    )),
                const SizedBox(height: 12),
                _PaymentSelector(),
              ],
            ),
      bottomSheet: cart.items.isEmpty ? null : _Summary(onSubmit: _submit, loading: _submitting),
    );
  }
}

class _FarmerSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmerId = ref.watch(cartProvider).farmerId;
    if (farmerId == null) {
      return AppCard(
        onTap: () async {
          final id = await context.push<int>('/farmers?picker=1');
          if (id != null) ref.read(cartProvider.notifier).setFarmer(id);
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_search_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sélectionner un producteur',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Requis avant le paiement',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      );
    }
    final f = ref.watch(farmerByIdProvider(farmerId));
    return AppCard(
      onTap: () async {
        final id = await context.push<int>('/farmers?picker=1');
        if (id != null) ref.read(cartProvider.notifier).setFarmer(id);
      },
      child: f.when(
        loading: () => const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Erreur: $e'),
        data: (farmer) => Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                farmer.initials,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farmer.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${farmer.identifier} • ${farmer.phone ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            StatusPill(
              tone: (farmer.totalDebt ?? 0) > 0
                  ? PillTone.warning
                  : PillTone.success,
              label: (farmer.totalDebt ?? 0) > 0
                  ? 'Dette ${Formatters.money(farmer.totalDebt)}'
                  : 'À jour',
            ),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(cartProvider.notifier);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${Formatters.money(item.product.price)} / ${item.product.unit ?? 'unité'}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          _QtyStepper(
            value: item.quantity,
            onChanged: (v) => ctrl.setQty(item.product.id, v),
            onRemove: () => ctrl.remove(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });
  final num value;
  final ValueChanged<num> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(value <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded),
            onPressed: () =>
                value <= 1 ? onRemove() : onChanged(value - 1),
            color: AppColors.textPrimary,
          ),
          Text(Formatters.qty(value),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onChanged(value + 1),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PaymentSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final ctrl = ref.read(cartProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mode de paiement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PayCard(
                  active: cart.mode == PaymentMode.cash,
                  icon: Icons.payments_rounded,
                  title: 'Comptant',
                  subtitle: 'Paiement immédiat',
                  onTap: () => ctrl.setMode(PaymentMode.cash),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PayCard(
                  active: cart.mode == PaymentMode.credit,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Crédit',
                  subtitle: '+ ${(cart.interestRate * 100).toStringAsFixed(0)}% intérêt',
                  onTap: () => ctrl.setMode(PaymentMode.credit),
                ),
              ),
            ],
          ),
          if (cart.mode == PaymentMode.credit) ...[
            const SizedBox(height: 16),
            const Text('Taux d’intérêt',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              min: 0,
              max: 0.20,
              divisions: 20,
              value: cart.interestRate.clamp(0, 0.20),
              label: '${(cart.interestRate * 100).toStringAsFixed(0)}%',
              activeColor: AppColors.primary,
              onChanged: ctrl.setInterestRate,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Intérêt: ${Formatters.money(cart.interestAmount)} • Total: ${Formatters.money(cart.total)}',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.onSubmit, required this.loading});
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Sous-total',
                    style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                Text(Formatters.money(cart.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (cart.mode == PaymentMode.credit) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                      'Intérêt (${(cart.interestRate * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('+ ${Formatters.money(cart.interestAmount)}',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const Divider(height: 18),
            Row(
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text(
                  Formatters.money(cart.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Valider la vente',
              icon: Icons.lock_outline_rounded,
              loading: loading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
