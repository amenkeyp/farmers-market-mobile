import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/farmers_repository.dart';
import '../domain/farmer.dart';

final farmerSearchQueryProvider = StateProvider<String>((_) => '');

final farmerSearchResultsProvider = FutureProvider.autoDispose<List<Farmer>>((ref) async {
  final q = ref.watch(farmerSearchQueryProvider);
  // Debounce: small delay so we don't query on every keystroke.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return ref.read(farmersRepositoryProvider).search(q);
});

final farmerByIdProvider =
    FutureProvider.autoDispose.family<Farmer, int>((ref, id) {
  return ref.read(farmersRepositoryProvider).getById(id);
});
