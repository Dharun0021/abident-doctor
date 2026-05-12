import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final List<DateTime> _weekDays = List.generate(
    7,
    (index) {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index));
      return date;
    },
  );

  final List<int> _appointments = List.filled(7, 0);
  final List<int> _completed = List.filled(7, 0);
  final List<int> _cancelled = List.filled(7, 0);
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DoctorApiService.getDoctorBookings();
      if (response.statusCode != 200) {
        _errorMessage = 'Unable to load reports.';
        return;
      }

      final bookings = await _parseBookings(response.body);
      for (final booking in bookings) {
        final treatment = booking['treatment'] as Map<String, dynamic>?;
        final rawDate = treatment?['date']?.toString();
        if (rawDate == null) {
          continue;
        }

        final bookingDate = DateTime.tryParse(rawDate);
        if (bookingDate == null) {
          continue;
        }

        final index = _weekDays.indexWhere((day) => day.year == bookingDate.year && day.month == bookingDate.month && day.day == bookingDate.day);
        if (index < 0) {
          continue;
        }

        final status = booking['status']?.toString().toLowerCase() ?? 'pending';
        _appointments[index] += 1;
        if (status == 'completed') {
          _completed[index] += 1;
        } else if (status == 'cancelled' || status == 'canceled') {
          _cancelled[index] += 1;
        }
      }
    } catch (error) {
      _errorMessage = 'Unable to load reports: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _parseBookings(String body) async {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawBookings = List.from(data['bookings'] as List<dynamic>? ?? []);
      return rawBookings.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _downloadReport() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Report'];
      sheet.appendRow(['Date', 'Appointments', 'Completed', 'Cancelled']);

      for (var i = 0; i < _weekDays.length; i++) {
        sheet.appendRow([
          DateFormat('EEE, MMM d').format(_weekDays[i]),
          _appointments[i],
          _completed[i],
          _cancelled[i],
        ]);
      }

      final output = excel.save();
      if (output == null) {
        throw Exception('Could not create Excel file.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'doctor_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(output);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download report: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final maxAppt = _appointments.isNotEmpty ? _appointments.reduce((a, b) => a > b ? a : b) : 1;
    final totalCompleted = _completed.fold(0, (prev, item) => prev + item);
    final totalCancelled = _cancelled.fold(0, (prev, item) => prev + item);
    final totalAppointments = _appointments.fold(0, (prev, item) => prev + item);

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Reports', style: AppTextStyles.headingLarge)),
                  AppButton(
                    label: 'Download Excel',
                    icon: Icons.download_rounded,
                    onPressed: _appointments.every((count) => count == 0) ? null : _downloadReport,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Operational trends for the last 7 days, powered by live doctor bookings.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_errorMessage!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total appointments', style: AppTextStyles.caption),
                              const SizedBox(height: 10),
                              Text('$totalAppointments', style: AppTextStyles.headingLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Completed', style: AppTextStyles.caption),
                              const SizedBox(height: 10),
                              Text('$totalCompleted', style: AppTextStyles.headingLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cancelled', style: AppTextStyles.caption),
                              const SizedBox(height: 10),
                              Text('$totalCancelled', style: AppTextStyles.headingLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 720;
                    final chart = AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Appointments per day', style: AppTextStyles.headingSmall),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: CustomPaint(
                              painter: _BarChartPainter(),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(_appointments.length, (i) {
                                    final h = 160 * (_appointments[i] / (maxAppt == 0 ? 1 : maxAppt));
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              height: h.clamp(8, 160),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.85),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(DateFormat('E').format(_weekDays[i]), style: AppTextStyles.caption),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    final compare = AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Completed vs cancelled', style: AppTextStyles.headingSmall),
                          const SizedBox(height: 16),
                          ...List.generate(_weekDays.length, (i) {
                            final total = (_completed[i] + _cancelled[i]).clamp(1, 999);
                            final donePct = _completed[i] / total;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(DateFormat('E').format(_weekDays[i]), style: AppTextStyles.caption),
                                      const Spacer(),
                                      Text('${_completed[i]} done • ${_cancelled[i]} cancelled', style: AppTextStyles.caption),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: donePct,
                                      minHeight: 10,
                                      backgroundColor: AppColors.error.withValues(alpha: 0.15),
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                    if (narrow) {
                      return Column(
                        children: [
                          chart,
                          const SizedBox(height: 16),
                          compare,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: chart),
                        const SizedBox(width: 16),
                        Expanded(child: compare),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => false;
}
