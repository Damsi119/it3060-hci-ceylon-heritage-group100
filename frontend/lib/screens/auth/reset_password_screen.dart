import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/heritage_auth_ui.dart';
import '../../widgets/heritage_message.dart';
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
    return HeritageAuthShell(
      showBack: true,
      badgeLabel: 'New Password',
      badgeIcon: Icons.lock_reset_rounded,
      heroTitle: 'Set a stronger password',
      heroSubtitle: 'Finish account recovery with a private new password.',
      title: 'Reset Password',
      subtitle:
          'Choose a new, unique password for your Ceylon Heritage account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeritageAuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeritageAuthField(
                    controller: _password,
                    label: 'New password',
                    hint: 'Enter new password',
                    icon: Icons.key_outlined,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HeritageAuthColors.inputSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HeritageAuthColors.border),
                    ),
                    child: const Text(
                      '- 8+ characters\n- Use a combination of letters, numbers and symbols',
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.5,
                        color: HeritageAuthColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  HeritageAuthField(
                    controller: _confirm,
                    label: 'Confirm password',
                    hint: 'Re-enter new password',
                    icon: Icons.verified_user_outlined,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 17),
                  HeritageAuthPrimaryButton(
                    label: 'Save password',
                    onPressed: _save,
                    loading: _loading,
                    icon: Icons.lock_reset_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const HeritageAuthNotice(
              icon: Icons.security_rounded,
              title: 'Secure storage',
              message:
                  'Passwords are stored securely using one-way hashing. Your plain password is never stored.',
              color: HeritageAuthColors.successSoft,
              iconColor: HeritageAuthColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
