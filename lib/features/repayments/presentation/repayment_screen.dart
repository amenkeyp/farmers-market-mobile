import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../debts/presentation/debts_providers.dart';
import '../../farmers/presentation/farmers_providers.dart';
import '../data/repayments_repository.dart';

/// Repayment in physical commodity (kg). Cashier enters quantity and we
/// preview the FCFA conversion before confirmation.
class RepaymentScreen extends ConsumerStatefulWidget {
  const RepaymentScreen({super.key, required this.farmerId});
  final int farmerId;

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  final _kgCtrl = TextEditingController(text: '0');
  // Default unit price for in-kind repayment (e.g., cocoa). Editable.
  final _priceCtrl = TextEditingController(text: '1500');
  bool _saving = false;

  @override
  void dispose() {
    _kgCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  num get _kg => num.tryParse(_kgCtrl.text.replaceAll(',', '.')) ?? 0;
  num get _price => num.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
  num get _amount => _kg * _price;

  Future<void> _confirm() async {
    if (_amount <= 0) return;
    final farmer = await ref.read(farmerByIdProvider(widget.farmerId).future);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer le remboursement'),
        content: Text(
          'Vous êtes sur le point de rembourser ${Formatters.money(_amount)} '
          '(${Formatters.qty(_kg)} kg × ${Formatters.money(_price)}) '
          'pour ${farmer.fullName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      final res = await ref
          .read(repaymentsRepositoryProvider)
          .pay(
            farmerId: widget.farmerId,
            commodityKg: _kg,
            commodityRate: _price,
            notes: 'Remboursement en nature: ${_kg} kg @ ${_price}',
          );
      if (!mounted) return;
      ref.invalidate(debtsListProvider(widget.farmerId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.queued
                ? 'Hors ligne — remboursement mis en file d’attente.'
                : 'Remboursement enregistré avec succès.',
          ),
        ),
      );
      context.pop();
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerAsync = ref.watch(farmerByIdProvider(widget.farmerId));
    return Scaffold(
      appBar: AppBar(title: const Text('Remboursement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            farmerAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erreur: $e'),
              data: (f) => AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        f.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Dette: ${Formatters.money(f.totalDebt)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Quantité (kg)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _kgCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: 'kg',
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prix unitaire (FCFA / kg)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Aperçu',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous êtes sur le point de rembourser',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: .8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.money(_amount),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.qty(_kg)} kg × ${Formatters.money(_price)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirmer le remboursement',
              icon: Icons.check_circle_outline_rounded,
              loading: _saving,
              onPressed: _amount > 0 ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}
