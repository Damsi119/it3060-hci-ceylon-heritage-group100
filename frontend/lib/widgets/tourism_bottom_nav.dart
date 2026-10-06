import 'package:flutter/material.dart';

class TourismBottomNav extends StatelessWidget {
  const TourismBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _routes = ['/explore', '/map', '/weather', '/saved', '/profile'];

  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 66,
    selectedIndex: currentIndex,
    onDestinationSelected: (index) {
      Navigator.of(context).pushReplacementNamed(_routes[index]);
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Explore',
      ),
      NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
      NavigationDestination(
        icon: Icon(Icons.wb_sunny_outlined),
        selectedIcon: Icon(Icons.wb_sunny),
        label: 'Weather',
      ),
      NavigationDestination(
        icon: Icon(Icons.favorite_border),
        selectedIcon: Icon(Icons.favorite),
        label: 'Saved',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  );
}
