import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_item.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_bottom_nav.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';
import '../home/home_router.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;
  String _filter = 'Unread';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await NotificationService.instance.getNotifications();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.read) return;
    try {
      await NotificationService.instance.markRead(item.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    }
  }

  Future<void> _markAll() async {
    try {
      await NotificationService.instance.markAllRead();
      await _load();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    }
  }

  Future<void> _delete(NotificationItem item) async {
    try {
      await NotificationService.instance.delete(item.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
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
    final visible = _filter == 'Unread'
        ? _items.where((item) => !item.read).toList()
        : _items;
    final unreadCount = _items.where((item) => !item.read).length;

    return Scaffold(
      appBar: HeritageAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                widget.user.displayName.isEmpty
                    ? 'U'
                    : widget.user.displayName[0].toUpperCase(),
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
        currentIndex: 1,
        onTap: _bottomTap,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Row(
              children: [
                ChoiceChip(
                  selected: _filter == 'Unread',
                  label: Text('Unread $unreadCount'),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _filter == 'Unread' ? Colors.white : AppColors.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() => _filter = 'Unread'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selected: _filter == 'All',
                  label: const Text('All'),
                  selectedColor: AppColors.green,
                  labelStyle: TextStyle(
                    color: _filter == 'All' ? Colors.white : AppColors.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() => _filter = 'All'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: unreadCount == 0 ? null : _markAll,
                  icon: const Icon(Icons.done_all_rounded, size: 15),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: HeritageCard(
                  color: AppColors.surfaceSoft,
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 42,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No notifications',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...visible.map(
                (item) => _NotificationCard(
                  item: item,
                  onTap: () => _markRead(item),
                  onDelete: () => _delete(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HeritageCard(
        onTap: onTap,
        color: item.read ? AppColors.surfaceSoft : AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HeritageBadge(
                  label: item.read ? 'Read' : 'Unread',
                  color: item.read ? AppColors.green : AppColors.primary,
                ),
                const Spacer(),
                Text(
                  formatter.format(item.createdAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textMuted,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  item.read ? 'Viewed' : 'Tap to mark as read',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: item.read ? AppColors.textMuted : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  item.read ? Icons.check_rounded : Icons.circle_outlined,
                  size: 15,
                  color: item.read ? AppColors.green : AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
