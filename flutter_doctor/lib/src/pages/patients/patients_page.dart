import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_card.dart';
import '../../services/mock_data.dart';
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

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _q = _search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final list = repo.patients
        .where(
          (p) =>
              p.name.toLowerCase().contains(_q.toLowerCase()) ||
              p.email.toLowerCase().contains(_q.toLowerCase()),
        )
        .toList();
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
                  Text('Search and open a patient chart.', style: AppTextStyles.body),
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
                child: list.isEmpty
                    ? Center(child: Text('No matches.', style: AppTextStyles.body))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = list[i];
                          final last = p.lastVisit == null
                              ? 'New patient'
                              : 'Last visit: ${DateFormat('MMM d, y').format(p.lastVisit!)}';
                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PatientDetailPage(patientId: p.id),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.accentSoft,
                                  child: Text(
                                    p.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                                    style: AppTextStyles.title,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: AppTextStyles.headingSmall),
                                      const SizedBox(height: 2),
                                      Text(p.email, style: AppTextStyles.caption),
                                      Text(last, style: AppTextStyles.caption),
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
