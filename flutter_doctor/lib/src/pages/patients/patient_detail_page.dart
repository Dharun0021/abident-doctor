import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../services/mock_data.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final p = repo.patients.firstWhere((e) => e.id == patientId, orElse: () => repo.patients.first);
    final appts = repo.patientAppointments[p.id] ?? [];
    final treatments = repo.patientTreatments[p.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(p.name, style: AppTextStyles.headingSmall),
      ),
      body: ListView(
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
                    p.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
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
                      _InfoRow(icon: Icons.phone_rounded, text: p.phone),
                      _InfoRow(icon: Icons.email_outlined, text: p.email),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        text: 'DOB: ${DateFormat('MMM d, y').format(p.dob)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Appointment history', style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          if (appts.isEmpty)
            Text('No history yet.', style: AppTextStyles.body)
          else
            ...appts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM d, y • h:mm a').format(a.time), style: AppTextStyles.title),
                            Text(a.status.name, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.event_note_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('Treatment history', style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          if (treatments.isEmpty)
            Text('No treatments recorded.', style: AppTextStyles.body)
          else
            ...treatments.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.diagnosis, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d, y').format(t.date), style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Text(t.notes, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
            ),
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
      ),
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
