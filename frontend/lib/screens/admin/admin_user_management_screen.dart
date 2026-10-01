import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String? _role;
  List<UserProfile> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await AdminUserService.instance.getUsers(role: _role);
      if (mounted) setState(() => _users = users);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _status(UserProfile user, bool enabled) async {
    try {
      await AdminUserService.instance.updateStatus(user.id, enabled);
      if (!mounted) return;
      showHeritageMessage(
        context,
        enabled ? 'Account enabled' : 'Account disabled',
      );
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    }
  }

  Future<void> _delete(UserProfile user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Soft delete ${user.displayName} (${user.email})?'),
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
    if (ok != true) return;
    try {
      await AdminUserService.instance.deleteUser(user.id);
      if (!mounted) return;
      showHeritageMessage(context, 'User removed');
      _load();
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeritageAppBar(showBack: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'View and manage registered Ceylon Heritage accounts.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              children: [
                _Filter(
                  label: 'ALL',
                  selected: _role == null,
                  onTap: () {
                    setState(() => _role = null);
                    _load();
                  },
                ),
                _Filter(
                  label: 'TOURIST',
                  selected: _role == 'TOURIST',
                  onTap: () {
                    setState(() => _role = 'TOURIST');
                    _load();
                  },
                ),
                _Filter(
                  label: 'GUIDE',
                  selected: _role == 'GUIDE',
                  onTap: () {
                    setState(() => _role = 'GUIDE');
                    _load();
                  },
                ),
                _Filter(
                  label: 'ADMIN',
                  selected: _role == 'ADMIN',
                  onTap: () {
                    setState(() => _role = 'ADMIN');
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: HeritageCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: user.role == 'GUIDE'
                              ? AppColors.greenSoft
                              : AppColors.primarySoft,
                          child: Text(
                            user.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: user.role == 'GUIDE'
                                  ? AppColors.greenDark
                                  : AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 9.3,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              HeritageBadge(
                                label: user.role,
                                color: user.role == 'GUIDE'
                                    ? AppColors.green
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'enable') _status(user, true);
                            if (value == 'disable') _status(user, false);
                            if (value == 'delete') _delete(user);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'enable',
                              child: Text('Enable account'),
                            ),
                            PopupMenuItem(
                              value: 'disable',
                              child: Text('Disable account'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete user'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    selected: selected,
    label: Text(label),
    selectedColor: AppColors.primary,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.text,
      fontSize: 9.3,
      fontWeight: FontWeight.w700,
    ),
    onSelected: (_) => onTap(),
  );
}
