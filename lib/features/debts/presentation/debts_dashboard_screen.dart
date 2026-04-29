import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/debt.dart';
import 'debts_providers.dart';

class DebtsDashboardScreen extends ConsumerWidget {
  const DebtsDashboardScreen({super.key, this.farmerId});
  final int? farmerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsListProvider(farmerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(farmerId == null ? 'Dettes' : 'Dettes du producteur'),
      ),
      body: debts.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => EmptyState(
          title: 'Erreur',
          message: e.toString(),
          icon: Icons.error_outline_rounded,
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'Aucune dette ouverte',
              message: 'Tous les producteurs sont à jour.',
              icon: Icons.verified_outlined,
            );
          }
          final totalRemaining =
              list.fold<num>(0, (a, d) => a + d.remainingAmount);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(debtsListProvider(farmerId)),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SummaryHeader(
                  totalRemaining: totalRemaining,
                  count: list.length,
                ),
                const SizedBox(height: 16),
                ...list.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(debt: d),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.totalRemaining, required this.count});
  final num totalRemaining;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Encours total',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            Formatters.money(totalRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Text('$count dette(s) ouverte(s)',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/repayment?farmer_id=${debt.farmerId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  debt.farmerName ?? 'Dette #${debt.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              StatusPill(
                tone: debt.isOverdue ? PillTone.danger : PillTone.info,
                icon: debt.isOverdue
                    ? Icons.schedule_rounded
                    : Icons.timelapse_rounded,
                label: debt.isOverdue ? 'En retard' : 'En cours',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Créée ${Formatters.relative(debt.createdAt)}'
            '${debt.dueAt != null ? ' • Échéance ${Formatters.date(debt.dueAt)}' : ''}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: debt.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(
                debt.isOverdue ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Original',
                  value: Formatters.money(debt.originalAmount),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Restant',
                  value: Formatters.money(debt.remainingAmount),
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
