import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/live_weather.dart';
import 'screens/my_favourites.dart';
import 'screens/nearby_places.dart';
import 'screens/home/heritage_home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/user_service.dart';

/// Local preview entry point for the heritage home screen.
/// Run with: flutter run -d edge -t lib/home_preview.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CeylonHeritagePreviewApp());
}

class CeylonHeritagePreviewApp extends StatelessWidget {
  const CeylonHeritagePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Heritage',
      builder: (context, child) {
        final viewport = MediaQuery.of(context);
        final width = viewport.size.width > 600 ? 430.0 : viewport.size.width;
        final appMedia = viewport.copyWith(
          size: Size(width, viewport.size.height),
        );
        return ColoredBox(
          color: const Color(0xFFE8E3DE),
          child: Center(
            child: SizedBox(
              width: width,
              height: viewport.size.height,
              child: MediaQuery(
                data: appMedia,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/explore' => const NearbyPlacesScreen(),
          '/map' => const NearbyMapScreen(),
          '/weather' => const LiveWeatherScreen(),
          '/saved' => const MyFavouritesScreen(),
          '/profile' => const _ProfilePreviewScreen(),
          _ => const NearbyPlacesScreen(),
        };
        return MaterialPageRoute<void>(
          builder: (_) => page,
          settings: settings,
        );
      },
      home: Builder(
        builder: (context) => HeritageHomeScreen(
          onNearby: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const NearbyPlacesScreen(),
            ),
          ),
        ),
      ),
  );
}

class _ProfilePreviewScreen extends StatefulWidget {
  const _ProfilePreviewScreen();

  @override
  State<_ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<_ProfilePreviewScreen> {
  late Future<UserProfile> _profile = UserService.instance.getProfile();

  @override
  Widget build(BuildContext context) => FutureBuilder<UserProfile>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.hasData) return ProfileScreen(user: snapshot.data!);
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sign in to view your profile.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
  );
}
