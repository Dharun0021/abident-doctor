import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_skeleton.dart';
import '../../hooks/use_delayed_future.dart';
import '../../routes/app_routes.dart';
import '../../routes/doctor_scope.dart';
import '../../services/mock_data.dart';
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

  @override
  void initState() {
    super.initState();
    _load.start();
    _load.addListener(_onLoad);
  }

  void _onLoad() => setState(() {});

  @override
  void dispose() {
    _load.removeListener(_onLoad);
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final pad = pagePadding(context);

    if (!_load.ready) {
      return SingleChildScrollView(
        padding: pad,
        child: const DashboardSkeleton(),
      );
    }

    final pending = repo.todayAppointments.where((a) => a.status == AppointmentStatus.pending).length;
    final completed = repo.pastAppointments.where((a) => a.status == AppointmentStatus.completed).length;

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Good day, ${repo.doctorName.split(' ').last}', style: AppTextStyles.display),
              const SizedBox(height: 8),
              Text(
                'Here is what your practice looks like today.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 720;
                  final children = [
                    _StatCard(
                      title: 'Today',
                      value: '${repo.todayAppointments.length}',
                      subtitle: 'Appointments',
                      icon: Icons.calendar_today_rounded,
                      tint: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Pending',
                      value: '$pending',
                      subtitle: 'Requests',
                      icon: Icons.hourglass_top_rounded,
                      tint: AppColors.warning,
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: '$completed',
                      subtitle: 'Last 30 days',
                      icon: Icons.verified_rounded,
                      tint: AppColors.success,
                    ),
                  ];
                  if (isNarrow) {
                    return Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          children[i],
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: children[0]),
                      const SizedBox(width: 16),
                      Expanded(child: children[1]),
                      const SizedBox(width: 16),
                      Expanded(child: children[2]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
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
                              Text('Upcoming', style: AppTextStyles.headingSmall),
                              const Spacer(),
                              Text(
                                DateFormat('EEE, MMM d').format(DateTime.now()),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...[
                            ...repo.todayAppointments,
                            ...repo.upcomingAppointments,
                          ].take(5).map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AppointmentRow(appointment: a),
                                ),
                              ),
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
                            Text('Quick actions', style: AppTextStyles.headingSmall),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Review appointments',
                              icon: Icons.event_available_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(context, DoctorRoute.appointments),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: 'Update availability',
                              variant: AppButtonVariant.outline,
                              icon: Icons.schedule_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(context, DoctorRoute.availability),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: 'Add treatment note',
                              variant: AppButtonVariant.outline,
                              icon: Icons.note_add_rounded,
                              expanded: true,
                              onPressed: () => DoctorAppScope.navigate(context, DoctorRoute.treatments),
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
                        onPressed: () => DoctorAppScope.navigate(context, DoctorRoute.appointments),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Update availability',
                        variant: AppButtonVariant.outline,
                        icon: Icons.schedule_rounded,
                        expanded: true,
                        onPressed: () => DoctorAppScope.navigate(context, DoctorRoute.availability),
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

  final MockAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(appointment.time);
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
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Text(
              appointment.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
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
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
