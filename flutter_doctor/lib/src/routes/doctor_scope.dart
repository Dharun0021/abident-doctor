import 'package:flutter/material.dart';

import 'app_routes.dart';

class DoctorAppScope extends InheritedWidget {
  const DoctorAppScope({
    super.key,
    required this.navigateTo,
    required super.child,
  });

  final ValueChanged<DoctorRoute> navigateTo;

  static DoctorAppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DoctorAppScope>();
  }

  static void navigate(BuildContext context, DoctorRoute route) {
    final scope = context.findAncestorWidgetOfExactType<DoctorAppScope>();
    scope?.navigateTo(route);
  }

  @override
  bool updateShouldNotify(covariant DoctorAppScope oldWidget) {
    return oldWidget.navigateTo != navigateTo;
  }
}
