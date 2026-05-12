import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';

class PatientDetailPage extends StatefulWidget {
  const PatientDetailPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DoctorApiService.getDoctorPatientById(patientId: widget.patientId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _patient = data['patient'] as Map<String, dynamic>?;
          _bookings = (data['bookings'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
        });
      } else {
        final data = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : {};
        setState(() {
          _error = data['message']?.toString() ?? 'Unable to load patient details';
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _patient != null ? (_patient!['name'] as String) : 'Patient details',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body.copyWith(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final name = _patient!['name'] as String? ?? 'Unknown';
    final email = _patient!['email'] as String? ?? 'No email';
    final phone = _patient!['phone'] as String? ?? 'No phone';
    final dobValue = _patient!['dob'];
    final dob = dobValue != null ? DateTime.tryParse(dobValue as String) : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                  style: AppTextStyles.headingSmall,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient info', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.phone_rounded, text: phone),
                    _InfoRow(icon: Icons.email_outlined, text: email),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Appointment history', style: AppTextStyles.headingSmall),
        const SizedBox(height: 10),
        if (_bookings.isEmpty)
          Text('No appointment history for this patient.', style: AppTextStyles.body)
        else
          AppCard(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Type')),
                ],
                rows: _bookings.map((a) {
                  final rawDate = a['treatment']?['date']?.toString() ?? '';
                  final date = DateTime.tryParse(rawDate);
                  final dateLabel = date != null
                      ? DateFormat('MMM d, y').format(date)
                      : rawDate.isNotEmpty
                          ? rawDate
                          : 'Unknown';
                  final status = a['status']?.toString() ?? 'Unknown';
                  final type = a['treatment']?['type']?.toString() ?? 'Unknown';

                  return DataRow(
                    cells: [
                      DataCell(Text(dateLabel)),
                      DataCell(Text(status)),
                      DataCell(Text(type)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Treatment notes', style: AppTextStyles.headingSmall),
        const SizedBox(height: 10),
        if (_bookings.isEmpty)
          Text('No treatment notes available.', style: AppTextStyles.body)
        else
          ..._bookings.expand((a) {
            final treatment = a['treatment'] as Map<String, dynamic>?;
            if (treatment == null) return <Widget>[];
            return [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(treatment['type'] ?? 'Treatment', style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text('Reason: ${treatment['reason'] ?? 'Not provided'}', style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Text(treatment['details'] ?? 'No additional notes', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
            ];
          }),
        const SizedBox(height: 8),
        Text('Clinical notes', style: AppTextStyles.headingSmall),
        const SizedBox(height: 10),
        AppCard(
          child: AppTextField(
            hint: 'Private notes (mock — not saved)',
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
