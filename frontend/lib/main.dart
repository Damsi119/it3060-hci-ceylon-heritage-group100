import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'models/user_profile.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_router.dart';
import 'services/token_store.dart';
import 'services/user_service.dart';
import 'widgets/heritage_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CeylonHeritageApp());
}

class CeylonHeritageApp extends StatelessWidget {
  const CeylonHeritageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Heritage',
      theme: AppTheme.light,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  UserProfile? _user;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await TokenStore.getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _ready = true);
      return;
    }

    try {
      final user = await UserService.instance.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _ready = true;
        });
      }
    } catch (_) {
      await TokenStore.clear();
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeritageLogo(),
              SizedBox(height: 22),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) return const LoginScreen();

    if (_user!.passwordChangeRequired) {
      return ChangePasswordScreen(user: _user!, forced: true);
    }

    return HomeRouter(user: _user!);
  }
}
