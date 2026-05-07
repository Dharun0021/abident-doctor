import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _emailNotif = true;
  bool _smsNotif = false;
  bool _marketing = false;
  String _locale = 'English (UK)';

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text('Security and preferences for this workstation.', style: AppTextStyles.body),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Change password', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    const AppTextField(label: 'Current password', obscure: true, hint: '••••••••'),
                    const SizedBox(height: 14),
                    const AppTextField(label: 'New password', obscure: true, hint: '••••••••'),
                    const SizedBox(height: 14),
                    const AppTextField(label: 'Confirm password', obscure: true, hint: '••••••••'),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Update password',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated (mock).')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Appointment emails', style: AppTextStyles.title),
                      subtitle: Text('Confirmations and schedule changes', style: AppTextStyles.caption),
                      value: _emailNotif,
                      onChanged: (v) => setState(() => _emailNotif = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('SMS alerts', style: AppTextStyles.title),
                      subtitle: Text('Urgent patient messages', style: AppTextStyles.caption),
                      value: _smsNotif,
                      onChanged: (v) => setState(() => _smsNotif = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Product updates', style: AppTextStyles.title),
                      subtitle: Text('Occasional tips from Abident', style: AppTextStyles.caption),
                      value: _marketing,
                      onChanged: (v) => setState(() => _marketing = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Language & region'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _locale,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'English (UK)', child: Text('English (UK)')),
                        DropdownMenuItem(value: 'English (US)', child: Text('English (US)')),
                      ],
                      onChanged: (v) => setState(() => _locale = v ?? _locale),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
