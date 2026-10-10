import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/notification_badge.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../community/community_feed_screen.dart';
import '../explore/historical_place_details_screen.dart';
import '../explore/historical_places_screen.dart';
import '../navigation/member4_navigation_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class GuideHomeScreen extends StatefulWidget {
  const GuideHomeScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<GuideHomeScreen> createState() => _GuideHomeScreenState();
}

class _GuideHomeScreenState extends State<GuideHomeScreen> {
  static const _primary = Color(0xFF8D4A24);
  static const _accent = Color(0xFFC96F4A);
  static const _blue = Color(0xFF416DAB);
  static const _ink = Color(0xFF2C1E18);
  static const _muted = Color(0xFF6F625D);

  Route<dynamic>? _homeRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeRoute = ModalRoute.of(context);
  }

  String get _initial {
    final name = widget.user.displayName.trim();
    return name.isEmpty ? 'G' : name[0].toUpperCase();
  }

  String get _phoneLabel {
    final phone = widget.user.phone?.trim();
    return phone == null || phone.isEmpty ? 'Phone not set' : phone;
  }

  void _returnHome() {
    final route = _homeRoute;
    if (route == null || !route.isActive) {
      return;
    }

    Navigator.of(context).popUntil((candidate) => identical(candidate, route));
  }

  void _navigateFromChild(VoidCallback action) {
    _returnHome();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  void _tapBottomNav(int index) {
    if (index == 0) {
      return;
    }
    if (index == 1) {
      _notifications(replace: true);
      return;
    }
    _profile(replace: true);
  }

  void _openExplore({String keyword = ''}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoricalPlacesScreen(
          user: widget.user,
          initialKeyword: keyword,
          onHome: _returnHome,
          onCommunity: () => _navigateFromChild(_openCommunity),
          onPlaceSelected: _openPlaceDetails,
        ),
      ),
    );
  }

  void _openPlaceDetails(HistoricalPlace place) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoricalPlaceDetailsScreen(
          placeId: place.id,
          initialPlace: place.toJson(),
        ),
      ),
    );
  }

  void _openCommunity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityFeedScreen(
          user: widget.user,
          onHome: _returnHome,
          onExplore: () => _navigateFromChild(_openExplore),
          onProfile: () => _navigateFromChild(_profile),
          onNotifications: () => _navigateFromChild(_notifications),
        ),
      ),
    );
  }

  void _openFieldNavigation() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            Member4NavigationScreen(storageScope: widget.user.id.toString()),
      ),
    );
  }

  void _changePassword() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChangePasswordScreen(user: widget.user),
      ),
    );
  }

  void _notifications({bool replace = false}) {
    final route = MaterialPageRoute<void>(
      builder: (_) => NotificationsScreen(user: widget.user),
    );
    if (replace) {
      Navigator.of(context).pushReplacement<void, void>(route);
      return;
    }
    Navigator.of(context).push<void>(route);
  }

  void _profile({bool replace = false}) {
    final route = MaterialPageRoute<void>(
      builder: (_) => ProfileScreen(user: widget.user),
    );
    if (replace) {
      Navigator.of(context).pushReplacement<void, void>(route);
      return;
    }
    Navigator.of(context).push<void>(route);
  }

  Future<void> _logout() async {
    try {
      await UserService.instance.logout();
      await GoogleAuthService.instance.signOut();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HeritageAppBar(
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _notifications,
            icon: const NotificationBadge(
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _profile,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.greenSoft,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HeritageBottomNav(
        currentIndex: 0,
        onTap: _tapBottomNav,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _hero(),
          const SizedBox(height: 16),
          _statusRow(),
          const SizedBox(height: 16),
          _accountPanel(),
          const SizedBox(height: 20),
          _sectionTitle('Guide Toolkit'),
          const SizedBox(height: 12),
          _actionGrid(),
          const SizedBox(height: 20),
          _sectionTitle('Today Focus'),
          const SizedBox(height: 12),
          _focusList(),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: AssetImage('assets/images/guide_request_banner.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F301A0D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .72),
                    const Color(0xFF4C2616).withValues(alpha: .52),
                    Colors.black.withValues(alpha: .08),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: -16,
            bottom: -26,
            child: Icon(
              Icons.explore_rounded,
              size: 158,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeritageBadge(
                  label: 'Verified Guide',
                  icon: Icons.workspace_premium_outlined,
                  color: Colors.white,
                  background: Color(0x2FFFFFFF),
                ),
                const Spacer(),
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerif(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _openExplore,
                  icon: const Icon(Icons.account_balance_rounded, size: 18),
                  label: const Text(
                    'Explore Places',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Row(
      children: [
        Expanded(
          child: _GuideMetric(
            label: 'Role',
            value: 'GUIDE',
            icon: Icons.badge_outlined,
            color: _primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _GuideMetric(
            label: 'Email',
            value: widget.user.emailVerified ? 'VERIFIED' : 'PENDING',
            icon: Icons.mark_email_read_outlined,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _GuideMetric(
            label: 'Login',
            value: widget.user.provider,
            icon: Icons.shield_outlined,
            color: _blue,
          ),
        ),
      ],
    );
  }

  Widget _accountPanel() {
    return HeritageCard(
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tour_outlined,
              color: AppColors.green,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phoneLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _profile,
            icon: const Icon(Icons.edit_outlined, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSerif(
        fontSize: 20,
        color: _ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _actionGrid() {
    final actions = [
      _GuideAction(
        title: 'Heritage Places',
        subtitle: 'Browse landmarks',
        icon: Icons.account_balance_rounded,
        color: _blue,
        onTap: _openExplore,
      ),
      _GuideAction(
        title: 'Community',
        subtitle: 'Answer visitors',
        icon: Icons.groups_outlined,
        color: AppColors.green,
        onTap: _openCommunity,
      ),
      _GuideAction(
        title: 'Field Route',
        subtitle: 'Navigate checkpoints',
        icon: Icons.route_outlined,
        color: const Color(0xFF9B5C9A),
        onTap: _openFieldNavigation,
      ),
      _GuideAction(
        title: 'Notifications',
        subtitle: 'Review guide alerts',
        icon: Icons.notifications_active_outlined,
        color: _accent,
        onTap: _notifications,
      ),
      _GuideAction(
        title: 'Profile',
        subtitle: 'Update guide details',
        icon: Icons.person_outline_rounded,
        color: _primary,
        onTap: _profile,
      ),
      _GuideAction(
        title: 'Password',
        subtitle: 'Secure account',
        icon: Icons.lock_outline_rounded,
        color: AppColors.warning,
        onTap: _changePassword,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) => _GuideActionCard(action: actions[index]),
    );
  }

  Widget _focusList() {
    return Column(
      children: [
        _FocusTile(
          icon: Icons.fact_check_outlined,
          title: 'Keep guide details current',
          subtitle: 'Review your profile, phone number and service details.',
          color: AppColors.green,
          onTap: _profile,
        ),
        const SizedBox(height: 9),
        _FocusTile(
          icon: Icons.travel_explore_outlined,
          title: 'Prepare field navigation',
          subtitle: 'Open saved journeys before meeting visitors.',
          color: _blue,
        ),
        const SizedBox(height: 9),
        _FocusTile(
          icon: Icons.notifications_active_outlined,
          title: 'Check guide alerts',
          subtitle: 'Read account and community updates from visitors.',
          color: _accent,
          onTap: _notifications,
        ),
        const SizedBox(height: 9),
        _FocusTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'End this guide session on the device.',
          color: AppColors.danger,
          onTap: _logout,
        ),
      ],
    );
  }
}

class _GuideMetric extends StatelessWidget {
  const _GuideMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HeritageCard(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideAction {
  const _GuideAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _GuideActionCard extends StatelessWidget {
  const _GuideActionCard({required this.action});

  final _GuideAction action;

  @override
  Widget build(BuildContext context) {
    return HeritageCard(
      onTap: action.onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: action.color, size: 23),
          ),
          const Spacer(),
          Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _GuideHomeScreenState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            action.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _GuideHomeScreenState._muted,
              fontSize: 9.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HeritageCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _GuideHomeScreenState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _GuideHomeScreenState._muted,
                    fontSize: 9.7,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ],
      ),
    );
  }
}
