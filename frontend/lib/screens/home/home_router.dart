import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../admin/admin_home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'account_home_screen.dart';
import 'heritage_home_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key, required this.user, this.initialTab = 0});

  final UserProfile user;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case 'ADMIN':
        return AdminHomeScreen(user: user);
      case 'TOURIST':
        return HeritageHomeScreen(
          user: user,
          onNotifications: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(user: user),
              ),
            );
          },
          onProfile: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
            );
          },
        );
      default:
        return AccountHomeScreen(user: user);
    }
  }
}
