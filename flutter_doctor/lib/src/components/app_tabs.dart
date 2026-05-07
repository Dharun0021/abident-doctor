import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_decorations.dart';
import '../styles/app_theme.dart';

class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
  });

  final TabController controller;
  final List<String> tabs;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppDecorations.softShadow,
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        tabs: [for (final t in tabs) Tab(text: t)],
      ),
    );
  }
}
