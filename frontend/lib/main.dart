import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'models/user_profile.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/live_weather.dart';
import 'screens/my_favourites.dart';
import 'screens/nearby_places.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_router.dart';
import 'services/api_client.dart';
import 'services/notification_center.dart';
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
      onGenerateRoute: _generateRoute,
      builder: (context, child) {
        final viewport = MediaQuery.of(context);
        final appWidth = viewport.size.width > 600
            ? 430.0
            : viewport.size.width;
        final appMedia = viewport.copyWith(
          size: Size(appWidth, viewport.size.height),
        );
        return ColoredBox(
          color: const Color(0xFFE8E3DE),
          child: Center(
            child: SizedBox(
              width: appWidth,
              height: viewport.size.height,
              child: MediaQuery(
                data: appMedia,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      '/explore' => const NearbyPlacesScreen(),
      '/map' => const NearbyMapScreen(),
      '/weather' => const LiveWeatherScreen(),
      '/saved' => const MyFavouritesScreen(),
      '/profile' => const _ProfileRoute(),
      _ => const NearbyPlacesScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}

class _ProfileRoute extends StatefulWidget {
  const _ProfileRoute();

  @override
  State<_ProfileRoute> createState() => _ProfileRouteState();
}

class _ProfileRouteState extends State<_ProfileRoute> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserService.instance.getProfile();
  }

  void _retry() {
    setState(() => _profileFuture = UserService.instance.getProfile());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UserProfile>(
    future: _profileFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load your profile.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  if (snapshot.error is ApiException &&
                      [
                        401,
                        403,
                      ].contains((snapshot.error as ApiException).statusCode))
                    FilledButton(
                      onPressed: () {
                        TokenStore.clear();
                        NotificationCenter.instance.stop(clear: true);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text('Sign in again'),
                    ),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/explore'),
                    child: const Text('Back to Explore'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ProfileScreen(user: snapshot.data!);
    },
  );
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
      await NotificationCenter.instance.start();
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
