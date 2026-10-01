import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/auth_response.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/heritage_button.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/heritage_section_title.dart';
import '../../widgets/heritage_text_field.dart';
import '../guide/guide_request_screen.dart';
import '../home/home_router.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await AuthService.instance.login(
        _identifier.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      _openAfterLogin(response, currentPassword: _password.text);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } catch (e) {
      if (mounted) showHeritageMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _googleLoading = true);
    try {
      final idToken = await GoogleAuthService.instance.getIdToken();
      final response = await AuthService.instance.googleLogin(idToken);
      if (!mounted) return;
      _openAfterLogin(response);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } catch (e) {
      if (mounted) showHeritageMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _openAfterLogin(AuthResponse response, {String? currentPassword}) {
    if (response.user.passwordChangeRequired) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(
            user: response.user,
            forced: true,
            initialCurrentPassword: currentPassword,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeRouter(user: response.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeritageCard(
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(
                children: [
                  HeritageLogo(compact: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'User Account Access',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const HeritageSectionTitle(
              title: 'Login',
              subtitle:
                  'Login to manage your account, profile, password, and notifications.',
            ),
            const SizedBox(height: 18),
            HeritageTextField(
              controller: _identifier,
              label: 'Email, username or phone',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your email, username or phone'
                  : null,
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _password,
              obscureText: true,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            HeritagePrimaryButton(
              label: 'Log in',
              onPressed: _login,
              loading: _loading,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: AppColors.textMuted.withValues(alpha: .95),
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _googleLoading ? null : _googleLogin,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE7E7E7),
                  foregroundColor: AppColors.text,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: _googleLoading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Google sign in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 13),
            HeritageCard(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              color: AppColors.surfaceWarm,
              child: Column(
                children: [
                  const Text(
                    'Need a tourist account?',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HeritageCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuideRequestScreen()),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              color: AppColors.greenSoft,
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.badge_outlined, color: AppColors.green),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request a guide account',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Submit your details for admin review.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
