import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';
import 'app_button.dart';

Future<T?> showAppModal<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? primaryLabel,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(child: SingleChildScrollView(child: child)),
                if (primaryLabel != null || secondaryLabel != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (secondaryLabel != null)
                        Expanded(
                          child: AppButton(
                            label: secondaryLabel,
                            variant: AppButtonVariant.outline,
                            onPressed: onSecondary ?? () => Navigator.pop(ctx),
                            expanded: true,
                          ),
                        ),
                      if (secondaryLabel != null && primaryLabel != null) const SizedBox(width: 12),
                      if (primaryLabel != null)
                        Expanded(
                          child: AppButton(
                            label: primaryLabel,
                            onPressed: onPrimary ?? () => Navigator.pop(ctx),
                            expanded: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
