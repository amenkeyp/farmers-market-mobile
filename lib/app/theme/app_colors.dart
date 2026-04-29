import 'package:flutter/material.dart';

/// Brand & semantic colors for the POS app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0088CC);
  static const Color primaryDark = Color(0xFF006EA8);
  static const Color primarySoft = Color(0xFFE6F4FB);

  // Surfaces
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F4F9);
  static const Color border = Color(0xFFE5EAF2);
  static const Color divider = Color(0xFFEEF1F6);

  // Text
  static const Color textPrimary = Color(0xFF0E1A2B);
  static const Color textSecondary = Color(0xFF5B6878);
  static const Color textTertiary = Color(0xFF93A0B1);

  // Semantic
  static const Color success = Color(0xFF12B76A);
  static const Color successSoft = Color(0xFFE7F8EF);
  static const Color warning = Color(0xFFF79009);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFEEBEC);
  static const Color info = primary;

  // Shadows
  static const Color shadow = Color(0x14101828);
}
