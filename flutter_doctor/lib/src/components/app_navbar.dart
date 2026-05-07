import 'package:flutter/material.dart';

import '../services/doctor_auth_storage.dart';
import '../services/mock_data.dart';
import '../styles/app_colors.dart';
import '../styles/app_decorations.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_theme.dart';
import 'app_button.dart';

class AppNavbar extends StatefulWidget {
  const AppNavbar({
    super.key,
    required this.title,
    this.onMenu,
    this.showSearch = true,
    this.onLogout,
    this.onNotifications,
    this.onProfile,
  });

  final String title;
  final VoidCallback? onMenu;
  final bool showSearch;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  State<AppNavbar> createState() => _AppNavbarState();
}

class _AppNavbarState extends State<AppNavbar> {
  String _doctorName = 'Loading...';
  String _specialization = 'Doctor';

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final name = await DoctorAuthStorage.getDoctorName();
    final spec = await DoctorAuthStorage.getSpecialization();
    if (mounted) {
      setState(() {
        _doctorName = name ?? 'Doctor';
        _specialization = spec ?? 'General Dentist';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final unread = repo.notifications.where((n) => !n.read).length;
    final compact = MediaQuery.sizeOf(context).width < 900;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 10 : 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.92),
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
          boxShadow: AppDecorations.softShadow,
        ),
        child: Row(
          children: [
            if (widget.onMenu != null)
              IconButton(
                onPressed: widget.onMenu,
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.textPrimary,
              ),
            Expanded(
              flex: compact ? 1 : 0,
              child: Text(
                widget.title,
                style: compact ? AppTextStyles.headingSmall : AppTextStyles.headingMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.showSearch && !compact) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients, charts…',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (compact && widget.showSearch)
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Global search is UI-only.')),
                  );
                },
                icon: const Icon(Icons.search_rounded),
                color: AppColors.textPrimary,
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: widget.onNotifications,
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: AppColors.textPrimary,
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onProfile,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          _doctorName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                          style: AppTextStyles.title.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_doctorName, style: AppTextStyles.title),
                          Text(_specialization, style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Logout',
                variant: AppButtonVariant.outline,
                icon: Icons.logout_rounded,
                onPressed: widget.onLogout ?? () {},
              ),
            ] else ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    _doctorName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                onSelected: (v) {
                  if (v == 'logout') {
                    widget.onLogout?.call();
                  } else if (v == 'profile') {
                    widget.onProfile?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(_doctorName, style: AppTextStyles.title),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
