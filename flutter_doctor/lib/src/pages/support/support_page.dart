import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_theme.dart';
import '../../utils/responsive.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final faqs = [
      ('How do patients book?', 'They use the Abident patient app; requests appear under Appointments.'),
      ('Can I block a holiday?', 'Yes — Availability supports blocked dates.'),
      ('Is PHI stored here?', 'This build is UI-only; connect your backend to persist data.'),
    ];

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Help & Support', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text('Answers, contact, and next steps.', style: AppTextStyles.body),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('FAQ', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),
                    ...faqs.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$1, style: AppTextStyles.title),
                              const SizedBox(height: 6),
                              Text(e.$2, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Contact us', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    Text('We typically respond within one business day.', style: AppTextStyles.caption),
                    const SizedBox(height: 16),
                    const AppTextField(label: 'Subject', hint: 'Brief summary'),
                    const SizedBox(height: 14),
                    const AppTextField(label: 'Message', hint: 'How can we help?', maxLines: 5),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Send message',
                      expanded: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message sent (mock).')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
