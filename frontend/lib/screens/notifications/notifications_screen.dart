import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification_item.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_message.dart';
import '../home/home_router.dart';
import '../profile/profile_screen.dart';

// Uses the existing app's services and navigation. No extra dependencies,
// images or backend changes are required.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;
  bool _actionRunning = false;
  String _filter = 'Unread';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final items = await NotificationService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
      showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.read || _actionRunning) return;
    setState(() => _actionRunning = true);
    try {
      await NotificationService.instance.markRead(item.id);
      await _load(showLoader: false);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }

  Future<void> _markAll() async {
    if (_actionRunning) return;
    setState(() => _actionRunning = true);
    try {
      await NotificationService.instance.markAllRead();
      await _load(showLoader: false);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }

  Future<void> _delete(NotificationItem item) async {
    if (_actionRunning) return;
    setState(() => _actionRunning = true);
    try {
      await NotificationService.instance.delete(item.id);
      await _load(showLoader: false);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }

  void _bottomTap(int index) {
    if (index == 1) return;
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeRouter(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((item) => !item.read).length;
    final visible = _filter == 'Unread'
        ? _items.where((item) => !item.read).toList()
        : _items;

    return Scaffold(
      backgroundColor: _NoticeColors.background,
      appBar: HeritageAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _NoticeColors.avatar,
              child: Text(
                widget.user.displayName.isEmpty
                    ? 'U'
                    : widget.user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: _NoticeColors.brown,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HeritageBottomNav(
        currentIndex: 1,
        onTap: _bottomTap,
      ),
      body: RefreshIndicator(
        color: _NoticeColors.brown,
        onRefresh: () => _load(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _NotificationHero(
              unreadCount: unreadCount,
              totalCount: _items.length,
              onMarkAll: unreadCount == 0 || _actionRunning ? null : _markAll,
            ),
            const SizedBox(height: 54),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent activity',
                      style: TextStyle(
                        color: _NoticeColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (!_loading)
                    Text(
                      '${_items.length} total',
                      style: const TextStyle(
                        color: _NoticeColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _NoticeFilters(
                selected: _filter,
                unreadCount: unreadCount,
                allCount: _items.length,
                onSelected: (value) => setState(() => _filter = value),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _NoticeColors.brown,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_loadError != null && _items.isEmpty)
              _NoticeEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load updates',
                subtitle: 'Check your connection and try again.',
                buttonLabel: 'Try again',
                onAction: () => _load(),
              )
            else if (visible.isEmpty)
                _NoticeEmptyState(
                  icon: _filter == 'Unread'
                      ? Icons.mark_email_read_outlined
                      : Icons.notifications_none_rounded,
                  title: _filter == 'Unread'
                      ? 'You are all caught up!'
                      : 'No notifications yet',
                  subtitle: _filter == 'Unread'
                      ? 'There are no unread updates right now. Enjoy your journey!'
                      : 'Important updates about your journeys will appear here.',
                  buttonLabel: _filter == 'Unread' ? 'View all updates' : null,
                  onAction: _filter == 'Unread'
                      ? () => setState(() => _filter = 'All')
                      : null,
                )
              else
                ...visible.map(
                      (item) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ModernNotificationCard(
                      item: item,
                      onTap: () => _markRead(item),
                      onDelete: () => _delete(item),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NoticeColors {
  static const background = Color(0xFFFCF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF241C1A);
  static const muted = Color(0xFF897B73);
  static const brown = Color(0xFF933F15);
  static const darkBrown = Color(0xFF6D300E);
  static const peach = Color(0xFFFCE9DA);
  static const avatar = Color(0xFFFBE2D0);
  static const line = Color(0xFFF1E8E0);
  static const danger = Color(0xFFAF3436);
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({
    required this.unreadCount,
    required this.totalCount,
    required this.onMarkAll,
  });

  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: _NoticeWaveClipper(),
            child: Container(
              height: 195,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF4EA),
                    Color(0xFFF8D7BE),
                    Color(0xFFEDB98F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -42,
                    top: -65,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x66FFFFFF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 3,
                    top: 2,
                    child: Icon(
                      Icons.account_balance_outlined,
                      size: 125,
                      color: _NoticeColors.brown.withValues(alpha: 0.09),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xDAFFFFFF),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                size: 16,
                                color: _NoticeColors.brown,
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              'CEYLON HERITAGE',
                              style: TextStyle(
                                color: _NoticeColors.darkBrown,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19),
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: _NoticeColors.ink,
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Stay updated with every journey.',
                          style: TextStyle(
                            color: _NoticeColors.darkBrown,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 19,
            right: 19,
            top: 151,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: _NoticeColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140E0906),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: _NoticeColors.peach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: _NoticeColors.brown,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR INBOX',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.15,
                            fontWeight: FontWeight.w800,
                            color: _NoticeColors.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unreadCount == 0
                              ? 'All caught up'
                              : '$unreadCount unread ${unreadCount == 1 ? 'update' : 'updates'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _NoticeColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$totalCount total notifications',
                          style: const TextStyle(
                            color: _NoticeColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: onMarkAll,
                      style: TextButton.styleFrom(
                        foregroundColor: _NoticeColors.brown,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 10,
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
    );
  }
}

class _NoticeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 18)
      ..cubicTo(
        size.width * 0.31,
        size.height + 8,
        size.width * 0.67,
        size.height - 46,
        size.width,
        size.height - 21,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NoticeFilters extends StatelessWidget {
  const _NoticeFilters({
    required this.selected,
    required this.unreadCount,
    required this.allCount,
    required this.onSelected,
  });

  final String selected;
  final int unreadCount;
  final int allCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _NoticeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _NoticeColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterOption('Unread', unreadCount, selected == 'Unread'),
          ),
          Expanded(child: _filterOption('All', allCount, selected == 'All')),
        ],
      ),
    );
  }

  Widget _filterOption(String label, int count, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => onSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 9),
        decoration: BoxDecoration(
          color: isSelected ? _NoticeColors.brown : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _NoticeColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0x40FFFFFF)
                    : _NoticeColors.peach,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : _NoticeColors.brown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernNotificationCard extends StatelessWidget {
  const _ModernNotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = _NoticeCategory.fromItem(item);
    final formattedDate = DateFormat("d MMM '•' h:mm a")
        .format(item.createdAt.toLocal());

    return Material(
      color: item.read ? _NoticeColors.surface : const Color(0xFFFFFDFC),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: item.read ? null : onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 15, 9, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: item.read
                  ? _NoticeColors.line
                  : const Color(0xFFF1D4C0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 17,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(visual.icon, color: visual.foreground, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visual.label,
                          style: const TextStyle(
                            color: _NoticeColors.brown,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: _NoticeColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!item.read)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _NoticeColors.brown,
                      ),
                    ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    tooltip: 'Notification options',
                    color: _NoticeColors.surface,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 23,
                      color: _NoticeColors.muted,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: _NoticeColors.danger, size: 19),
                            SizedBox(width: 9),
                            Text('Delete notification'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                item.title,
                style: const TextStyle(
                  color: _NoticeColors.ink,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                style: const TextStyle(
                  color: _NoticeColors.muted,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 13),
              Container(height: 1, color: _NoticeColors.line),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    item.read
                        ? Icons.check_circle_outline_rounded
                        : Icons.circle_notifications_outlined,
                    color: item.read
                        ? _NoticeColors.muted
                        : _NoticeColors.brown,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    item.read ? 'Read' : 'Unread · Tap to mark as read',
                    style: TextStyle(
                      color: item.read
                          ? _NoticeColors.muted
                          : _NoticeColors.brown,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCategory {
  const _NoticeCategory(this.label, this.icon, this.background, this.foreground);

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  factory _NoticeCategory.fromItem(NotificationItem item) {
    final text = '${item.title} ${item.message}'.toLowerCase();

    if (text.contains('booking') || text.contains('appointment') ||
        text.contains('reservation')) {
      return const _NoticeCategory('BOOKING', Icons.event_available_outlined,
          Color(0xFFFFE7D7), Color(0xFF98461C));
    }
    if (text.contains('buddy') || text.contains('match') ||
        text.contains('chat') || text.contains('message')) {
      return const _NoticeCategory('TRAVEL COMMUNITY', Icons.groups_outlined,
          Color(0xFFF7E8D9), Color(0xFF875021));
    }
    if (text.contains('guide') || text.contains('tour') ||
        text.contains('destination')) {
      return const _NoticeCategory('TRAVEL UPDATE', Icons.map_outlined,
          Color(0xFFFFEDD9), Color(0xFF9C5C21));
    }
    if (text.contains('password') || text.contains('security') ||
        text.contains('account') || text.contains('login')) {
      return const _NoticeCategory('ACCOUNT', Icons.shield_outlined,
          Color(0xFFFBE6E4), Color(0xFFA2423A));
    }
    return const _NoticeCategory('NOTIFICATION', Icons.notifications_none_rounded,
        _NoticeColors.peach, _NoticeColors.brown);
  }
}

class _NoticeEmptyState extends StatelessWidget {
  const _NoticeEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
        decoration: BoxDecoration(
          color: _NoticeColors.surface,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: _NoticeColors.line),
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _NoticeColors.peach,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _NoticeColors.brown, size: 36),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _NoticeColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _NoticeColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _NoticeColors.brown,
                  side: const BorderSide(color: _NoticeColors.brown),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
