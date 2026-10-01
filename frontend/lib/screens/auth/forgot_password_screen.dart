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
    return AuthShell(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeritageBadge(
            label: 'Account Recovery',
            icon: Icons.key_outlined,
          ),
          const SizedBox(height: 10),
          const HeritageSectionTitle(
            title: 'Forgot Password',
            subtitle:
                'Enter at least two account details. We will send an archival verification code to your registered email.',
          ),
          const SizedBox(height: 14),
          const HeritageCard(
            color: AppColors.surfaceWarm,
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ACCOUNT RECOVERY\nIdentity matching uses your stored account details.',
                    style: TextStyle(fontSize: 9.8, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HeritageTextField(
            controller: _email,
            label: 'Registered email',
            hint: 'name@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          HeritageTextField(
            controller: _username,
            label: 'Username',
            hint: 'your username',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          HeritageTextField(
            controller: _phone,
            label: 'Phone number',
            hint: '07XXXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          const Text(
            'At least 2 of the 3 details above must match the same account.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          HeritagePrimaryButton(
            label: 'Send verification code',
            onPressed: _send,
            loading: _loading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Log in'),
            ),
          ),
          const SizedBox(height: 12),
          const HeritageCard(
            color: AppColors.greenSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Need help accessing your pass? Check your spam folder or contact the archival registry desk if you no longer have access to the email.',
                    style: TextStyle(fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
