import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';

// Uses the same warm color palette and curved Galle Fort cover as the
// redesigned ProfileScreen. No extra Flutter packages are required.
class _EditPalette {
  static const background = Color(0xFFFCF8F3);
  static const surface = Colors.white;
  static const coffee = Color(0xFF893B0B);
  static const coffeeDark = Color(0xFF54220B);
  static const peach = Color(0xFFFFE9DC);
  static const cream = Color(0xFFFFF8F2);
  static const ink = Color(0xFF172035);
  static const muted = Color(0xFF777987);
  static const border = Color(0xFFF1E7DF);
  static const disabled = Color(0xFFC2ACA0);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user.firstName ?? '');
    _lastName = TextEditingController(text: widget.user.lastName ?? '');
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _address = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String get _initial {
    final name = widget.user.displayName.trim();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  Future<void> _save() async {
    if (_loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final updated = await UserService.instance.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      showHeritageMessage(context, 'Profile updated successfully');
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showHeritageMessage(
          context,
          'Could not update your profile. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _EditPalette.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _EditPalette.background,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: _buildBottomActions(),
        body: Form(
          key: _formKey,
          child: ScrollConfiguration(
            behavior: const NoOverscrollScrollBehavior(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.zero,
              children: [
                _buildHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 3, 17, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildEmailCard(),
                      const SizedBox(height: 20),
                      _buildFormSection(),
                      const SizedBox(height: 15),
                      const _PrivacyNote(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + 296,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 207,
            child: ClipPath(
              clipper: _EditCoverWaveClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/heritage_login_banner.webp',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.25, 0),
                    errorBuilder: (_, _, _) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFCADDED),
                            Color(0xFFFFD7B0),
                            Color(0xFFAE6030),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                _HeroIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back to profile',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeritageLogo(compact: true),
                      SizedBox(height: 3),
                      Text(
                        'PROFILE SETTINGS',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: _EditPalette.coffeeDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: _EditPalette.coffee,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'EDIT',
                        style: TextStyle(
                          color: _EditPalette.coffee,
                          fontSize: 10,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 109,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 99,
                width: 99,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDDC5), Color(0xFFFFF0E8)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x281D130D),
                      blurRadius: 22,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 49,
                    fontWeight: FontWeight.w800,
                    color: _EditPalette.coffee,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 215,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const Text(
                  'Edit Your Profile',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: _EditPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${widget.user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _EditPalette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Make your information accurate and up to date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _EditPalette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const _SoftIcon(icon: Icons.alternate_email_rounded, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EMAIL ADDRESS',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: _EditPalette.muted,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _EditPalette.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: _EditPalette.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _EditPalette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.user.emailVerified
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  size: 13,
                  color: _EditPalette.coffee,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.user.emailVerified ? 'Verified' : 'Pending',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _EditPalette.coffee,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(
                icon: Icons.manage_accounts_outlined,
                size: 45,
                strong: true,
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Details',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _EditPalette.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Update your contact information',
                      style: TextStyle(fontSize: 11, color: _EditPalette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _EditPalette.border, height: 1),
          const SizedBox(height: 18),
          _ProfileInput(
            controller: _firstName,
            label: 'First Name',
            hint: 'Enter your first name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            requiredField: true,
          ),
          const SizedBox(height: 16),
          _ProfileInput(
            controller: _lastName,
            label: 'Last Name',
            hint: 'Enter your last name',
            icon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _ProfileInput(
            controller: _phone,
            label: 'Phone Number',
            hint: 'Enter your mobile number',
            icon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            requiredField: true,
          ),
          const SizedBox(height: 16),
          _ProfileInput(
            controller: _address,
            label: 'Address',
            hint: 'City or residential address',
            icon: Icons.location_on_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 13),
        decoration: const BoxDecoration(
          color: _EditPalette.surface,
          border: Border(top: BorderSide(color: _EditPalette.border)),
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
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _EditPalette.coffee,
                  side: const BorderSide(
                    color: _EditPalette.border,
                    width: 1.3,
                  ),
                  minimumSize: const Size(0, 50),
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
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _EditPalette.coffee,
                  disabledBackgroundColor: _EditPalette.disabled,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 19),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Save Changes',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
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

BoxDecoration _cardDecoration() => BoxDecoration(
  color: _EditPalette.surface,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: _EditPalette.border, width: 0.6),
  boxShadow: const [
    BoxShadow(color: Color(0x10614329), blurRadius: 23, offset: Offset(0, 7)),
  ],
);

class _EditCoverWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - 88,
        0,
        size.height - 20,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: _EditPalette.coffee, size: 18),
          ),
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, this.size = 44, this.strong = false});

  final IconData icon;
  final double size;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: strong
            ? const LinearGradient(
                colors: [_EditPalette.coffee, Color(0xFFB56531)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [_EditPalette.peach, _EditPalette.cream],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 22,
        color: strong ? Colors.white : _EditPalette.coffee,
      ),
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _EditPalette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            if (requiredField)
              const Text('  *', style: TextStyle(color: _EditPalette.coffee)),
            if (!requiredField) ...[
              const SizedBox(width: 6),
              const Text(
                'Optional',
                style: TextStyle(color: _EditPalette.muted, fontSize: 10),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _EditPalette.ink,
          ),
          cursorColor: _EditPalette.coffee,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA39A97),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: _EditPalette.coffee, size: 19),
            filled: true,
            fillColor: _EditPalette.cream,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _EditPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _EditPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _EditPalette.coffee,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB52A30)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFB52A30),
                width: 1.5,
              ),
            ),
          ),
          validator: requiredField
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required'
                    : null
              : null,
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EditPalette.peach.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: _EditPalette.coffee,
            size: 19,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your email address is linked to your account and cannot be '
              'changed here. Your changes will appear on your profile after saving.',
              style: TextStyle(
                fontSize: 11,
                color: _EditPalette.coffeeDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
