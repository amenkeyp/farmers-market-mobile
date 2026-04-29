import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive online/offline status, exposed as a Riverpod stream.
final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  final c = Connectivity();

  Future<void> emit(List<ConnectivityResult> results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!controller.isClosed) controller.add(online);
  }

  c.checkConnectivity().then(emit);
  final sub = c.onConnectivityChanged.listen(emit);

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
        data: (v) => v,
        orElse: () => true,
      );
});
