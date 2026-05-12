import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_skeleton.dart';
import '../../hooks/use_delayed_future.dart';
import '../../routes/app_routes.dart';
import '../../routes/doctor_scope.dart';
import '../../services/doctor_api_service.dart';
import '../../services/doctor_auth_storage.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _load = DelayedContentController();
  final List<_DashboardAppointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _doctorName = 'Doctor';

  @override
  void initState() {
    super.initState();
    _load.start();
    _load.addListener(_onLoad);
    _loadDashboardData();
  }

  void _onLoad() => setState(() {});

  @override
  void dispose() {
    _load.removeListener(_onLoad);
    _load.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = await DoctorAuthStorage.getDoctorName();
      if (name != null && name.isNotEmpty) {
        _doctorName = name;
      }

      final response = await DoctorApiService.getDoctorBookings();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawBookings = List.from(data['bookings'] as List<dynamic>? ?? []);
        _appointments.clear();
        _appointments.addAll(
          rawBookings.map((rawBooking) {
            final item = rawBooking as Map<String, dynamic>;
            final user = item['userId'] as Map<String, dynamic>?;
            final treatment = item['treatment'] as Map<String, dynamic>?;
            final rawDate = treatment?['date']?.toString();
            final rawTime = treatment?['time']?.toString();
            final appointmentTime =
                _parseBookingDateTime(rawDate, rawTime) ?? DateTime.now();

            return _DashboardAppointment(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
              patientName: user?['name']?.toString() ?? 'Patient',
              appointmentTime: appointmentTime,
              status: item['status']?.toString() ?? 'PENDING',
            );
          }),
        );
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        _errorMessage =
            data?['message']?.toString() ?? 'Failed to load dashboard data.';
      }
    } catch (error) {
      _errorMessage = 'Unable to load dashboard data: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime? _parseBookingDateTime(String? rawDate, String? rawTime) {
    if (rawDate == null) return null;

    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        return DateTime.parse('$rawDate $rawTime');
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd hh:mm a').parse('$rawDate $rawTime');
        } catch (_) {
          return null;
        }
      }
    }

    return DateTime.tryParse(rawDate);
  }

  bool _isPending(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending' ||
        normalized == 'requested' ||
        normalized == 'rescheduled';
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!_load.ready || _isLoading) {
      return SingleChildScrollView(
        padding: pad,
        child: const DashboardSkeleton(),
      );
    }

    final todayCount = _appointments.where((a) {
      final appointmentDate = DateTime(
        a.appointmentTime.year,
        a.appointmentTime.month,
        a.appointmentTime.day,
      );
      return appointmentDate == today;
    }).length;

    final pendingCount = _appointments
        .where((a) => _isPending(a.status))
        .length;
    final completedCount = _appointments.where((a) {
      final age = now.difference(a.appointmentTime).inDays;
      return a.status.toLowerCase() == 'completed' && age >= 0 && age <= 30;
    }).length;

    final upcomingAppointments = _appointments.where((a) {
      final appointmentDate = DateTime(
        a.appointmentTime.year,
        a.appointmentTime.month,
        a.appointmentTime.day,
      );
      return appointmentDate == today || appointmentDate.isAfter(today);
    }).toList()..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));

    final displayName = _doctorName.split(' ').last;

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Good day, $displayName', style: AppTextStyles.display),
              const SizedBox(height: 8),
              Text(
                'Here is what your practice looks like today.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 720;
                  final cards = [
                    _StatCard(
                      title: 'Today',
                      value: '$todayCount',
                      subtitle: 'Appointments',
                      icon: Icons.calendar_today_rounded,
                      tint: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Pending',
                      value: '$pendingCount',
                      subtitle: 'Requests',
                      icon: Icons.hourglass_top_rounded,
                      tint: AppColors.warning,
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: '$completedCount',
                      subtitle: 'Last 30 days',
                      icon: Icons.verified_rounded,
                      tint: AppColors.success,
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          cards[i],
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[2]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Upcoming',
                                style: AppTextStyles.headingSmall,
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('EEE, MMM d').format(now),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (upcomingAppointments.isEmpty)
                            Text(
                              'No upcoming appointments found.',
                              style: AppTextStyles.caption,
                            )
                          else ...[
                            for (var appointment in upcomingAppointments.take(
                              5,
                            )) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AppointmentRow(
                                  appointment: appointment,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!context.isMobile) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Quick actions',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Review appointments',
                              icon: Icons.event_available_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(
                                context,
                                DoctorRoute.appointments,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: 'Update availability',
                              variant: AppButtonVariant.outline,
                              icon: Icons.schedule_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(
                                context,
                                DoctorRoute.availability,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: 'Add treatment note',
                              variant: AppButtonVariant.outline,
                              icon: Icons.note_add_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(
                                context,
                                DoctorRoute.treatments,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (context.isMobile) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Quick actions', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Review appointments',
                        icon: Icons.event_available_rounded,
                        expanded: true,
                        onPressed: () => DoctorAppScope.navigate(
                          context,
                          DoctorRoute.appointments,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Update availability',
                        variant: AppButtonVariant.outline,
                        icon: Icons.schedule_rounded,
                        expanded: true,
                        onPressed: () => DoctorAppScope.navigate(
                          context,
                          DoctorRoute.availability,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAppointment {
  _DashboardAppointment({
    required this.id,
    required this.patientName,
    required this.appointmentTime,
    required this.status,
  });

  final String id;
  final String patientName;
  final DateTime appointmentTime;
  final String status;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.headingLarge),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment});

  final _DashboardAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(appointment.appointmentTime);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              appointment.patientName
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join(),
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.patientName, style: AppTextStyles.title),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
