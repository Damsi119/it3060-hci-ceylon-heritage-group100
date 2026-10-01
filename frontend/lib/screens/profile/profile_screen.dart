import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../home/home_router.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';

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
    final updated = await UserService.instance.getProfile();
    if (mounted) setState(() => _user = updated);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Current password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final message = await UserService.instance.deleteAccount(controller.text);
      if (!mounted) return;
      showHeritageMessage(context, message);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    }
  }

  void _bottomTap(int index) {
    if (index == 2) return;
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NotificationsScreen(user: _user)),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeRouter(user: _user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _user.displayName.isEmpty
        ? 'U'
        : _user.displayName[0].toUpperCase();

    return Scaffold(
      appBar: HeritageAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HeritageBottomNav(
        currentIndex: 2,
        onTap: _bottomTap,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _user.displayName,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Center(
              child: Text(
                '@${_user.username}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: HeritageBadge(
                label: '${_roleLabel(_user.role)} / ${_verifiedLabel()}',
                icon: Icons.verified_rounded,
                color: _user.emailVerified
                    ? AppColors.green
                    : AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            HeritageCard(
              color: AppColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Email', value: _user.email),
                  _DetailRow(label: 'Phone', value: _user.phone ?? 'Not set'),
                  _DetailRow(
                    label: 'First name',
                    value: _user.firstName ?? 'Not set',
                  ),
                  _DetailRow(
                    label: 'Last name',
                    value: _user.lastName ?? 'Not set',
                  ),
                  _DetailRow(
                    label: 'Address',
                    value: _user.address ?? 'Not set',
                  ),
                  _DetailRow(
                    label: 'Provider',
                    value: _user.provider,
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileTile(
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              subtitle: 'Update name, phone and address.',
              onTap: _editProfile,
            ),
            _ProfileTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change password',
              subtitle: 'Set a new account password.',
              onTap: _changePassword,
            ),
            _ProfileTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Open account notifications.',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(user: _user),
                ),
              ),
            ),
            _ProfileTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Clear this session.',
              danger: true,
              onTap: _logout,
            ),
            _ProfileTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              subtitle: 'Soft delete your account after password confirmation.',
              danger: true,
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  String _verifiedLabel() => _user.emailVerified ? 'Verified' : 'Not verified';

  String _roleLabel(String role) {
    switch (role) {
      case 'GUIDE':
        return 'Guide';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Tourist';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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
    final color = danger ? AppColors.danger : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HeritageCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFFDECEC) : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 19, color: color),
          ],
        ),
      ),
    );
  }
}
