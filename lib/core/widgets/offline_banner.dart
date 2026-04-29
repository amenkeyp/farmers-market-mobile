import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../network/connectivity_service.dart';
import '../sync/sync_service.dart';

/// Compact banner shown when offline OR when there are queued ops.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    final pending = ref.watch(pendingSyncCountProvider);

    final visible = !online || pending > 0;
    if (!visible) return const SizedBox.shrink();

    final tone = !online ? AppColors.warning : AppColors.primary;
    final bg = !online ? AppColors.warningSoft : AppColors.primarySoft;
    final text = !online
        ? 'Mode hors ligne — vos actions seront synchronisées'
        : 'Synchronisation de $pending opération(s) en attente…';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(text),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: bg,
        child: Row(
          children: [
            Icon(!online ? Icons.cloud_off_rounded : Icons.sync_rounded,
                size: 16, color: tone),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: tone, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
