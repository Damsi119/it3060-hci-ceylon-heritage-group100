import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/heritage_auth_ui.dart';
import '../../widgets/heritage_message.dart';
import 'forgot_password_verify_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final values = [_username.text, _email.text, _phone.text];
    final provided = values.where((value) => value.trim().isNotEmpty).length;
    if (provided < 2) {
      showHeritageMessage(
        context,
        'Provide at least two account details',
        error: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await AuthService.instance.requestPasswordReset(
        username: _username.text,
        email: _email.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      showHeritageMessage(context, message);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ForgotPasswordVerifyScreen(initialEmail: _email.text.trim()),
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
    return HeritageAuthShell(
      showBack: true,
      badgeLabel: 'Account Recovery',
      badgeIcon: Icons.key_outlined,
      heroTitle: 'Recover your heritage access',
      heroSubtitle: 'Confirm your details and continue with a secure reset.',
      title: 'Forgot Password',
      subtitle:
          'Enter at least two account details. We will send a verification code to your registered email.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeritageAuthNotice(
            icon: Icons.verified_user_outlined,
            title: 'Identity check',
            message:
                'At least 2 of the 3 details below must match the same account before a reset code is sent.',
          ),
          const SizedBox(height: 15),
          HeritageAuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      color: HeritageAuthColors.primaryDark,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Find Your Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: HeritageAuthColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HeritageAuthField(
                  controller: _email,
                  label: 'Registered email',
                  hint: 'name@example.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 13),
                HeritageAuthField(
                  controller: _username,
                  label: 'Username',
                  hint: 'your username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 13),
                HeritageAuthField(
                  controller: _phone,
                  label: 'Phone number',
                  hint: '07XXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HeritageAuthColors.inputSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HeritageAuthColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: HeritageAuthColors.muted,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use the details saved on your Ceylon Heritage account.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: HeritageAuthColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HeritageAuthPrimaryButton(
                  label: 'Send verification code',
                  onPressed: _send,
                  loading: _loading,
                  icon: Icons.mark_email_read_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: HeritageAuthColors.primaryDark,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                'Back to Log in',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const HeritageAuthNotice(
            icon: Icons.support_agent_rounded,
            title: 'Still need help?',
            message:
                'Check your spam folder after requesting a code, or contact support if you no longer have access to your email.',
            color: HeritageAuthColors.successSoft,
            iconColor: HeritageAuthColors.success,
          ),
        ],
      ),
    );
  }
}
