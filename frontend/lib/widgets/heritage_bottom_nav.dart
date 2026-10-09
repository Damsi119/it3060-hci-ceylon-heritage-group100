import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'notification_badge.dart';

class HeritageBottomNav extends StatelessWidget {
  const HeritageBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 68,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.greenSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: NotificationBadge(
            child: Icon(Icons.notifications_none_rounded),
          ),
          selectedIcon: NotificationBadge(
            child: Icon(Icons.notifications_rounded),
          ),
          label: 'Alerts',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
