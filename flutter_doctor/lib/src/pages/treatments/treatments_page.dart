import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../services/mock_data.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_theme.dart';
import '../../utils/responsive.dart';

class TreatmentsPage extends StatefulWidget {
  const TreatmentsPage({super.key});

  @override
  State<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends State<TreatmentsPage> {
  final _diag = TextEditingController();
  final _notes = TextEditingController();
  final _med = TextEditingController();
  DateTime? _next = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _diag.dispose();
    _notes.dispose();
    _med.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final timeline = repo.patientTreatments['pt1'] ?? [];
    final pad = pagePadding(context);

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Treatments', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text('Document care plans with attachments and follow-ups.', style: AppTextStyles.body),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add treatment', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Diagnosis', controller: _diag, hint: 'e.g. Caries MO tooth 16'),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Notes', controller: _notes, maxLines: 3, hint: 'Clinical notes'),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Medication', controller: _med, hint: 'Prescriptions / rinse'),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Next visit', style: AppTextStyles.label),
                      subtitle: Text(
                        _next == null ? 'Not set' : DateFormat('EEE, MMM d, y').format(_next!),
                        style: AppTextStyles.body,
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _next ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (d != null) setState(() => _next = d);
                        },
                        child: const Text('Pick date'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Before / after photos', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _UploadTile(label: 'Before', icon: Icons.photo_camera_back_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: _UploadTile(label: 'After', icon: Icons.photo_camera_front_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Save treatment',
                      expanded: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Treatment saved (mock).')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Treatment timeline', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              if (timeline.isEmpty)
                Text('No items yet.', style: AppTextStyles.body)
              else
                ...timeline.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.diagnosis, style: AppTextStyles.title),
                                const SizedBox(height: 4),
                                Text(DateFormat('MMM d, y').format(t.date), style: AppTextStyles.caption),
                                const SizedBox(height: 8),
                                Text(t.notes, style: AppTextStyles.body),
                                const SizedBox(height: 8),
                                Text('Medication: ${t.medication}', style: AppTextStyles.caption),
                                if (t.nextVisit != null)
                                  Text(
                                    'Next: ${DateFormat('MMM d, y').format(t.nextVisit!)}',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label upload (mock).')),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          height: 110,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.caption),
              Text('Tap to upload', style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}
