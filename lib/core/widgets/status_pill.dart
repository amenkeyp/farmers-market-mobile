import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum PillTone { neutral, info, success, warning, danger }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = PillTone.neutral, this.icon});
  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.info => (AppColors.primarySoft, AppColors.primary),
      PillTone.success => (AppColors.successSoft, AppColors.success),
      PillTone.warning => (AppColors.warningSoft, AppColors.warning),
      PillTone.danger => (AppColors.dangerSoft, AppColors.danger),
      _ => (AppColors.surfaceMuted, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
