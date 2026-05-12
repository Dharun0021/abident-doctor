import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_card.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';
import 'patient_detail_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _search = TextEditingController();
  String _q = '';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _q = _search.text));
    _loadPatients();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DoctorApiService.getDoctorPatients();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final patients = (data['patients'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        setState(() {
          _patients = patients;
        });
      } else {
        setState(() {
          _error = 'Unable to load patients';
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
    final list = _patients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      return name.contains(_q.toLowerCase()) || email.contains(_q.toLowerCase());
    }).toList();
    final pad = pagePadding(context);
    final maxW = contentMaxWidth(context);

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Patients', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 8),
                  Text('Search and view patient details.', style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!, style: AppTextStyles.body.copyWith(color: Colors.red)))
                        : list.isEmpty
                            ? Center(child: Text('No patients found.', style: AppTextStyles.body))
                            : ListView.separated(
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final p = list[i];
                                  final lastBooking = p['lastBooking'] as Map<String, dynamic>?;
                                  final lastText = lastBooking == null
                                      ? 'New patient'
                                      : 'Last: ${DateFormat('MMM d, y').format(DateTime.parse(lastBooking['date'] as String))}';
                                  return AppCard(
                                    padding: const EdgeInsets.all(16),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PatientDetailPage(patientId: p['id'] as String),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.accentSoft,
                                          child: Text(
                                            (p['name'] as String)
                                                .split(' ')
                                                .map((e) => e.isNotEmpty ? e[0] : '')
                                                .take(2)
                                                .join(),
                                            style: AppTextStyles.title,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p['name'] as String, style: AppTextStyles.headingSmall),
                                              const SizedBox(height: 2),
                                              Text(p['email'] as String? ?? '', style: AppTextStyles.caption),
                                              Text(lastText, style: AppTextStyles.caption),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
