import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_button.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/heritage_section_title.dart';
import '../../widgets/heritage_text_field.dart';
import '../home/home_router.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.user,
    this.forced = false,
    this.initialCurrentPassword,
  });

  final UserProfile user;
  final bool forced;
  final String? initialCurrentPassword;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _current;
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController(text: widget.initialCurrentPassword ?? '');
  }

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = await UserService.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _newPassword.text,
        confirmPassword: _confirm.text,
      );
      final updated = await UserService.instance.getProfile();
      if (!mounted) return;
      showHeritageMessage(context, message);
      if (widget.forced) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeRouter(user: updated)),
          (_) => false,
        );
      } else {
        Navigator.pop(context, updated);
      }
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: AuthShell(
        showBack: !widget.forced,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeritageBadge(
                label: widget.forced
                    ? 'First Login Security'
                    : 'Account Security',
                icon: Icons.security_rounded,
              ),
              const SizedBox(height: 10),
              HeritageSectionTitle(
                title: widget.forced
                    ? 'Set your own password'
                    : 'Change password',
                subtitle: widget.forced
                    ? 'Your guide account was created with a temporary password. Replace it before continuing.'
                    : 'Update the password used for your Ceylon Heritage account.',
              ),
              const SizedBox(height: 16),
              if (widget.forced)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: HeritageCard(
                    color: AppColors.surfaceWarm,
                    child: Text(
                      'The temporary password was sent only to your approved guide email. Admin cannot see your new password.',
                      style: TextStyle(fontSize: 10.5, height: 1.45),
                    ),
                  ),
                ),
              HeritageTextField(
                controller: _current,
                label: widget.forced
                    ? 'Temporary password'
                    : 'Current password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              HeritageTextField(
                controller: _newPassword,
                label: 'New password',
                icon: Icons.key_outlined,
                obscureText: true,
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              HeritageTextField(
                controller: _confirm,
                label: 'Confirm new password',
                icon: Icons.verified_user_outlined,
                obscureText: true,
                validator: (value) => value != _newPassword.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 18),
              HeritagePrimaryButton(
                label: 'Save password',
                onPressed: _save,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
