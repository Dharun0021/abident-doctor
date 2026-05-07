import 'package:flutter/material.dart';

import '../services/mock_data.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      AppointmentStatus.pending => ('Pending', AppColors.warning.withValues(alpha: 0.12), AppColors.warning),
      AppointmentStatus.confirmed => ('Confirmed', AppColors.info.withValues(alpha: 0.12), AppColors.info),
      AppointmentStatus.completed => ('Completed', AppColors.success.withValues(alpha: 0.12), AppColors.success),
      AppointmentStatus.cancelled => ('Cancelled', AppColors.error.withValues(alpha: 0.1), AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class LabelBadge extends StatelessWidget {
  const LabelBadge({super.key, required this.label, this.color = AppColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
