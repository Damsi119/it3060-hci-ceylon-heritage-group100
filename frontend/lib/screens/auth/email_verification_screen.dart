import 'dart:async';

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
import '../../widgets/otp_code_input.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  bool _loading = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      showHeritageMessage(
        context,
        'Enter the 6-digit verification code',
        error: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final message = await AuthService.instance.verifyEmail(
        widget.email,
        _code.text,
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

  Future<void> _resend() async {
    if (_seconds > 0) return;
    setState(() => _resending = true);
    try {
      final message = await AuthService.instance.resendEmailOtp(widget.email);
      if (!mounted) return;
      showHeritageMessage(context, message);
      _startTimer();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts.first.length < 2) return widget.email;
    final name = parts.first;
    return '${name.substring(0, 2)}••••@${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeritageBadge(
            label: 'Two-factor security',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 10),
          const HeritageSectionTitle(
            title: 'Verify your email',
            subtitle:
                'We sent a 6-digit archaeological access code to your registered email.',
          ),
          const SizedBox(height: 14),
          HeritageCard(
            color: AppColors.surfaceWarm,
            child: Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter the 6-digit code dispatched to $_maskedEmail',
                    style: const TextStyle(fontSize: 10.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OtpCodeInput(controller: _code),
          const SizedBox(height: 16),
          HeritagePrimaryButton(
            label: 'Verify code',
            onPressed: _verify,
            loading: _loading,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _seconds > 0
                    ? 'Resend code in 00:${_seconds.toString().padLeft(2, '0')}'
                    : 'Didn\'t receive the code?',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: _seconds == 0 && !_resending ? _resend : null,
                child: Text(_resending ? 'Sending...' : 'Resend'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const HeritageCard(
            color: AppColors.greenSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 19,
                  color: AppColors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Passcodes expire in 5 minutes to protect your account.',
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
