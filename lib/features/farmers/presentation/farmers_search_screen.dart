import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/farmer.dart';
import 'farmers_providers.dart';

class FarmersSearchScreen extends ConsumerStatefulWidget {
  const FarmersSearchScreen({super.key, this.picker = false});
  final bool picker;

  @override
  ConsumerState<FarmersSearchScreen> createState() =>
      _FarmersSearchScreenState();
}

class _FarmersSearchScreenState extends ConsumerState<FarmersSearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(farmerSearchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Producteurs'),
        actions: [
          IconButton(
            tooltip: 'Nouveau producteur',
            onPressed: () => context.push('/farmers/new'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) =>
                  ref.read(farmerSearchQueryProvider.notifier).state = v,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Téléphone ou identifiant (ex. CI-FARM-0004)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(farmerSearchQueryProvider.notifier).state =
                              '';
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const ListSkeleton(),
              error: (e, _) => EmptyState(
                title: 'Erreur',
                message: e.toString(),
                icon: Icons.error_outline_rounded,
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'Aucun producteur',
                    message:
                        'Ajustez votre recherche ou créez un nouveau producteur.',
                    icon: Icons.person_search_rounded,
                    action: FilledButton.icon(
                      onPressed: () => context.push('/farmers/new'),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Nouveau producteur'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(farmerSearchResultsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemBuilder: (_, i) =>
                        _FarmerTile(farmer: list[i], picker: widget.picker),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: list.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerTile extends StatelessWidget {
  const _FarmerTile({required this.farmer, this.picker = false});
  final Farmer farmer;
  final bool picker;

  @override
  Widget build(BuildContext context) {
    final hasDebt = (farmer.totalDebt ?? 0) > 0;
    return AppCard(
      onTap: () => picker
          ? context.pop<int>(farmer.id)
          : context.push('/repayment?farmer_id=${farmer.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              farmer.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        farmer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    StatusPill(
                      tone: hasDebt ? PillTone.warning : PillTone.success,
                      icon: hasDebt
                          ? Icons.account_balance_wallet_outlined
                          : Icons.check_circle_outline_rounded,
                      label: hasDebt
                          ? Formatters.money(farmer.totalDebt)
                          : 'À jour',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${farmer.identifier} • ${farmer.phone ?? '—'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (farmer.village != null || farmer.region != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      farmer.village,
                      farmer.region,
                    ].whereType<String>().join(' • '),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
