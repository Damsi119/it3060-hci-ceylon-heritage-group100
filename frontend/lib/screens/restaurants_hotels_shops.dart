import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import 'restaurant_details.dart';

/// Nearby restaurants, hotels, and shops loaded from the Spring Boot API.
class RestaurantsHotelsShopsScreen extends StatefulWidget {
  const RestaurantsHotelsShopsScreen({super.key});

  @override
  State<RestaurantsHotelsShopsScreen> createState() =>
      _RestaurantsHotelsShopsScreenState();
}

class _RestaurantsHotelsShopsScreenState
    extends State<RestaurantsHotelsShopsScreen> {
  String _filter = 'All';
  final _filters = const ['All', 'Restaurants', 'Hotels', 'Shops'];
  List<TourismPlace> _places = [];
  bool _loading = true;
  String? _error;
  Position? _position;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await TourismService.instance.getPlaces(
        category: _filter,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        radiusMeters: 5000,
      );
      if (mounted)
        setState(() {
          _places = places;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Allow location access in your browser or device settings.',
        );
      }
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() => _locating = false);
      await _load();
    } catch (error) {
      if (mounted)
        setState(() {
          _locating = false;
          _error = error.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Places Near You',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            'Restaurants, hotels and shops',
            style: TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _locating ? null : _useLocation,
          tooltip: 'Use my location',
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    ),
    body: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(17, 4, 17, 13),
          child: Row(
            children: _filters.map((label) {
              final selected = label == _filter;
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.white : const Color(0xFF47514D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _filter = label);
                    _load();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF824A2B),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF824A2B)
                        : const Color(0xFFE9E2DB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load places: $_error',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _places.isEmpty
              ? const Center(child: Text('No places found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                  itemCount: _places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return _ListingCard(
                      place: place,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailsScreen(place: place),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
  );
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.place, required this.onTap});
  final TourismPlace place;
  final VoidCallback onTap;
  IconData get _icon => switch (place.category) {
    'RESTAURANTS' => Icons.restaurant,
    'HOTELS' => Icons.hotel,
    'SHOPS' => Icons.storefront,
    _ => Icons.museum_outlined,
  };
  Color get _tint => switch (place.category) {
    'RESTAURANTS' => const Color(0xFFEBCB9D),
    'HOTELS' => const Color(0xFFBDD5C6),
    'SHOPS' => const Color(0xFFE9D7B6),
    _ => const Color(0xFFD7C9BB),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9E2DB)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 29, color: const Color(0xFF824A2B)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFE99A26)),
                    Text(
                      ' ${place.rating.toStringAsFixed(1)} · ${place.distanceLabel}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF59625E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: place.isOpen
                        ? const Color(0xFFE9F5ED)
                        : const Color(0xFFFDE9E6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    place.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 8,
                      color: place.isOpen
                          ? const Color(0xFF39714C)
                          : const Color(0xFFB34A40),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.near_me_outlined,
            size: 18,
            color: Color(0xFF9AA6A0),
          ),
        ],
      ),
    ),
  );
}
