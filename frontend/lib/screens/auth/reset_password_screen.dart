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
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = await AuthService.instance.resetPassword(
        email: widget.email,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      showHeritageMessage(context, message);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeritageBadge(
              label: 'Identity Recovery',
              icon: Icons.lock_reset_rounded,
            ),
            const SizedBox(height: 10),
            const HeritageSectionTitle(
              title: 'Reset Password',
              subtitle:
                  'Choose a new, unique password for your Ceylon Heritage archive account.',
            ),
            const SizedBox(height: 18),
            HeritageTextField(
              controller: _password,
              label: 'New password',
              hint: 'Enter new passcode',
              icon: Icons.key_outlined,
              obscureText: true,
              validator: (value) => value == null || value.length < 8
                  ? 'Use at least 8 characters'
                  : null,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                '• 8+ characters\n• Use a combination of letters, numbers and symbols',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 13),
            HeritageTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter new passcode',
              icon: Icons.verified_user_outlined,
              obscureText: true,
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 17),
            HeritagePrimaryButton(
              label: 'Save password',
              onPressed: _save,
              loading: _loading,
            ),
            const SizedBox(height: 14),
            const HeritageCard(
              color: AppColors.greenSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, color: AppColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Passwords are stored securely using one-way hashing. Your plain password is never stored in the archive.',
                      style: TextStyle(fontSize: 10, height: 1.4),
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
