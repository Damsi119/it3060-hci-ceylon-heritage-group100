import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_button.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/heritage_section_title.dart';
import '../../widgets/heritage_text_field.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _username,
      _email,
      _phone,
      _address,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showHeritageMessage(
        context,
        'Please accept the heritage terms',
        error: true,
      );
      return;
    }

    final parts = _fullName.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        confirmPassword: _confirm.text,
        firstName: firstName,
        lastName: lastName,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: _email.text.trim()),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? 'Required' : null;

    return AuthShell(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeritageBadge(
              label: 'Field Notebook & Archive',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 10),
            const HeritageSectionTitle(
              title: 'Sign up',
              subtitle:
                  'Create a tourist account and verify your email with OTP.',
            ),
            const SizedBox(height: 14),
            const HeritageCard(
              color: AppColors.surfaceWarm,
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tourist accounts are activated after email OTP verification.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HeritageTextField(
              controller: _fullName,
              label: 'Full name',
              hint: 'Maya Senanayake',
              icon: Icons.person_outline,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _username,
              label: 'Username',
              hint: 'maya.s',
              icon: Icons.badge_outlined,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _email,
              label: 'Email',
              hint: 'name@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (required(value) != null) return 'Required';
                if (!value!.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _phone,
              label: 'Phone number',
              hint: '07XXXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: required,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _address,
              label: 'Address (optional)',
              hint: 'Galle, Sri Lanka',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _password,
              label: 'Password',
              hint: 'Create secure passcode',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 8)
                  return 'Use at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            HeritageTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Repeat passcode',
              icon: Icons.verified_user_outlined,
              obscureText: true,
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _agreed,
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              title: const Text(
                'I agree to preserve historical fieldnotes in accordance with the Heritage Charter.',
                style: TextStyle(fontSize: 10.5, height: 1.35),
              ),
            ),
            const SizedBox(height: 8),
            HeritagePrimaryButton(
              label: 'Create account',
              onPressed: _submit,
              loading: _loading,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Already have an account?  Login',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const HeritageCard(
              color: AppColors.greenSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.public_rounded, color: AppColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'UNESCO FIELD SYNC · OFFLINE MODE\nField access at UNESCO World Heritage sites in Galle, Kandy & Sigiriya.',
                      style: TextStyle(fontSize: 9.7, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
