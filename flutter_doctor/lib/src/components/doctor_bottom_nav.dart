import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../styles/app_colors.dart';
import '../styles/app_decorations.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';

/// Quick access: Home, appointments, availability, map, reports.
class DoctorBottomNav extends StatelessWidget {
  const DoctorBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final DoctorRoute current;
  final ValueChanged<DoctorRoute> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.75)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                for (final route in DoctorNavigation.bottomRoutes)
                  Expanded(
                    child: _BottomNavItem(
                      route: route,
                      selected: current == route,
                      onTap: () => onSelect(route),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final DoctorRoute route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? route.activeIcon : route.icon;
    final fg = selected ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
              ),
              boxShadow: selected ? AppDecorations.softShadow : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    route.bottomNavLabel,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
