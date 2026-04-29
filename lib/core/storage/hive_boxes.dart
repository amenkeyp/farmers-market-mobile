import 'package:hive_flutter/hive_flutter.dart';

/// Centralized list of Hive boxes used as the local cache layer.
///
/// We deliberately store JSON-friendly maps (not custom adapters) so the
/// schema can evolve without write-time migrations.
class HiveBoxes {
  HiveBoxes._();

  static const String farmers = 'cache_farmers';
  static const String products = 'cache_products';
  static const String categories = 'cache_categories';
  static const String debts = 'cache_debts';
  static const String transactions = 'cache_transactions';
  static const String offlineQueue = 'offline_queue';
  static const String meta = 'meta';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(farmers),
      Hive.openBox<dynamic>(products),
      Hive.openBox<dynamic>(categories),
      Hive.openBox<dynamic>(debts),
      Hive.openBox<dynamic>(transactions),
      Hive.openBox<dynamic>(offlineQueue),
      Hive.openBox<dynamic>(meta),
    ]);
  }

  static Box<dynamic> box(String name) => Hive.box<dynamic>(name);
}
