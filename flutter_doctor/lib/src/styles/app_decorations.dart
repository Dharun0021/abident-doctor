import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

class AppDecorations {
  AppDecorations._();

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration card({Color? color, Border? border}) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: border ?? Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration panel({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      boxShadow: softShadow,
    );
  }
}
