import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_logo.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../home/home_router.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';

// The warm tones intentionally match Ceylon Heritage's original palette.
// No third-party packages are required.
class _ProfilePalette {
  static const Color background = Color(0xFFFCF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color coffee = Color(0xFF893B0B);
  static const Color coffeeDark = Color(0xFF54220B);
  static const Color peach = Color(0xFFFFE9DC);
  static const Color beige = Color(0xFFFFF2E6);
  static const Color ink = Color(0xFF172035);
  static const Color muted = Color(0xFF777987);
  static const Color border = Color(0xFFF1E9E2);
  static const Color danger = Color(0xFFB52A30);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _reload() async {
    try {
      final updated = await UserService.instance.getProfile();
      if (mounted) setState(() => _user = updated);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showHeritageMessage(
          context,
          'Could not refresh your profile.',
          error: true,
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user)),
    );
    if (result != null && mounted) setState(() => _user = result);
  }

  Future<void> _changePassword() async {
    final result = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(user: _user)),
    );
    if (result != null && mounted) setState(() => _user = result);
  }

  void _openNotifications() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen(user: _user)),
    );
  }

  Future<void> _logout() async {
    try {
      await UserService.instance.logout();
      await GoogleAuthService.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _ProfilePalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your current password to confirm deletion.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final value = controller.text;
              if (value.trim().isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;

    try {
      final message = await UserService.instance.deleteAccount(password);
      if (!mounted) return;
      showHeritageMessage(context, message);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showHeritageMessage(context, 'Account deletion failed.', error: true);
      }
    }
  }

  void _bottomTap(int index) {
    if (index == 2) return;
    if (index == 1) {
      _openNotifications();
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeRouter(user: _user)),
    );
  }

  void _photoInfo() {
    // UserProfile in the supplied project doesn't expose image URLs or
    // upload methods, so this button is intentionally not a fake upload.
    showHeritageMessage(
      context,
      'Connect a profile photo upload API to enable changing your picture.',
    );
  }

  String get _initial {
    final name = _user.displayName.trim();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  String _displayOrNotSet(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? 'Not set' : clean;
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'GUIDE':
        return 'GUIDE';
      case 'ADMIN':
        return 'ADMIN';
      default:
        return 'TOURIST';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _ProfilePalette.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _ProfilePalette.background,
        bottomNavigationBar: _WarmBottomNav(onTap: _bottomTap),
        body: RefreshIndicator(
          color: _ProfilePalette.coffee,
          onRefresh: _reload,
          child: ScrollConfiguration(
            behavior: const NoOverscrollScrollBehavior(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: EdgeInsets.zero,
              children: [
                _buildHero(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPersonalInfo(),
                      const SizedBox(height: 18),
                      _buildSectionHeading(
                        'Account settings',
                        'Manage your profile and security',
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        subtitle: 'Update your name, phone and address.',
                        onTap: _editProfile,
                      ),
                      _ActionCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        subtitle: 'Manage your account password.',
                        onTap: _changePassword,
                      ),
                      _ActionCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'See alerts and account updates.',
                        onTap: _openNotifications,
                      ),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        subtitle: 'Sign out of your account.',
                        onTap: _logout,
                        danger: true,
                      ),
                      _ActionCard(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete Account',
                        subtitle: 'Permanently deactivate your account.',
                        onTap: _deleteAccount,
                        danger: true,
                      ),
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

  Widget _buildHero(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const avatarSize = 104.0;
    return SizedBox(
      height: top + 353,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 237,
            child: ClipPath(
              clipper: _CoverWaveClipper(),
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
                            Color(0xFFCBDEF0),
                            Color(0xFFFFD3A1),
                            Color(0xFF985023),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.landscape_rounded,
                          size: 90,
                          color: Color(0x66FFFFFF),
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
                          Color(0x44FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x44713C1A),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: top + 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      HeritageLogo(compact: true),
                      SizedBox(height: 3),
                      Text(
                        'EXPLORE  •  DISCOVER  •  EXPERIENCE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: _ProfilePalette.coffeeDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderRoundButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: _openNotifications,
                ),
                const SizedBox(width: 7),
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  color: _ProfilePalette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'refresh') _reload();
                    if (value == 'edit') _editProfile();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit profile')),
                    PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                  ],
                  child: const _HeaderRoundIcon(icon: Icons.more_vert_rounded),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 131,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x221D130D),
                          blurRadius: 20,
                          offset: Offset(0, 7),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE3CF), Color(0xFFFFF1E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 51,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: _ProfilePalette.coffee,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: -5,
                    child: Material(
                      color: _ProfilePalette.coffee,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                      elevation: 2,
                      child: InkWell(
                        onTap: _photoInfo,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 241,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  _user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: _ProfilePalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _ProfilePalette.muted,
                  ),
                ),
                const SizedBox(height: 9),
                _VerificationBadge(
                  text:
                      '${_roleLabel(_user.role)}  /  ${_user.emailVerified ? 'VERIFIED' : 'NOT VERIFIED'}',
                  verified: _user.emailVerified,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      decoration: BoxDecoration(
        color: _ProfilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D614329),
            blurRadius: 23,
            offset: Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 17, 15, 15),
            child: Row(
              children: [
                const _SquareIcon(
                  icon: Icons.person_rounded,
                  color: Colors.white,
                  background: _ProfilePalette.coffee,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Personal Information',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: _ProfilePalette.ink,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Account details & contact information',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10.8,
                          color: _ProfilePalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                _VerificationBadge(
                  text: _user.emailVerified ? 'Verified' : 'Pending',
                  verified: _user.emailVerified,
                  compact: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _ProfilePalette.border),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: _user.email,
            verified: _user.emailVerified,
          ),
          _InfoRow(
            icon: Icons.call_outlined,
            label: 'Phone Number',
            value: _displayOrNotSet(_user.phone),
            onTap: _editProfile,
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'First Name',
            value: _displayOrNotSet(_user.firstName),
            onTap: _editProfile,
          ),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Last Name',
            value: _displayOrNotSet(_user.lastName),
            onTap: _editProfile,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _displayOrNotSet(_user.address),
            onTap: _editProfile,
          ),
          _InfoRow(
            icon: Icons.link_rounded,
            label: 'Provider',
            value: _user.provider.toUpperCase(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ProfilePalette.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _ProfilePalette.muted),
          ),
        ],
      ),
    );
  }
}

class _CoverWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 23)
      // The raised center is the same soft curved hero shape as the mockup.
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - 96,
        0,
        size.height - 23,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _CoverWaveClipper oldClipper) => false;
}

class _HeaderRoundIcon extends StatelessWidget {
  const _HeaderRoundIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 37,
      height: 37,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.86),
      ),
      child: Icon(icon, size: 21, color: _ProfilePalette.coffeeDark),
    );
  }
}

class _HeaderRoundButton extends StatelessWidget {
  const _HeaderRoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white.withValues(alpha: 0.86),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 37,
          height: 37,
          child: Icon(icon, size: 21, color: _ProfilePalette.coffeeDark),
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({
    required this.text,
    required this.verified,
    this.compact = false,
  });

  final String text;
  final bool verified;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = verified
        ? _ProfilePalette.coffee
        : _ProfilePalette.muted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFF9EADC) : const Color(0xFFF1EEEA),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.schedule_rounded,
            size: compact ? 14 : 16,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10.5 : 11,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({
    required this.icon,
    this.color = _ProfilePalette.coffee,
    this.background = _ProfilePalette.beige,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: color),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.verified = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool verified;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final empty = value == 'Not set';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _SquareIcon(icon: icon, size: 41),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                            color: _ProfilePalette.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.4,
                            fontWeight: empty
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: empty
                                ? _ProfilePalette.muted
                                : _ProfilePalette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  if (verified)
                    const _SmallPill(text: 'Verified')
                  else if (empty && onTap != null)
                    const _SmallPill(text: 'Add', outline: true),
                  if (onTap != null) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: _ProfilePalette.muted,
                    ),
                  ],
                ],
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(left: 68, right: 15),
                child: Divider(height: 1, color: _ProfilePalette.border),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.text, this.outline = false});

  final String text;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: outline ? Colors.white : _ProfilePalette.beige,
        border: Border.all(
          color: outline ? _ProfilePalette.coffee : Colors.transparent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ProfilePalette.coffee,
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? _ProfilePalette.danger : _ProfilePalette.coffee;
    final fill = danger ? const Color(0xFFFFE5E5) : _ProfilePalette.peach;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _ProfilePalette.surface,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09614329),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  _SquareIcon(
                    icon: icon,
                    background: fill,
                    color: foreground,
                    size: 46,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: danger
                                ? _ProfilePalette.coffeeDark
                                : _ProfilePalette.ink,
                            fontSize: 16.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.8,
                            height: 1.3,
                            color: _ProfilePalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _ProfilePalette.beige,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 21,
                      color: foreground,
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
}

// Uses the existing project's 3 routes. Only the visual appearance changes.
class _WarmBottomNav extends StatelessWidget {
  const _WarmBottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ProfilePalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
          child: Row(
            children: [
              _NavItem(
                index: 0,
                icon: Icons.space_dashboard_outlined,
                title: 'Dashboard',
                selected: false,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                icon: Icons.notifications_none_rounded,
                title: 'Alerts',
                selected: false,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                icon: Icons.person_rounded,
                title: 'Profile',
                selected: true,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String title;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 33,
                width: 67,
                decoration: BoxDecoration(
                  color: selected ? _ProfilePalette.peach : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? _ProfilePalette.coffee
                      : _ProfilePalette.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? _ProfilePalette.coffee
                      : _ProfilePalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
