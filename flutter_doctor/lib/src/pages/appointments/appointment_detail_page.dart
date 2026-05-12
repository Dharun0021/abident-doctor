import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../models/booking.dart';
import '../../pages/map/booking_map_detail_page.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';

class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({
    super.key,
    this.bookingId,
    this.title,
    this.message,
    this.patientName,
    this.appointmentTime,
    this.status = 'PENDING',
    this.visitType = 'Clinic Visit',
    this.treatmentType = 'Unknown',
    this.reason = 'No reason provided',
    this.details = 'No additional details',
    this.locationAddress = 'No location provided',
  });

  final String? bookingId;
  final String? title;
  final String? message;
  final String? patientName;
  final DateTime? appointmentTime;
  final String status;
  final String visitType;
  final String treatmentType;
  final String reason;
  final String details;
  final String locationAddress;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  bool _isLoading = false;
  String? _status;
  String? _message;
  DoctorBooking? _booking;
  bool _isLoadingBooking = false;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _message = null;
    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      _loadBookingDetails();
    }
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoadingBooking = true;
    });

    try {
      final response = await DoctorApiService.getDoctorBookingById(
        bookingId: widget.bookingId!,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bookingData = data['booking'] as Map<String, dynamic>?;
        if (bookingData != null) {
          setState(() {
            _booking = DoctorBooking.fromJson(bookingData);
          });
        }
      }
    } catch (_) {
      // Silent catch - we'll still show the page with available data
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBooking = false;
        });
      }
    }
  }

  Future<void> _sendResponse(String status, {DateTime? newTime}) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (widget.bookingId == null || widget.bookingId!.isEmpty) {
        setState(() {
          _message = 'Unable to update booking without an ID';
        });
        return;
      }

      final response = await DoctorApiService.respondToBooking(
        bookingId: widget.bookingId!,
        status: status,
        newTime: newTime?.toIso8601String(),
      );

      if (response.statusCode == 200) {
        setState(() {
          _status = status;
          _message = 'Booking updated successfully';
        });
      } else {
        final data = response.body.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(response.body) as Map)
            : {};
        setState(() {
          _message = data['message']?.toString() ?? 'Unable to update booking';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Network error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reschedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.appointmentTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: widget.appointmentTime != null
          ? TimeOfDay.fromDateTime(widget.appointmentTime!)
          : const TimeOfDay(hour: 9, minute: 0),
    );

    if (time == null) return;

    final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _sendResponse('RESCHEDULED', newTime: newDateTime);
  }

  String _friendlyStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      case 'RESCHEDULED':
        return 'Rescheduled';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = widget.appointmentTime != null
        ? DateFormat('EEE, MMM d • h:mm a').format(widget.appointmentTime!)
        : 'Time not available';

    final canRespond = widget.bookingId != null &&
        _status != null &&
        _status!.toUpperCase() != 'REJECTED' &&
        _status!.toUpperCase() != 'COMPLETED';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ListView(
          children: [
            const SizedBox(height: 4),
            Text(widget.title ?? 'Appointment details', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              Text(widget.message!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
            ],
            OverviewCard(
              title: widget.patientName ?? 'Unknown patient',
              subtitle: widget.visitType,
              status: _friendlyStatus(_status ?? widget.status),
              appointmentTime: timeLabel,
              location: widget.locationAddress,
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Treatment summary'),
            const SizedBox(height: 12),
            InfoRow(label: 'Treatment type', value: widget.treatmentType),
            const SizedBox(height: 12),
            InfoRow(label: 'Reason for visit', value: widget.reason),
            const SizedBox(height: 12),
            InfoRow(label: 'Patient notes', value: widget.details),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(_message!, style: AppTextStyles.body.copyWith(color: AppColors.success)),
            ],
            const SizedBox(height: 28),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (canRespond) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppButton(
                    label: 'Accept',
                    onPressed: () => _sendResponse('ACCEPTED'),
                  ),
                  AppButton(
                    label: 'Reject',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _sendResponse('REJECTED'),
                  ),
                  AppButton(
                    label: 'Reschedule',
                    variant: AppButtonVariant.outline,
                    onPressed: _reschedule,
                  ),
                  AppButton(
                    label: 'Mark completed',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _sendResponse('COMPLETED'),
                  ),
                  if (_booking != null && _booking!.location.hasValidCoordinates)
                    AppButton(
                      label: 'View on Map',
                      variant: AppButtonVariant.outline,
                      icon: Icons.map,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingMapDetailPage(booking: _booking!),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ] else ...[
              if (_booking != null && _booking!.location.hasValidCoordinates)
                AppButton(
                  label: 'View on Map',
                  variant: AppButtonVariant.outline,
                  icon: Icons.map,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingMapDetailPage(booking: _booking!),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall);
  }
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.appointmentTime,
    required this.location,
  });

  final String title;
  final String subtitle;
  final String status;
  final String appointmentTime;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Text(title, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: AppTextStyles.body.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoRow(label: 'Appointment', value: appointmentTime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoRow(label: 'Location', value: location),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: AppTextStyles.body),
        ),
      ],
    );
  }
}
