import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/notification_badge.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_guide_requests_screen.dart';
import 'admin_user_management_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeritageAppBar(
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(user: user),
              ),
            ),
            icon: const NotificationBadge(
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          const HeritageBadge(
            label: 'Archive Administrator',
            icon: Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'Ceylon Heritage Registry',
            style: GoogleFonts.notoSerif(
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Review guide requests, manage registered users and keep the heritage explorer registry trusted.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: const DecorationImage(
                image: AssetImage('assets/images/polonnaruwa_banner.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: .66),
                          const Color(0xFF5A2D1F).withValues(alpha: .46),
                          Colors.black.withValues(alpha: .16),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: -20,
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeritageBadge(
                        label: 'Registry Control',
                        color: Colors.white,
                        background: Color(0x2FFFFFFF),
                      ),
                      Spacer(),
                      Text(
                        'Admin Field Desk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Accounts - approvals - notifications',
                        style: TextStyle(
                          color: Color(0xFFF3DED3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminTile(
            icon: Icons.person_search_outlined,
            title: 'Guide Requests',
            subtitle:
                'Review pending guide applications and approve or reject them.',
            accent: AppColors.greenSoft,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminGuideRequestsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AdminTile(
            icon: Icons.group_outlined,
            title: 'User Management',
            subtitle:
                'View Tourist, Guide and Admin accounts; enable, disable or remove users.',
            accent: AppColors.surfaceWarm,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminUserManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AdminTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notification Center',
            subtitle: 'Review account and guide approval notifications.',
            accent: AppColors.greenSoft,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(user: user),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const HeritageCard(
            color: AppColors.surfaceSoft,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.greenSoft,
                  child: Icon(Icons.shield_outlined, color: AppColors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guide accounts are created only after approval. Temporary passwords are generated automatically and sent by email.',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
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

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HeritageCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.7,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
