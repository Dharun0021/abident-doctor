import 'package:flutter/material.dart';

import '../components/app_navbar.dart';
import '../components/app_sidebar.dart';
import '../components/doctor_bottom_nav.dart';
import '../pages/appointments/appointments_page.dart';
import '../pages/availability/availability_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/map/map_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/patients/patients_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/reports/reports_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/support/support_page.dart';
import '../pages/treatments/treatments_page.dart';
import '../pages/auth/doctor_login_page.dart';
import '../services/doctor_auth_storage.dart';
import '../routes/app_routes.dart';
import '../styles/app_colors.dart';
import '../routes/doctor_scope.dart';
import '../utils/responsive.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  DoctorRoute _route = DoctorRoute.dashboard;
  bool _collapsed = false;

  /// Mobile layout: [Scaffold] is below this State's [context], so never use
  /// [Scaffold.of] with `context` here — use this key instead.
  final GlobalKey<ScaffoldState> _drawerScaffoldKey = GlobalKey<ScaffoldState>();

  String get _title => _route.label;

  Widget _pageFor(DoctorRoute r) {
    return switch (r) {
      DoctorRoute.dashboard => const DashboardPage(),
      DoctorRoute.appointments => const AppointmentsPage(),
      DoctorRoute.availability => const AvailabilityPage(),
      DoctorRoute.patients => const PatientsPage(),
      DoctorRoute.treatments => const TreatmentsPage(),
      DoctorRoute.map => const MapPage(),
      DoctorRoute.notifications => const NotificationsPage(),
      DoctorRoute.reports => const ReportsPage(),
      DoctorRoute.profile => const ProfilePage(),
      DoctorRoute.settings => const SettingsPage(),
      DoctorRoute.support => const SupportPage(),
    };
  }

  void _openNotifications() {
    setState(() => _route = DoctorRoute.notifications);
  }

  Future<void> _logout() async {
    await DoctorAuthStorage.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DoctorLoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerNav = context.useDrawerNav;

    Widget shell(Widget child) {
      return DoctorAppScope(
        navigateTo: (r) => setState(() => _route = r),
        child: child,
      );
    }

    if (drawerNav) {
      return shell(
        Scaffold(
          key: _drawerScaffoldKey,
          backgroundColor: AppColors.background,
          drawer: Drawer(
            child: SafeArea(
              child: AppSidebar(
                collapsed: false,
                selected: _route,
                showCollapseToggle: false,
                onSelect: (r) {
                  setState(() => _route = r);
                  _drawerScaffoldKey.currentState?.closeDrawer();
                },
                onToggleCollapse: () {},
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavbar(
                title: _title,
                onMenu: () => _drawerScaffoldKey.currentState?.openDrawer(),
                showSearch: false,
                onNotifications: _openNotifications,
                onLogout: _logout,
                onProfile: () => setState(() => _route = DoctorRoute.profile),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_route),
                    child: _pageFor(_route),
                  ),
                ),
              ),
              DoctorBottomNav(
                current: _route,
                onSelect: (r) => setState(() => _route = r),
              ),
            ],
          ),
        ),
      );
        
    }

    return shell(
      Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(
              collapsed: _collapsed,
              selected: _route,
              onSelect: (r) => setState(() => _route = r),
              onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavbar(
                    title: _title,
                    showSearch: context.screenWidth >= Breakpoints.desktop,
                    onNotifications: _openNotifications,
                    onLogout: _logout,
                    onProfile: () => setState(() => _route = DoctorRoute.profile),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(_route),
                        child: _pageFor(_route),
                      ),
                    ),
                  ),
                  DoctorBottomNav(
                    current: _route,
                    onSelect: (r) => setState(() => _route = r),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
