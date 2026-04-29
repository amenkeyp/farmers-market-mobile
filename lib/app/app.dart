import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FarmersPosApp extends ConsumerWidget {
  const FarmersPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly construct sync service so it listens to connectivity.
    ref.watch(syncServiceProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Marché POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        // Cap text scaling for tablet consistency.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(mq.textScaler.scale(1).clamp(1.0, 1.2)),
          ),
          child: child!,
        );
      },
    );
  }
}
