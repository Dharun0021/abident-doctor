import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_theme.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.height = 14,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final double? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final base = AppColors.border.withValues(alpha: 0.55);
        final hi = AppColors.border.withValues(alpha: 0.2);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusLg),
            gradient: LinearGradient(
              colors: [Color.lerp(base, hi, t)!, Color.lerp(hi, base, t)!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 100, borderRadius: AppTheme.radiusXl)),
            const SizedBox(width: 16),
            Expanded(child: AppSkeleton(height: 100, borderRadius: AppTheme.radiusXl)),
            const SizedBox(width: 16),
            Expanded(child: AppSkeleton(height: 100, borderRadius: AppTheme.radiusXl)),
          ],
        ),
        const SizedBox(height: 24),
        AppSkeleton(height: 280, borderRadius: AppTheme.radiusXl),
      ],
    );
  }
}
