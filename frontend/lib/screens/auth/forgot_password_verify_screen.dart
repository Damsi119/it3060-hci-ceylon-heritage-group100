import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/heritage_auth_ui.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/otp_code_input.dart';
import 'reset_password_screen.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  const ForgotPasswordVerifyScreen({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState
    extends State<ForgotPasswordVerifyScreen> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  bool _loading = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
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
    if (_email.text.trim().isEmpty) {
      showHeritageMessage(
        context,
        'Enter the registered email where the code was sent',
        error: true,
      );
      return;
    }
    if (_code.text.length != 6) {
      showHeritageMessage(context, 'Enter the 6-digit code', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.verifyPasswordResetOtp(
        _email.text.trim(),
        _code.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: _email.text.trim()),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_email.text.trim().isEmpty) {
      showHeritageMessage(
        context,
        'Enter your registered email first',
        error: true,
      );
      return;
    }
    setState(() => _resending = true);
    try {
      final message = await AuthService.instance.resendPasswordResetOtp(
        _email.text.trim(),
      );
      if (!mounted) return;
      showHeritageMessage(context, message);
      _startTimer();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeritageAuthShell(
      showBack: true,
      badgeLabel: 'Secure Code',
      badgeIcon: Icons.verified_user_outlined,
      heroTitle: 'Check your reset code',
      heroSubtitle: 'The code protects your account before a new password.',
      title: 'Verify reset code',
      subtitle:
          'Enter the verification code sent to the email linked with your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeritageAuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HeritageAuthColors.soft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: HeritageAuthColors.primaryDark,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.initialEmail.isEmpty
                            ? 'Enter the email used for recovery'
                            : 'Code sent to ${widget.initialEmail}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: HeritageAuthColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.initialEmail.isEmpty) ...[
                  const SizedBox(height: 16),
                  HeritageAuthField(
                    controller: _email,
                    label: 'Registered email',
                    hint: 'name@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
                const SizedBox(height: 18),
                OtpCodeInput(
                  controller: _code,
                  activeColor: HeritageAuthColors.primary,
                  borderColor: HeritageAuthColors.border,
                  fillColor: HeritageAuthColors.inputSurface,
                  textColor: HeritageAuthColors.primaryDark,
                ),
                const SizedBox(height: 16),
                HeritageAuthPrimaryButton(
                  label: 'Verify code',
                  onPressed: _verify,
                  loading: _loading,
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _seconds == 0 && !_resending ? _resend : null,
                    style: TextButton.styleFrom(
                      foregroundColor: HeritageAuthColors.primaryDark,
                    ),
                    child: Text(
                      _resending
                          ? 'Sending...'
                          : _seconds > 0
                          ? 'Resend in 00:${_seconds.toString().padLeft(2, '0')}'
                          : 'Resend code',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const HeritageAuthNotice(
            icon: Icons.schedule_rounded,
            title: 'Time limit',
            message: 'The reset code expires in 5 minutes.',
          ),
        ],
      ),
    );
  }
}
