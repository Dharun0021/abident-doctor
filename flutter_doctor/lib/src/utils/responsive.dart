import 'package:flutter/material.dart';

class Breakpoints {
  Breakpoints._();

  static const double mobile = 640;
  static const double tablet = 960;
  static const double desktop = 1200;
}

enum AppBreakpoint { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  AppBreakpoint get breakpoint {
    final w = screenWidth;
    if (w < Breakpoints.mobile) return AppBreakpoint.mobile;
    if (w < Breakpoints.tablet) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }

  bool get isMobile => breakpoint == AppBreakpoint.mobile;
  bool get isTablet => breakpoint == AppBreakpoint.tablet;
  bool get isDesktop => breakpoint == AppBreakpoint.desktop;

  bool get useDrawerNav => screenWidth < Breakpoints.tablet;
}

double contentMaxWidth(BuildContext context) {
  final w = context.screenWidth;
  if (w > 1400) return 1280;
  if (w > Breakpoints.tablet) return w - 280;
  return w;
}

EdgeInsets pagePadding(BuildContext context) {
  if (context.isMobile) return const EdgeInsets.all(16);
  if (context.isTablet) return const EdgeInsets.all(20);
  return const EdgeInsets.all(24);
}
