import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_modal.dart';
import '../../components/app_tabs.dart';
import '../../components/status_badge.dart';
import '../../services/mock_data.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<MockAppointment> _listFor(int i) {
    final repo = MockRepository.instance;
    return switch (i) {
      0 => repo.todayAppointments,
      1 => repo.upcomingAppointments,
      _ => repo.pastAppointments,
    };
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final maxW = contentMaxWidth(context);
    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Appointments', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 8),
                  Text('Manage requests and your daily schedule.', style: AppTextStyles.body),
                  const SizedBox(height: 20),
                  AppSegmentedTabs(
                    controller: _tabs,
                    tabs: const ['Today', 'Upcoming', 'Past'],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: TabBarView(
                  controller: _tabs,
                  children: List.generate(3, (tabIndex) {
                    final items = _listFor(tabIndex);
                    if (items.isEmpty) {
                      return Center(
                        child: Text('No appointments in this view.', style: AppTextStyles.body),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final a = items[i];
                        final time = DateFormat('EEE, MMM d • h:mm a').format(a.time);
                        return AppCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.patientName, style: AppTextStyles.headingSmall),
                                        const SizedBox(height: 4),
                                        Text(time, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: a.status),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (a.status == AppointmentStatus.pending) ...[
                                    AppButton(
                                      label: 'Accept',
                                      onPressed: () => _toast('Accepted (mock)'),
                                    ),
                                    AppButton(
                                      label: 'Reject',
                                      variant: AppButtonVariant.outline,
                                      onPressed: () => _toast('Rejected (mock)'),
                                    ),
                                  ],
                                  AppButton(
                                    label: 'Reschedule',
                                    variant: AppButtonVariant.outline,
                                    onPressed: () => showAppModal(
                                      context: context,
                                      title: 'Reschedule',
                                      child: Text(
                                        'Pick a new slot for ${a.patientName}.',
                                        style: AppTextStyles.body,
                                      ),
                                      primaryLabel: 'Save',
                                      secondaryLabel: 'Cancel',
                                      onPrimary: () {
                                        Navigator.pop(context);
                                        _toast('Rescheduled (mock)');
                                      },
                                    ),
                                  ),
                                  if (a.status != AppointmentStatus.completed &&
                                      a.status != AppointmentStatus.cancelled)
                                    AppButton(
                                      label: 'Mark completed',
                                      variant: AppButtonVariant.outline,
                                      onPressed: () => _toast('Marked completed (mock)'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
