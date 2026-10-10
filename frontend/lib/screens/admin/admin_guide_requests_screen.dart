import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/guide_application.dart';
import '../../services/api_client.dart';
import '../../services/guide_service.dart';
import '../../widgets/heritage_app_bar.dart';
import '../../widgets/heritage_badge.dart';
import '../../widgets/heritage_card.dart';
import '../../widgets/heritage_message.dart';

class AdminGuideRequestsScreen extends StatefulWidget {
  const AdminGuideRequestsScreen({super.key});

  @override
  State<AdminGuideRequestsScreen> createState() =>
      _AdminGuideRequestsScreenState();
}

class _AdminGuideRequestsScreenState extends State<AdminGuideRequestsScreen> {
  String _status = 'PENDING';
  List<GuideApplication> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await GuideService.instance.getByStatus(_status);
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) showHeritageMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(GuideApplication item, String status) async {
    final noteController = TextEditingController();
    var confirmed = false;
    var reviewNote = '';

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(
            status == 'APPROVED'
                ? 'Approve guide request?'
                : 'Reject guide request?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                item.email,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Review note (optional)',
                ),
              ),
              if (status == 'APPROVED') ...[
                const SizedBox(height: 10),
                const Text(
                  'Approval automatically creates the GUIDE account and emails the temporary password.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: status == 'APPROVED'
                    ? AppColors.green
                    : AppColors.danger,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(status == 'APPROVED' ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      );

      confirmed = confirm == true;
      reviewNote = noteController.text.trim();
    } finally {
      noteController.dispose();
    }

    if (!confirmed) return;
    try {
      await GuideService.instance.review(
        id: item.id,
        status: status,
        note: reviewNote,
      );
      if (!mounted) return;
      showHeritageMessage(
        context,
        status == 'APPROVED'
            ? 'Guide approved and account created'
            : 'Guide request rejected',
      );
      await _load();
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
              'Guide Requests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review local guide applications submitted from the public login screen.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              children: ['PENDING', 'APPROVED', 'REJECTED'].map((status) {
                return ChoiceChip(
                  selected: _status == status,
                  selectedColor: status == 'PENDING'
                      ? AppColors.primary
                      : AppColors.green,
                  labelStyle: TextStyle(
                    color: _status == status ? Colors.white : AppColors.text,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                  label: Text(status),
                  onSelected: (_) {
                    setState(() => _status = status);
                    _load();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const HeritageCard(
                color: AppColors.surfaceSoft,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 38,
                      color: AppColors.green,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No guide requests in this section',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              )
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HeritageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                item.name.isEmpty
                                    ? 'G'
                                    : item.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    item.email,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            HeritageBadge(
                              label: item.status,
                              color: item.status == 'PENDING'
                                  ? AppColors.primary
                                  : AppColors.green,
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        _Detail(icon: Icons.phone_outlined, text: item.phone),
                        _Detail(
                          icon: Icons.place_outlined,
                          text: item.primaryServiceArea,
                        ),
                        _Detail(
                          icon: Icons.translate_rounded,
                          text: item.languages,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.experience,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.45,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (_status == 'PENDING') ...[
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _review(item, 'REJECTED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _review(item, 'APPROVED'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.green),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 10.2))),
      ],
    ),
  );
}
