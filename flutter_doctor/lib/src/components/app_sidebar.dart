import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../styles/app_colors.dart';
import '../styles/app_decorations.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.collapsed,
    required this.selected,
    required this.onSelect,
    required this.onToggleCollapse,
    this.showCollapseToggle = true,
    this.routes = DoctorNavigation.sidebarRoutes,
  });

  final bool collapsed;
  final DoctorRoute selected;
  final ValueChanged<DoctorRoute> onSelect;
  final VoidCallback onToggleCollapse;
  final bool showCollapseToggle;
  final List<DoctorRoute> routes;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 76.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: AppDecorations.softShadow,
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 12 : 16, 20, collapsed ? 12 : 16, 12),
              child: Row(
                children: [
                  if (!collapsed) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ABIDENT', style: AppTextStyles.label.copyWith(letterSpacing: 1.2)),
                          Text('More', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
                        ),
                      ),
                    ),
                  if (showCollapseToggle)
                    IconButton(
                      onPressed: onToggleCollapse,
                      icon: Icon(collapsed ? Icons.menu_open_rounded : Icons.menu_rounded),
                      color: AppColors.textSecondary,
                      tooltip: collapsed ? 'Expand' : 'Collapse',
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: routes.length,
                itemBuilder: (context, i) {
                  final route = routes[i];
                  final isActive = route == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SidebarTile(
                      collapsed: collapsed,
                      route: route,
                      selected: isActive,
                      onTap: () => onSelect(route),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                collapsed ? 'v0.1' : 'Abident Doctor v0.1',
                textAlign: collapsed ? TextAlign.center : TextAlign.left,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.collapsed,
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final bool collapsed;
  final DoctorRoute route;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.selected ? widget.route.activeIcon : widget.route.icon;
    final bg = widget.selected
        ? AppColors.sidebarActive
        : _hover
            ? AppColors.background
            : Colors.transparent;
    final fg = widget.selected ? AppColors.primary : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 12, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: widget.selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              ),
            ),
            child: widget.collapsed
                ? Center(child: Icon(icon, color: fg, size: 22))
                : Row(
                    children: [
                      Icon(icon, color: fg, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.route.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(
                            color: widget.selected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
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
