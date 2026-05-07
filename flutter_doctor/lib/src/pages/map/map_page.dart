import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../services/mock_data.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final pad = pagePadding(context);
    final markers = repo.mapPatients;

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Map / Navigation', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 8),
                  Text('Mock map UI — tap a marker, then navigate.', style: AppTextStyles.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: context.isMobile ? 320 : 420,
                            child: LayoutBuilder(
                              builder: (context, c) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFE8F4F3), Color(0xFFF7F8FA)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: _MapGridPainter(),
                                    ),
                                    ...List.generate(markers.length, (i) {
                                      final m = markers[i];
                                      return Positioned(
                                        left: m.offset.dx * c.maxWidth - 18,
                                        top: m.offset.dy * c.maxHeight - 36,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selected = i),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                color: _selected == i ? AppColors.primary : AppColors.textSecondary,
                                                size: 36,
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardBackground,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  m.name.split(' ').first,
                                                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!context.isMobile) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Patients on map', style: AppTextStyles.headingSmall),
                              const SizedBox(height: 12),
                              ...List.generate(markers.length, (i) {
                                final m = markers[i];
                                final on = _selected == i;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: on ? AppColors.sidebarActive : AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: () => setState(() => _selected = i),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m.name, style: AppTextStyles.title),
                                            const SizedBox(height: 4),
                                            Text(m.address, style: AppTextStyles.caption),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const Spacer(),
                              AppButton(
                                label: 'Navigate',
                                icon: Icons.navigation_rounded,
                                expanded: true,
                                onPressed: _selected == null
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Opening directions to ${markers[_selected!].address} (mock).',
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (context.isMobile) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Navigate to selected',
              icon: Icons.navigation_rounded,
              expanded: true,
              onPressed: _selected == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opening directions to ${markers[_selected!].address} (mock).',
                          ),
                        ),
                      );
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
