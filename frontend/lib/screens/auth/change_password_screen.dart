import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/api_config.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';
import '../home/home_router.dart';

// Matches the Profile and Edit Profile redesign. No third-party packages.
class _SecurityColors {
  static const background = Color(0xFFFCF8F3);
  static const white = Colors.white;
  static const coffee = Color(0xFF893B0B);
  static const deepCoffee = Color(0xFF54220B);
  static const peach = Color(0xFFFFE9DC);
  static const palePeach = Color(0xFFFFF5ED);
  static const ink = Color(0xFF172035);
  static const muted = Color(0xFF777987);
  static const border = Color(0xFFF1E7DF);
  static const inactive = Color(0xFFE8D9CD);
  static const danger = Color(0xFFC74435);
}

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
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController(text: widget.initialCurrentPassword ?? '');
    _newPassword.addListener(_onPasswordChanged);
    _confirm.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newPassword.removeListener(_onPasswordChanged);
    _confirm.removeListener(_onPasswordChanged);
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _newPassword.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  String get _strengthLabel {
    if (_newPassword.text.isEmpty) return 'Not entered';
    if (_strength <= 1) return 'Needs improvement';
    if (_strength <= 2) return 'Fair';
    if (_strength == 3) return 'Good';
    return 'Strong';
  }

  String get _initial {
    final name = widget.user.displayName.trim();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  String? _absoluteImageUrl(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = clean.startsWith('/') ? clean : '/$clean';
    return '$baseUrl$path';
  }

  Future<void> _save() async {
    if (_loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
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
    } catch (_) {
      if (mounted) {
        showHeritageMessage(
          context,
          'Unable to change your password. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _SecurityColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _SecurityColors.background,
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: _bottomBar(),
          body: Form(
            key: _formKey,
            child: ScrollConfiguration(
              behavior: const NoOverscrollScrollBehavior(),
              child: ListView(
                padding: EdgeInsets.zero,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _hero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 0, 17, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _accountCard(),
                        const SizedBox(height: 17),
                        if (widget.forced) ...[
                          _temporaryPasswordNote(),
                          const SizedBox(height: 17),
                        ],
                        _passwordCard(),
                        const SizedBox(height: 14),
                        _securityTip(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 291,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 206,
            child: ClipPath(
              clipper: _PasswordCoverWave(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x44754218),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 17,
            right: 17,
            child: Row(
              children: [
                if (!widget.forced) ...[
                  _TopButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 11),
                ] else ...[
                  const _TopButton(icon: Icons.shield_outlined),
                  const SizedBox(width: 11),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeritageLogo(compact: true),
                      SizedBox(height: 3),
                      Text(
                        'ACCOUNT SECURITY',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: _SecurityColors.deepCoffee,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: _SecurityColors.coffee,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'SECURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                          color: _SecurityColors.coffee,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 107,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 102,
                width: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD8BC), Color(0xFFFFF2E9)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x261D130D),
                      blurRadius: 22,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildAvatarImage(102),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _SecurityColors.coffee,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 215,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Text(
                  widget.forced ? 'Secure Your Account' : 'Change Password',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25,
                    color: _SecurityColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.forced
                      ? 'Set a private password before you continue.'
                      : 'Refresh your password to keep your account safe.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _SecurityColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final coverUrl = _absoluteImageUrl(widget.user.coverImageUrl);
    if (coverUrl != null) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _defaultCoverImage(),
      );
    }

    return _defaultCoverImage();
  }

  Widget _defaultCoverImage() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCADDED), Color(0xFFFFD7B0), Color(0xFFAE6030)],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(double size) {
    final profileUrl = _absoluteImageUrl(widget.user.profileImageUrl);
    if (profileUrl != null) {
      return ClipOval(
        child: Image.network(
          profileUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _avatarInitial(),
        ),
      );
    }

    return _avatarInitial();
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        _initial,
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 49,
          fontWeight: FontWeight.w800,
          color: _SecurityColors.coffee,
        ),
      ),
    );
  }

  Widget _accountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: _securityCardDecoration(),
      child: Row(
        children: [
          const _PasswordSoftIcon(icon: Icons.account_circle_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    letterSpacing: 1.1,
                    fontSize: 9.2,
                    fontWeight: FontWeight.w800,
                    color: _SecurityColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.3,
                    fontWeight: FontWeight.w800,
                    color: _SecurityColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _SecurityColors.palePeach,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _SecurityColors.border),
            ),
            child: const Text(
              'Protected',
              style: TextStyle(
                fontSize: 10,
                color: _SecurityColors.coffee,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _temporaryPasswordNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SecurityColors.palePeach,
        border: Border.all(color: const Color(0xFFF0D5C1)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: _SecurityColors.coffee,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'First login: use the temporary password sent to your approved guide email. Your new password will remain private.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: _SecurityColors.deepCoffee,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 19),
      decoration: _securityCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _PasswordSoftIcon(
                icon: Icons.admin_panel_settings_outlined,
                strong: true,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Details',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 19,
                        color: _SecurityColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep your credentials up to date',
                      style: TextStyle(
                        fontSize: 11,
                        color: _SecurityColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: _SecurityColors.border),
          const SizedBox(height: 19),
          _PasswordInput(
            controller: _current,
            title: widget.forced ? 'Temporary Password' : 'Current Password',
            hint: widget.forced
                ? 'Enter your temporary password'
                : 'Enter your current password',
            icon: Icons.lock_outline_rounded,
            visible: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.password],
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your ${widget.forced ? 'temporary' : 'current'} password'
                : null,
          ),
          const SizedBox(height: 18),
          _PasswordInput(
            controller: _newPassword,
            title: 'New Password',
            hint: 'Create a secure new password',
            icon: Icons.key_outlined,
            visible: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) => value == null || value.length < 8
                ? 'Use at least 8 characters'
                : null,
          ),
          const SizedBox(height: 12),
          _passwordStrength(),
          const SizedBox(height: 19),
          _PasswordInput(
            controller: _confirm,
            title: 'Confirm New Password',
            hint: 'Repeat your new password',
            icon: Icons.verified_user_outlined,
            visible: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) => value == null || value.isEmpty
                ? 'Please confirm your password'
                : value != _newPassword.text
                ? 'Passwords do not match'
                : null,
          ),
          if (_confirm.text.isNotEmpty &&
              _confirm.text == _newPassword.text) ...[
            const SizedBox(height: 9),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: _SecurityColors.coffee,
                ),
                SizedBox(width: 5),
                Text(
                  'Passwords match',
                  style: TextStyle(
                    color: _SecurityColors.coffee,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _passwordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Password strength',
              style: TextStyle(
                fontSize: 10.5,
                color: _SecurityColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _strengthLabel,
              style: const TextStyle(
                fontSize: 10.5,
                color: _SecurityColors.coffee,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final active = index < _strength;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active
                      ? _SecurityColors.coffee
                      : _SecurityColors.inactive,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        const Text(
          'Use 8+ characters with upper/lowercase, numbers & symbols.',
          style: TextStyle(
            color: _SecurityColors.muted,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _securityTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SecurityColors.palePeach,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SecurityColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _SecurityColors.coffee,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security tip',
                  style: TextStyle(
                    color: _SecurityColors.deepCoffee,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Choose a unique password you do not use on other accounts. Never share it with anyone.',
                  style: TextStyle(
                    color: _SecurityColors.muted,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 13),
        decoration: const BoxDecoration(
          color: _SecurityColors.white,
          border: Border(top: BorderSide(color: _SecurityColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14614329),
              blurRadius: 17,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!widget.forced) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _SecurityColors.coffee,
                    side: const BorderSide(
                      color: _SecurityColors.border,
                      width: 1.3,
                    ),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _SecurityColors.coffee,
                  disabledBackgroundColor: _SecurityColors.inactive,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_reset_rounded, size: 21),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.forced
                                  ? 'Set My Password'
                                  : 'Update Password',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _securityCardDecoration() => BoxDecoration(
  color: _SecurityColors.white,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: _SecurityColors.border, width: 0.6),
  boxShadow: const [
    BoxShadow(color: Color(0x10614329), blurRadius: 23, offset: Offset(0, 7)),
  ],
);

class _PasswordCoverWave extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(
        size.width * .5,
        size.height - 88,
        0,
        size.height - 20,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: _SecurityColors.coffee),
        ),
      ),
    );
  }
}

class _PasswordSoftIcon extends StatelessWidget {
  const _PasswordSoftIcon({required this.icon, this.strong = false});

  final IconData icon;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: strong ? _SecurityColors.coffee : _SecurityColors.peach,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: strong ? Colors.white : _SecurityColors.coffee,
        size: 23,
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.controller,
    required this.title,
    required this.hint,
    required this.icon,
    required this.visible,
    required this.onToggle,
    required this.validator,
    required this.textInputAction,
    required this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final IconData icon;
  final bool visible;
  final VoidCallback onToggle;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _SecurityColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(
            fontSize: 13.5,
            color: _SecurityColors.ink,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _SecurityColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: _SecurityColors.coffee, size: 20),
            suffixIcon: IconButton(
              onPressed: onToggle,
              tooltip: visible ? 'Hide password' : 'Show password',
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _SecurityColors.muted,
                size: 19,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 15,
            ),
            filled: true,
            fillColor: _SecurityColors.background,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _SecurityColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _SecurityColors.coffee,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _SecurityColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _SecurityColors.danger,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
