import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_text_field.dart';
import '../../services/doctor_api_service.dart';
import '../../services/doctor_auth_storage.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final name = await DoctorAuthStorage.getDoctorName();
    final email = await DoctorAuthStorage.getDoctorEmail();
    final spec = await DoctorAuthStorage.getSpecialization();

    _nameController.text = name ?? '';
    _emailController.text = email ?? '';
    _specializationController.text = spec ?? '';

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await DoctorApiService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        specialization: _specializationController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final doctor = (data['doctor'] ?? {}) as Map<String, dynamic>;
        await DoctorAuthStorage.updateDoctorData(
          name: doctor['name']?.toString(),
          email: doctor['email']?.toString(),
          specialization: doctor['specialization']?.toString(),
        );

        _passwordController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']?.toString() ?? 'Update failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pad = pagePadding(context);

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile Settings', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text('Update your professional details and account settings.', style: AppTextStyles.body),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Professional Profile', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _specializationController,
                      label: 'Specialty',
                      hint: 'e.g. General Dentist',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Account Security', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hint: 'your.email@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'New password (leave blank to keep current)',
                      hint: 'Minimum 6 characters',
                      obscure: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Changes',
                expanded: true,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
