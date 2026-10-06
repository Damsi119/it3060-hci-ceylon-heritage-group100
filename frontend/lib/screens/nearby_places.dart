import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/tourism_place.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';
import 'place_recommendations.dart';
import 'restaurant_details.dart';

/// Nearby places landing screen backed by the places API.
class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  String _category = 'All';
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<TourismPlace> _places = [];
  bool _loading = true;
  bool _locating = false;
  Position? _position;
  String? _locationMessage;
  String? _error;
  static const _categories = ['All', 'Restaurants', 'Hotels', 'Shops'];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await TourismService.instance.getPlaces(
        category: _category,
        search: _searchController.text,
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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _locating = false;
      });
      await _loadPlaces();
    } catch (error) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  int _distanceFor(TourismPlace place) {
    final position = _position;
    if (position == null || place.latitude == null || place.longitude == null) {
      return place.distanceMeters;
    }
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.latitude!,
      place.longitude!,
    ).round();
  }

  List<TourismPlace> get _nearbyPlaces {
    final places = [..._places];
    if (_position != null) {
      places.sort((a, b) => _distanceFor(a).compareTo(_distanceFor(b)));
    }
    return places;
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPlaces);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList.list(
                children: [
                  const Text('Nearby Places', style: _title),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _position == null
                              ? 'Galle, Sri Lanka · sample location'
                              : 'Your location · ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                          style: _subtle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _locating ? null : _useCurrentLocation,
                        icon: _locating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location, size: 15),
                        label: Text(
                          _locating ? 'Locating' : 'Use my location',
                          style: const TextStyle(fontSize: 10),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _brown,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  if (_locationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _locationMessage!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: _searchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search nearby places...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 19),
                      suffixIcon: const Icon(
                        Icons.tune,
                        size: 19,
                        color: _brown,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CategoryChips(
                    values: _categories,
                    selected: _category,
                    onSelect: (v) {
                      setState(() => _category = v);
                      _loadPlaces();
                    },
                  ),
                  const SizedBox(height: 13),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: SizedBox(
                      height: 128,
                      child: NearbyMap(
                        places: _places,
                        position: _position,
                        onPlaceTap: (place) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RestaurantDetailsScreen(place: place),
                          ),
                        ),
                        showOpenButton: true,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Map and place data © OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9, color: Color(0xFF68716D)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const _SectionHeading(
                    title: 'Top Places Nearby',
                    action: 'See All',
                  ),
                  const SizedBox(height: 9),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _LoadError(message: _error!, onRetry: _loadPlaces)
                  else if (_places.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No places found nearby.'),
                    )
                  else
                    for (final place in _nearbyPlaces) ...[
                      _PlaceCard(
                        place: place,
                        distanceMeters: _distanceFor(place),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RestaurantDetailsScreen(place: place),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                    ],
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlaceRecommendationsScreen(),
                      ),
                    ),
                    child: const Text('View Recommendations'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const TourismBottomNav(currentIndex: 0),
    );
  }
}

const _title = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  color: Color(0xFF222826),
);
const _subtle = TextStyle(fontSize: 11, color: Color(0xFF68716D));
const _brown = Color(0xFF824A2B);
const _line = Color(0xFFE9E2DB);

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.values,
    required this.selected,
    required this.onSelect,
  });
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values.map((value) {
        final active = value == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 7),
          child: ChoiceChip(
            label: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.white : const Color(0xFF47514D),
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: active,
            onSelected: (_) => onSelect(value),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: _brown,
            side: BorderSide(color: active ? _brown : _line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.distanceMeters,
    required this.onTap,
  });
  final TourismPlace place;
  final int distanceMeters;
  final VoidCallback onTap;
  IconData get _icon => switch (place.category) {
    'RESTAURANTS' => Icons.restaurant,
    'HOTELS' => Icons.hotel,
    'SHOPS' => Icons.storefront,
    'MUSEUM' => Icons.museum_outlined,
    _ => Icons.account_balance_outlined,
  };
  Color get _color => switch (place.category) {
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
      border: Border.all(color: _line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _brown, size: 27),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(place.category, style: _subtle.copyWith(fontSize: 9)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFE99A26), size: 13),
                    Text(
                      ' ${place.rating.toStringAsFixed(1)} · ${_distanceLabel(distanceMeters)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF5B625E),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _Status(open: place.isOpen),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.near_me_outlined,
            color: Color(0xFF9AA6A0),
            size: 17,
          ),
        ],
      ),
    ),
  );
}

String _distanceLabel(int meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';

class NearbyMap extends StatelessWidget {
  const NearbyMap({
    super.key,
    required this.places,
    required this.position,
    required this.onPlaceTap,
    this.showOpenButton = false,
  });

  final List<TourismPlace> places;
  final Position? position;
  final ValueChanged<TourismPlace> onPlaceTap;
  final bool showOpenButton;

  static const _fallbackCenter = LatLng(6.0260, 80.2170);

  @override
  Widget build(BuildContext context) {
    final center = position == null
        ? _fallbackCenter
        : LatLng(position!.latitude, position!.longitude);
    final markers = <Marker>[
      if (position != null)
        Marker(
          point: center,
          width: 42,
          height: 42,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      for (final place in places)
        if (place.latitude != null && place.longitude != null)
          Marker(
            point: LatLng(place.latitude!, place.longitude!),
            width: 40,
            height: 40,
            child: IconButton(
              tooltip: place.name,
              onPressed: () => onPlaceTap(place),
              icon: const Icon(Icons.location_on, color: _brown, size: 34),
            ),
          ),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            key: ValueKey('${center.latitude},${center.longitude}'),
            options: MapOptions(
              initialCenter: center,
              initialZoom: position == null ? 14.0 : 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        if (showOpenButton)
          Positioned(
            left: 10,
            top: 10,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _NearbyLiveMapScreen(
                    places: places,
                    position: position,
                    onPlaceTap: onPlaceTap,
                  ),
                ),
              ),
              icon: const Icon(Icons.map_outlined, size: 15),
              label: const Text(
                'View Live Map',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class _NearbyLiveMapScreen extends StatelessWidget {
  const _NearbyLiveMapScreen({
    required this.places,
    required this.position,
    required this.onPlaceTap,
  });

  final List<TourismPlace> places;
  final Position? position;
  final ValueChanged<TourismPlace> onPlaceTap;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nearby places map')),
    body: NearbyMap(places: places, position: position, onPlaceTap: onPlaceTap),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: open ? const Color(0xFFE9F5ED) : const Color(0xFFFDE9E6),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      open ? 'Open' : 'Closed',
      style: TextStyle(
        fontSize: 8,
        color: open ? const Color(0xFF39714C) : const Color(0xFFB34A40),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'Could not load places: $message',
        style: const TextStyle(fontSize: 11, color: Color(0xFFB3261E)),
      ),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action});
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      Text(
        action,
        style: const TextStyle(
          fontSize: 10,
          color: _brown,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  List<TourismPlace> _places = [];
  Position? _position;
  bool _loading = true;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await TourismService.instance.getPlaces(
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

  Future<void> _locate() async {
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
      await _loadPlaces();
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
    appBar: AppBar(title: const Text('Places Map')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _position == null
                      ? 'Galle sample map'
                      : 'Your location · ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 16),
                label: Text(_locating ? 'Locating' : 'Use my location'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : NearbyMap(
                  places: _places,
                  position: _position,
                  onPlaceTap: (place) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailsScreen(place: place),
                    ),
                  ),
                ),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text(
            'Map and place data © OpenStreetMap contributors',
            style: TextStyle(fontSize: 9),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 1),
  );
}
