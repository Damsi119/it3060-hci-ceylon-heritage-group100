import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_config.dart';
import '../../models/notification_item.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/notification_center.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_message.dart';
import '../../widgets/no_overscroll_scroll_behavior.dart';
import '../home/home_router.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationCenter _center = NotificationCenter.instance;
  List<NotificationItem> _items = [];

  bool _loading = true;
  bool _actionRunning = false;

  String _filter = 'Unread';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _items = _center.items;
    _loadError = _center.error;
    _center.addListener(_syncFromCenter);
    _center.start();
    _load();
  }

  @override
  void dispose() {
    _center.removeListener(_syncFromCenter);
    super.dispose();
  }

  void _syncFromCenter() {
    if (!mounted) return;

    setState(() {
      _items = _center.items;
      _loadError = _center.error;
      _loading = _center.loading && _center.items.isEmpty;
    });
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }

    await _center.refresh(showLoader: showLoader);

    if (!mounted) return;

    setState(() {
      _items = _center.items;
      _loadError = _center.error;
      _loading = false;
    });

    final error = _center.error;
    if (showLoader && error != null) {
      showHeritageMessage(context, error, error: true);
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.read || _actionRunning) return;

    setState(() => _actionRunning = true);

    try {
      await _center.markRead(item.id);
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
      await _center.markAllRead();
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
      await _center.delete(item.id);
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((item) => !item.read).length;
    final visibleItems = _filter == 'Unread'
        ? _items.where((item) => !item.read).toList()
        : _items;

    return Scaffold(
      backgroundColor: _NoticeColors.background,
      appBar: HeritageAppBar(
        backgroundColor: _NoticeColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _UserAvatar(
              user: widget.user,
              imageUrl: _absoluteImageUrl(widget.user.profileImageUrl),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HeritageBottomNav(
        currentIndex: 1,
        onTap: _bottomTap,
      ),
      body: RefreshIndicator(
        color: _NoticeColors.primary,
        onRefresh: () => _load(showLoader: false),
        child: ScrollConfiguration(
          behavior: const NoOverscrollScrollBehavior(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _NotificationHero(
                unreadCount: unreadCount,
                totalCount: _items.length,
                actionRunning: _actionRunning,
                onMarkAll: unreadCount == 0 || _actionRunning ? null : _markAll,
              ),
              const SizedBox(height: 16),
              _NoticeFilters(
                selected: _filter,
                unreadCount: unreadCount,
                allCount: _items.length,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: _filter == 'Unread'
                    ? 'Unread Updates'
                    : 'Notification History',
                count: visibleItems.length,
              ),
              const SizedBox(height: 12),
              if (_loading)
                const _LoadingState()
              else if (_loadError != null && _items.isEmpty)
                _NoticeEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load updates',
                  subtitle: 'Check your connection and try again.',
                  buttonLabel: 'Try again',
                  onAction: () => _load(),
                )
              else if (visibleItems.isEmpty)
                _NoticeEmptyState(
                  icon: _filter == 'Unread'
                      ? Icons.mark_email_read_outlined
                      : Icons.notifications_none_rounded,
                  title: _filter == 'Unread'
                      ? 'Everything is read'
                      : 'No notifications yet',
                  subtitle: _filter == 'Unread'
                      ? 'There are no unread updates right now.'
                      : 'Journey updates, account alerts, and travel notices will appear here.',
                  buttonLabel: _filter == 'Unread' ? 'View all' : null,
                  onAction: _filter == 'Unread'
                      ? () => setState(() => _filter = 'All')
                      : null,
                )
              else
                ...visibleItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      item: item,
                      actionRunning: _actionRunning,
                      onTap: () => _markRead(item),
                      onDelete: () => _delete(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeColors {
  static const background = Color(0xFFFCF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFF7EF);
  static const primary = Color(0xFF934214);
  static const primaryDark = Color(0xFF5E2609);
  static const ink = Color(0xFF241C1A);
  static const muted = Color(0xFF7A6D66);
  static const softText = Color(0xFF9A8A81);
  static const line = Color(0xFFEFE4DC);
  static const peach = Color(0xFFFBE4D4);
  static const green = Color(0xFF476B54);
  static const greenSoft = Color(0xFFE4F1E8);
  static const danger = Color(0xFFB23A35);
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({
    required this.unreadCount,
    required this.totalCount,
    required this.actionRunning,
    required this.onMarkAll,
  });

  final int unreadCount;
  final int totalCount;
  final bool actionRunning;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = (width * 0.38).clamp(138.0, 172.0).toDouble();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/historia_notifications_cover.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: _NoticeColors.primaryDark,
                    child: Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white70,
                        size: 44,
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
                        Color(0x0A000000),
                        Color(0x4D000000),
                        Color(0xB0000000),
                      ],
                      stops: [0.0, 0.54, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            'CEYLON HERITAGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        unreadCount == 0
                            ? 'You are up to date.'
                            : '$unreadCount unread update${unreadCount == 1 ? '' : 's'} waiting.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF8EFE8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _NoticeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _NoticeColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            child: Row(
              children: [
                _StatTile(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Unread',
                  value: '$unreadCount',
                  highlight: true,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total',
                  value: '$totalCount',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Mark all read',
                  onPressed: onMarkAll,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    backgroundColor: unreadCount == 0
                        ? const Color(0xFFF1ECE7)
                        : _NoticeColors.peach,
                    foregroundColor: _NoticeColors.primary,
                    disabledForegroundColor: _NoticeColors.softText,
                  ),
                  icon: actionRunning
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _NoticeColors.primary,
                          ),
                        )
                      : const Icon(Icons.done_all_rounded, size: 19),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: highlight ? _NoticeColors.peach : _NoticeColors.greenSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: highlight ? _NoticeColors.primary : _NoticeColors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NoticeColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NoticeColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _NoticeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NoticeColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _FilterButton(
                label: 'Unread',
                count: unreadCount,
                selected: selected == 'Unread',
                onTap: () => onSelected('Unread'),
              ),
            ),
            Expanded(
              child: _FilterButton(
                label: 'All',
                count: allCount,
                selected: selected == 'All',
                onTap: () => onSelected('All'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
          decoration: BoxDecoration(
            color: selected ? _NoticeColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _NoticeColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : _NoticeColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : _NoticeColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _NoticeColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$count item${count == 1 ? '' : 's'}',
          style: const TextStyle(
            color: _NoticeColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.actionRunning,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final bool actionRunning;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = _NoticeCategory.fromItem(item);
    final formattedDate = DateFormat(
      'd MMM yyyy, h:mm a',
    ).format(item.createdAt.toLocal());

    return Material(
      color: item.read ? _NoticeColors.surface : const Color(0xFFFFFCF9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.read || actionRunning ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.read ? _NoticeColors.line : const Color(0xFFEACBB8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 9, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: visual.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.foreground,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  visual.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _NoticeColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (!item.read) ...[
                                const SizedBox(width: 7),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: _NoticeColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _NoticeColors.softText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      tooltip: 'Notification options',
                      enabled: !actionRunning,
                      color: _NoticeColors.surface,
                      surfaceTintColor: Colors.transparent,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 22,
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
                              Icon(
                                Icons.delete_outline_rounded,
                                color: _NoticeColors.danger,
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Text('Delete notification'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _NoticeColors.ink,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: _NoticeColors.muted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: _NoticeColors.line),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      item.read
                          ? Icons.check_circle_outline_rounded
                          : Icons.radio_button_checked_rounded,
                      color: item.read
                          ? _NoticeColors.green
                          : _NoticeColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.read ? 'Read' : 'Unread - tap to mark as read',
                        style: TextStyle(
                          color: item.read
                              ? _NoticeColors.green
                              : _NoticeColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCategory {
  const _NoticeCategory(
    this.label,
    this.icon,
    this.background,
    this.foreground,
  );

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  factory _NoticeCategory.fromItem(NotificationItem item) {
    final text = '${item.title} ${item.message}'.toLowerCase();

    if (text.contains('booking') ||
        text.contains('appointment') ||
        text.contains('reservation')) {
      return const _NoticeCategory(
        'BOOKING',
        Icons.event_available_outlined,
        Color(0xFFFFE7D7),
        Color(0xFF98461C),
      );
    }

    if (text.contains('guide') ||
        text.contains('tour') ||
        text.contains('destination') ||
        text.contains('journey')) {
      return const _NoticeCategory(
        'TRAVEL UPDATE',
        Icons.map_outlined,
        Color(0xFFFFEDD9),
        Color(0xFF9C5C21),
      );
    }

    if (text.contains('password') ||
        text.contains('security') ||
        text.contains('account') ||
        text.contains('login')) {
      return const _NoticeCategory(
        'ACCOUNT',
        Icons.shield_outlined,
        Color(0xFFFBE6E4),
        Color(0xFFA2423A),
      );
    }

    if (text.contains('community') ||
        text.contains('post') ||
        text.contains('comment') ||
        text.contains('message')) {
      return const _NoticeCategory(
        'COMMUNITY',
        Icons.groups_outlined,
        Color(0xFFE8F0E7),
        Color(0xFF476B54),
      );
    }

    return const _NoticeCategory(
      'NOTIFICATION',
      Icons.notifications_none_rounded,
      _NoticeColors.peach,
      _NoticeColors.primary,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 58, bottom: 70),
      child: Center(
        child: CircularProgressIndicator(
          color: _NoticeColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: BoxDecoration(
        color: _NoticeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _NoticeColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: _NoticeColors.peach,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _NoticeColors.primary, size: 29),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _NoticeColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
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
                foregroundColor: _NoticeColors.primary,
                side: const BorderSide(color: _NoticeColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.imageUrl});

  final UserProfile user;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: _NoticeColors.peach,
      child: ClipOval(
        child: imageUrl == null
            ? _initial()
            : Image.network(
                imageUrl!,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initial(),
              ),
      ),
    );
  }

  Widget _initial() {
    final name = user.displayName.trim();
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: _NoticeColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
