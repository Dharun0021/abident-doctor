import 'package:flutter/material.dart';

/// Primary destinations shown in the bottom bar (not duplicated in the sidebar).
class DoctorNavigation {
  DoctorNavigation._();

  static const List<DoctorRoute> bottomRoutes = [
    DoctorRoute.dashboard,
    DoctorRoute.appointments,
    DoctorRoute.availability,
    DoctorRoute.map,
    DoctorRoute.reports,
  ];

  /// Secondary destinations — sidebar / drawer only.
  static const List<DoctorRoute> sidebarRoutes = [
    DoctorRoute.patients,
    DoctorRoute.treatments,
    DoctorRoute.profile,
    DoctorRoute.settings,
    DoctorRoute.support,
  ];
}

enum DoctorRoute {
  dashboard,
  appointments,
  availability,
  patients,
  treatments,
  map,
  notifications,
  reports,
  profile,
  settings,
  support,
}

extension DoctorRouteX on DoctorRoute {
  String get label => switch (this) {
        DoctorRoute.dashboard => 'Dashboard',
        DoctorRoute.appointments => 'Appointments',
        DoctorRoute.availability => 'Availability',
        DoctorRoute.patients => 'Patients',
        DoctorRoute.treatments => 'Treatments',
        DoctorRoute.map => 'Map / Navigation',
        DoctorRoute.notifications => 'Notifications',
        DoctorRoute.reports => 'Reports',
        DoctorRoute.profile => 'Profile / Clinic',
        DoctorRoute.settings => 'Settings',
        DoctorRoute.support => 'Help & Support',
      };

  IconData get icon => switch (this) {
        DoctorRoute.dashboard => Icons.space_dashboard_outlined,
        DoctorRoute.appointments => Icons.calendar_month_outlined,
        DoctorRoute.availability => Icons.schedule_outlined,
        DoctorRoute.patients => Icons.people_outline_rounded,
        DoctorRoute.treatments => Icons.medical_services_outlined,
        DoctorRoute.map => Icons.map_outlined,
        DoctorRoute.notifications => Icons.notifications_none_rounded,
        DoctorRoute.reports => Icons.insights_outlined,
        DoctorRoute.profile => Icons.badge_outlined,
        DoctorRoute.settings => Icons.settings_outlined,
        DoctorRoute.support => Icons.help_outline_rounded,
      };

  IconData get activeIcon => switch (this) {
        DoctorRoute.dashboard => Icons.space_dashboard_rounded,
        DoctorRoute.appointments => Icons.calendar_month_rounded,
        DoctorRoute.availability => Icons.schedule_rounded,
        DoctorRoute.patients => Icons.people_rounded,
        DoctorRoute.treatments => Icons.medical_services_rounded,
        DoctorRoute.map => Icons.map_rounded,
        DoctorRoute.notifications => Icons.notifications_active_rounded,
        DoctorRoute.reports => Icons.insights_rounded,
        DoctorRoute.profile => Icons.badge_rounded,
        DoctorRoute.settings => Icons.settings_rounded,
        DoctorRoute.support => Icons.help_rounded,
      };

  /// Label for the bottom navigation bar ([FittedBox] scales on narrow screens).
  String get bottomNavLabel => switch (this) {
        DoctorRoute.dashboard => 'Home',
        DoctorRoute.appointments => 'Appointments',
        DoctorRoute.availability => 'Availability',
        DoctorRoute.map => 'Map',
        DoctorRoute.reports => 'Reports',
        _ => label,
      };
}
