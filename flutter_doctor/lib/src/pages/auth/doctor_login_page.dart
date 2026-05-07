import 'dart:convert';

import 'package:flutter/material.dart';

import '../../layouts/doctor_shell.dart';
import '../../services/doctor_api_service.dart';
import '../../services/doctor_auth_storage.dart';
import 'doctor_register_page.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DoctorApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (response.statusCode == 200) {
        final doctor = (data['doctor'] ?? {}) as Map<String, dynamic>;
        await DoctorAuthStorage.saveSession(
          token: data['token']?.toString() ?? '',
          doctorId: doctor['id']?.toString() ?? '',
          doctorName: doctor['name']?.toString() ?? '',
          doctorEmail: doctor['email']?.toString() ?? '',
          specialization: doctor['specialization']?.toString() ?? '',
        );

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DoctorShell()),
          (_) => false,
        );
      } else {
        setState(() {
          _errorMessage = data['message']?.toString() ?? 'Login failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password required' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DoctorRegisterPage(),
                        ),
                      );
                    },
                    child: const Text('No account? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
