import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/debts_repository.dart';
import '../domain/debt.dart';

final debtsListProvider =
    FutureProvider.autoDispose.family<List<Debt>, int?>((ref, farmerId) {
  return ref.read(debtsRepositoryProvider).list(farmerId: farmerId);
});
