import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/heritage_auth_ui.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/otp_code_input.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.initialMessage,
  });

  final String email;
  final String? initialMessage;

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

    final initialMessage = widget.initialMessage;
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showHeritageMessage(context, initialMessage);
      });
    }
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
    return '${name.substring(0, 2)}****@${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    return HeritageAuthShell(
      showBack: true,
      badgeLabel: 'Email Security',
      badgeIcon: Icons.shield_outlined,
      heroTitle: 'Confirm your email',
      heroSubtitle: 'One code completes your Ceylon Heritage registration.',
      title: 'Verify your email',
      subtitle: 'We sent a 6-digit verification code to your registered email.',
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
                        Icons.mail_outline_rounded,
                        color: HeritageAuthColors.primaryDark,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Code sent to $_maskedEmail',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _seconds > 0
                            ? 'Resend code in 00:${_seconds.toString().padLeft(2, '0')}'
                            : 'Did not receive the code?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: HeritageAuthColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _seconds == 0 && !_resending ? _resend : null,
                      style: TextButton.styleFrom(
                        foregroundColor: HeritageAuthColors.primaryDark,
                      ),
                      child: Text(
                        _resending ? 'Sending...' : 'Resend',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const HeritageAuthNotice(
            icon: Icons.lock_outline_rounded,
            title: 'Code safety',
            message: 'Verification codes expire in 5 minutes.',
          ),
        ],
      ),
    );
  }
}
