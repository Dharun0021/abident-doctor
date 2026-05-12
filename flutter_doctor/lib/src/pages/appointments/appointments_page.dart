import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_modal.dart';
import '../../components/app_tabs.dart';
import '../../components/status_badge.dart';
import '../../pages/appointments/appointment_detail_page.dart';
import '../../services/doctor_api_service.dart';
import '../../services/mock_data.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class DoctorBookingItem {
  DoctorBookingItem({
    required this.id,
    required this.patientName,
    required this.appointmentTime,
    required this.status,
    required this.visitType,
    required this.treatmentType,
    required this.reason,
    required this.details,
    required this.locationAddress,
    required this.notes,
  });

  final String id;
  final String patientName;
  final DateTime appointmentTime;
  final String status;
  final String visitType;
  final String treatmentType;
  final String reason;
  final String details;
  final String locationAddress;
  final String notes;
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  final List<DoctorBookingItem> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctorBookings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DoctorApiService.getDoctorBookings();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawBookings = List.from(data['bookings'] as List<dynamic>? ?? []);
        _bookings.clear();
        _bookings.addAll(rawBookings.map((rawBooking) {
          final item = rawBooking as Map<String, dynamic>;
          final user = item['userId'] as Map<String, dynamic>?;
          final treatment = item['treatment'] as Map<String, dynamic>?;
          final rawDate = treatment?['date']?.toString();
          final rawTime = treatment?['time']?.toString();
          final appointmentTime = _parseBookingDateTime(rawDate, rawTime) ?? DateTime.now();

          return DoctorBookingItem(
            id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
            patientName: user?['name']?.toString() ?? 'Unknown patient',
            appointmentTime: appointmentTime,
            status: item['status']?.toString() ?? 'PENDING',
            visitType: item['visitType']?.toString() ?? 'Clinic Visit',
            treatmentType: treatment?['type']?.toString() ?? 'Unknown',
            reason: treatment?['reason']?.toString() ?? 'No reason provided',
            details: treatment?['details']?.toString() ?? 'No additional details',
            locationAddress: item['location']?['addressText']?.toString() ?? 'No location provided',
            notes: treatment?['reason']?.toString() ?? 'No additional details',
          );
        }));
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        _errorMessage = data?['message']?.toString() ?? 'Failed to load bookings.';
      }
    } catch (error) {
      _errorMessage = 'Unable to load bookings: $error';
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

  List<DoctorBookingItem> _listFor(int index) {
    final now = DateTime.now();

    return _bookings.where((booking) {
      final appointment = booking.appointmentTime;
      final appointmentDate = DateTime(appointment.year, appointment.month, appointment.day);
      final today = DateTime(now.year, now.month, now.day);

      if (index == 0) {
        return appointmentDate == today;
      }
      if (index == 1) {
        return appointmentDate.isAfter(today);
      }
      return appointmentDate.isBefore(today);
    }).toList();
  }

  AppointmentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return AppointmentStatus.cancelled;
      case 'rescheduled':
        return AppointmentStatus.pending;
      default:
        return AppointmentStatus.pending;
    }
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
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_errorMessage != null) {
                      return Center(
                        child: Text(_errorMessage!, style: AppTextStyles.body),
                      );
                    }

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
                        final time = DateFormat('EEE, MMM d • h:mm a').format(a.appointmentTime);
                        final status = _statusFromString(a.status);
                        return AppCard(
                          padding: const EdgeInsets.all(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailPage(
                                    bookingId: a.id,
                                    patientName: a.patientName,
                                    appointmentTime: a.appointmentTime,
                                    status: a.status,
                                    visitType: a.visitType,
                                    treatmentType: a.treatmentType,
                                    reason: a.reason,
                                    details: a.details,
                                    locationAddress: a.locationAddress,
                                  ),
                                ),
                              );
                            },
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
                                          Text(a.visitType, style: AppTextStyles.caption),
                                          const SizedBox(height: 4),
                                          Text(time, style: AppTextStyles.caption),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: status),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (status == AppointmentStatus.pending) ...[
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
                                    if (status != AppointmentStatus.completed &&
                                        status != AppointmentStatus.cancelled)
                                      AppButton(
                                        label: 'Mark completed',
                                        variant: AppButtonVariant.outline,
                                        onPressed: () => _toast('Marked completed (mock)'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
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
