import 'package:intl/intl.dart';

/// Money & date formatting helpers (FCFA / fr-CI locale).
class Formatters {
  Formatters._();

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  static final NumberFormat _qty = NumberFormat('#,##0.##', 'fr_FR');

  static String money(num? value) {
    if (value == null) return '—';
    return _money.format(value).replaceAll('\u00A0', ' ');
  }

  static String qty(num? value) =>
      value == null ? '—' : _qty.format(value);

  static String date(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(d);
  }

  static String dateTime(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(d);
  }

  static String relative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return date(d);
  }
}
