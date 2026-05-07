import 'package:flutter/material.dart';

import '../../components/app_card.dart';
import '../../services/mock_data.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final appts = repo.appointmentsPerDay;
    final done = repo.completedPerDay;
    final cancelled = repo.cancelledPerDay;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final pad = pagePadding(context);
    final maxAppt = appts.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reports', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text('Operational trends — mock data for UI preview.', style: AppTextStyles.body),
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
                                children: List.generate(appts.length, (i) {
                                  final h = 160 * (appts[i] / maxAppt);
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
                                          Text(days[i], style: AppTextStyles.caption),
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
                        ...List.generate(days.length, (i) {
                          final total = (done[i] + cancelled[i]).clamp(1, 999);
                          final donePct = done[i] / total;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(days[i], style: AppTextStyles.caption),
                                    const Spacer(),
                                    Text('${done[i]} done • ${cancelled[i]} cancelled', style: AppTextStyles.caption),
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
