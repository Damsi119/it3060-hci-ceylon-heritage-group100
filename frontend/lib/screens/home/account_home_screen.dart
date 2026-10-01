import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_card.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class AccountHomeScreen extends StatelessWidget {
  const AccountHomeScreen({super.key, required this.user});

  final UserProfile user;

  Future<void> _logout(BuildContext context) async {
    try {
      await UserService.instance.logout();
      await GoogleAuthService.instance.signOut();
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _tap(BuildContext context, int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NotificationsScreen(user: user)),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isEmpty
        ? 'U'
        : user.displayName[0].toUpperCase();

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
        currentIndex: 0,
        onTap: (index) => _tap(context, index),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          HeritageBadge(
            label: _roleLabel(user.role),
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome, ${user.displayName}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your account, profile, password, and notifications.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          HeritageCard(
            color: AppColors.surfaceSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Username', value: user.username),
                _InfoRow(label: 'Email', value: user.email),
                _InfoRow(label: 'Phone', value: user.phone ?? 'Not set'),
                _InfoRow(label: 'Role', value: user.role),
                _InfoRow(label: 'Provider', value: user.provider, last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ActionTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'View and update your account details.',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
            ),
          ),
          _ActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(user: user),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Read and manage account notifications.',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(user: user),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'End this session on the device.',
            danger: true,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'GUIDE':
        return 'Guide Account';
      case 'ADMIN':
        return 'Admin Account';
      default:
        return 'Tourist Account';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
      padding: const EdgeInsets.only(bottom: 9),
      child: HeritageCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFFDECEC) : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
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
                    style: const TextStyle(
                      fontSize: 9.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
