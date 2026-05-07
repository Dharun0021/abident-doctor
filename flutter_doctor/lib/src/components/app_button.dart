import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';

enum AppButtonVariant { primary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTextStyles.title.copyWith(
            fontSize: 14,
            color: variant == AppButtonVariant.primary || variant == AppButtonVariant.danger ? Colors.white : AppColors.primary,
          ),
        ),
      ],
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            child: child,
          ),
        );
      case AppButtonVariant.outline:
        return SizedBox(
          width: expanded ? double.infinity : null,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            child: DefaultTextStyle(
              style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 14),
              child: child,
            ),
          ),
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: effectiveOnPressed,
          child: DefaultTextStyle(
            style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 14),
            child: child,
          ),
        );
      case AppButtonVariant.danger:
        return SizedBox(
          width: expanded ? double.infinity : null,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
            child: DefaultTextStyle(
              style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 14),
              child: child,
            ),
          ),
        );
    }
  }
}
