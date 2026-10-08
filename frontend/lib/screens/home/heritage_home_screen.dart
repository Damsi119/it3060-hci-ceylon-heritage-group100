import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../widgets/heritage_logo.dart';
import '../explore/historical_place_details_screen.dart';
import '../explore/historical_places_screen.dart';
import '../community/community_feed_screen.dart';
import '../tours/create_tour_screen.dart';
import '../tours/tour_plan_generator_screen.dart';
import '../tours/tour_details_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Heritage',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9A4F2D)),
      ),
      home: const HeritageHomeScreen(),
    ),
  );
}

class HeritageHomeScreen extends StatefulWidget {
  const HeritageHomeScreen({
    super.key,
    this.user,
    this.onExplore,
    this.onNearby,
    this.onCreateTour,
    this.onTours,
    this.onCommunity,
    this.onProfile,
    this.onNotifications,
  });

  // Keeps this screen compatible with the existing user object.
  final dynamic user;

  final VoidCallback? onExplore;
  final VoidCallback? onNearby;
  final VoidCallback? onCreateTour;
  final VoidCallback? onTours;
  final VoidCallback? onCommunity;

  // Retained for compatibility with existing callers.
  // This screen does not invoke leader-page navigation.
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  @override
  State<HeritageHomeScreen> createState() => _HeritageHomeScreenState();
}

class _HeritageHomeScreenState extends State<HeritageHomeScreen> {
  static const _primary = Color(0xFF9A4F2D);
  static const _accent = Color(0xFFC96F4A);
  static const _heading = Color(0xFF3A241B);
  static const _muted = Color(0xFF6F6A66);

  final TextEditingController _searchController = TextEditingController();

  bool _openingPlace = false;
  Route<dynamic>? _homeRoute;

  static const _featured = <_HomePlace>[
    _HomePlace(
      name: 'Polonnaruwa Ancient City',
      city: 'Polonnaruwa',
      image: 'assets/images/polonnaruwa.png',
    ),
    _HomePlace(
      name: 'Ruwanwelisaya',
      city: 'Anuradhapura',
      image: 'assets/images/ruwanwelisaya.png',
    ),
    _HomePlace(
      name: 'Galle Fort',
      city: 'Galle',
      image: 'assets/images/galle_fort.png',
    ),
  ];

  static const _nearby = <_HomePlace>[
    _HomePlace(
      name: 'Gal Vihara',
      city: 'Polonnaruwa',
      image: 'assets/images/gal_vihara.png',
    ),
    _HomePlace(
      name: 'Rankoth Vehera',
      city: 'Polonnaruwa',
      image: 'assets/images/rankoth_vehera.png',
    ),
    _HomePlace(
      name: 'Lankathilaka Temple',
      city: 'Polonnaruwa',
      image: 'assets/images/lankathilaka_temple.png',
    ),
    _HomePlace(
      name: 'Parakrama Samudraya',
      city: 'Polonnaruwa',
      image: 'assets/images/parakrama_samudraya.png',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeRoute = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _returnHome() {
    if (!mounted) return;

    final route = _homeRoute;
    if (route == null || !route.isActive) return;

    Navigator.of(context).popUntil((candidate) => identical(candidate, route));
  }

  void _navigateFromChild(VoidCallback action) {
    if (!mounted) return;

    _returnHome();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  void _openExplore({String keyword = ''}) {
    if (!mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoricalPlacesScreen(
          user: widget.user,
          initialKeyword: keyword,
          onHome: _returnHome,
          onCommunity: () => _navigateFromChild(_community),
          onTours: (places) {
            final selectedPlaces = places
                .map<Map<String, dynamic>>(
                  (place) => Map<String, dynamic>.from(place.toJson()),
                )
                .toList();

            _navigateFromChild(
              () => _openCreateTour(initialPlaces: selectedPlaces),
            );
          },
        ),
      ),
    );
  }

  void _explore() {
    final callback = widget.onExplore;

    if (callback != null) {
      callback();
    } else {
      _openExplore();
    }
  }

  void _nearbyPlaces() {
    final callback = widget.onNearby;

    if (callback != null) {
      callback();
    } else {
      // Browse the displayed region; this does not use GPS.
      _openExplore(keyword: 'Polonnaruwa');
    }
  }

  void _openCreateTour({
    List<Map<String, dynamic>> initialPlaces = const [],
    int? tourId,
  }) {
    if (!mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (createContext) => CreateTourScreen(
          tourId: tourId,
          initialPlaces: initialPlaces,
          onHome: _returnHome,
          onExplore: () => _navigateFromChild(_explore),
          onCommunity: () => _navigateFromChild(_community),

          // No navigation to the leader's Profile page.
          onProfile: _profile,

          // New: display the saved tour in Tour Details.
          onSaved: (savedTour) {
            _showSavedTour(savedTour, createContext);
          },
        ),
      ),
    );
  }

  Future<void> _showSavedTour(
    Map<String, dynamic> savedTour,
    BuildContext createContext,
  ) async {
    if (!mounted || !createContext.mounted) return;

    final rawId = savedTour['id'];

    final tourId = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '');

    if (tourId == null || tourId <= 0) {
      _message('The saved tour did not return a valid ID.');
      return;
    }

    // Allow the editor's saved state and PopScope to rebuild.
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted || !createContext.mounted) return;

    // Do not replace another page if the user already navigated away.
    if (ModalRoute.of(createContext)?.isCurrent != true) return;

    Navigator.of(createContext).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => TourDetailsScreen(
          tourId: tourId,
          initialTour: Map<String, dynamic>.from(savedTour),
          onHome: _returnHome,
          onExplore: () => _navigateFromChild(_explore),
          onCommunity: () => _navigateFromChild(_community),

          // Keep Profile within this component's existing behavior.
          onProfile: _profile,

          // Open the existing Historical Place Details page.
          onPlaceSelected: (placeId) {
            _openCommunityPlace(placeId);
          },
        ),
      ),
    );
  }

  void _createTour() {
    final callback = widget.onCreateTour ?? widget.onTours;

    if (callback != null) {
      callback();
    } else {
      _openCreateTour();
    }
  }

  void _openTourPlanner() {
    if (!mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TourPlanGeneratorScreen(onHome: _returnHome),
      ),
    );
  }

  void _tours() {
    final callback = widget.onTours ?? widget.onCreateTour;

    if (callback != null) {
      callback();
    } else {
      _openCreateTour();
    }
  }

  void _community() {
    final callback = widget.onCommunity;

    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityFeedScreen(
          user: widget.user,
          onHome: _returnHome,
          onExplore: () => _navigateFromChild(_explore),
          onTours: () => _navigateFromChild(_tours),
          onPlaceSelected: (placeId) {
            _openCommunityPlace(placeId);
          },

          // Keep icons without navigating to leader pages.
          onProfile: _profile,
          onNotifications: _notifications,
        ),
      ),
    );
  }

  void _profile() {
    final callback = widget.onProfile;

    if (callback != null) {
      callback();
    } else {
      _message('Profile navigation is outside this component.');
    }
  }

  void _notifications() {
    final callback = widget.onNotifications;

    if (callback != null) {
      callback();
    } else {
      _message('Notifications navigation is outside this component.');
    }
  }

  void _search(String value) {
    FocusScope.of(context).unfocus();
    _openExplore(keyword: value.trim());
  }

  String _normalise(String value) {
    return value
        .toLowerCase()
        .replaceAll('lankatilaka', 'lankathilaka')
        .replaceAll('ruwanwalisaya', 'ruwanwelisaya')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _absoluteImageUrl(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = clean.startsWith('/') ? clean : '/$clean';
    return '$baseUrl$path';
  }

  String get _avatarInitial {
    final user = widget.user;
    if (user is UserProfile) {
      final name = user.displayName.trim();
      return name.isEmpty ? 'U' : name[0].toUpperCase();
    }
    return 'U';
  }

  String? get _profileImageUrl {
    final user = widget.user;
    if (user is UserProfile) return user.profileImageUrl;
    return null;
  }

  Future<void> _openCommunityPlace(int placeId) async {
    if (_openingPlace || placeId <= 0) return;

    setState(() => _openingPlace = true);

    try {
      final response = await ApiClient.instance
          .get('/api/places/$placeId', authenticated: false)
          .timeout(const Duration(seconds: 20));

      if (response is! Map) {
        throw const FormatException('Invalid place response.');
      }

      final place = Map<String, dynamic>.from(response);

      if (!mounted) return;

      setState(() => _openingPlace = false);
      _showPlaceDetails(placeId, place);
    } catch (_) {
      if (!mounted) return;

      setState(() => _openingPlace = false);

      _message(
        'Could not load this place. Check the backend connection '
        'and try again.',
      );
    }
  }

  Future<void> _openPlace(_HomePlace selected) async {
    if (_openingPlace) return;

    setState(() => _openingPlace = true);

    Map<String, dynamic>? matchedPlace;

    try {
      final response = await ApiClient.instance
          .get('/api/places', authenticated: false)
          .timeout(const Duration(seconds: 20));

      if (response is! List) {
        throw const FormatException('Invalid places response.');
      }

      for (final item in response) {
        if (item is! Map) continue;

        final place = Map<String, dynamic>.from(item);

        final name = place['name']?.toString() ?? '';
        final city = place['city']?.toString() ?? '';

        if (_normalise(name) == _normalise(selected.name) &&
            _normalise(city) == _normalise(selected.city)) {
          matchedPlace = place;
          break;
        }
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _openingPlace = false);

      _message(
        'Could not load this place. Check the backend connection '
        'and try again.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _openingPlace = false);

    if (matchedPlace == null) {
      _message('${selected.name} is not available in the backend yet.');
      return;
    }

    final place = matchedPlace;
    final rawId = place['id'];

    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '');

    if (id == null || id <= 0) {
      _message('This place has an invalid ID.');
      return;
    }

    _showPlaceDetails(id, place);
  }

  void _showPlaceDetails(int placeId, Map<String, dynamic> place) {
    if (!mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoricalPlaceDetailsScreen(
          placeId: placeId,
          initialPlace: place,
          onAddToTour: () {
            // This place is selected when Create Tour opens.
            // Back returns to the Details page.
            _openCreateTour(initialPlaces: [place]);
          },
        ),
      ),
    );
  }

  Widget _image(String path) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(
          color: Color(0xFFF1E7DC),
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: _muted,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.interTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_openingPlace)
                const LinearProgressIndicator(
                  color: _primary,
                  backgroundColor: Color(0xFFF1E7DC),
                  minHeight: 3,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hero(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _searchBar(),
                                const SizedBox(height: 16),
                                _smartPlannerCard(),
                                const SizedBox(height: 16),
                                _quickActions(),
                                const SizedBox(height: 24),
                                _sectionHeader(
                                  'Featured Historical Places',
                                  _explore,
                                ),
                                const SizedBox(height: 12),
                                _featuredPlaces(),
                                const SizedBox(height: 24),
                                _sectionHeader(
                                  'Explore Near You',
                                  _nearbyPlaces,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Discover places around Polonnaruwa',
                                  style: TextStyle(fontSize: 12, color: _muted),
                                ),
                                const SizedBox(height: 12),
                                _nearbyCards(),
                                const SizedBox(height: 20),
                                _tourBanner(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomNavigation(),
      ),
    );
  }

  Widget _hero() {
    return SizedBox(
      height: 310,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _image('assets/images/polonnaruwa_banner.png'),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF2FCF8F4),
                  Color(0xA6FCF8F4),
                  Color(0x00FCF8F4),
                ],
                stops: [0, 0.42, 0.78],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 12,
            top: 14,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeritageLogo(),
                      const SizedBox(height: 3),
                      const Text(
                        'EXPLORE · DISCOVER · PRESERVE',
                        style: TextStyle(
                          fontSize: 7,
                          letterSpacing: 1.4,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Notifications',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _heading,
                  ),
                  onPressed: _notifications,
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
                const SizedBox(width: 8),
                _profileAvatarButton(),
              ],
            ),
          ),
          Positioned(
            top: 88,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STEP INTO SRI LANKA'S PAST",
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF40516A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover\nTimeless\nHeritage',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 33,
                    height: 1.03,
                    fontWeight: FontWeight.w700,
                    color: _heading,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Ancient cities, sacred places and\n'
                    'stories that live forever.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: _heading,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: _explore,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start Exploring', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, size: 17),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatarButton() {
    const size = 40.0;
    final imageUrl = _absoluteImageUrl(_profileImageUrl);

    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _profile,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: imageUrl == null
              ? _profileInitial()
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _profileInitial(),
                ),
        ),
      ),
    );
  }

  Widget _profileInitial() {
    return Center(
      child: Text(
        _avatarInitial,
        style: const TextStyle(
          color: _primary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search historical places, cities or landmarks...',
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7F8BA0),
              ),
              prefixIcon: IconButton(
                tooltip: 'Search',
                onPressed: () => _search(_searchController.text),
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF667B99),
                  size: 22,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E2DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E2DE)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Open Explore filters',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0F1F5),
            foregroundColor: const Color(0xFF667B99),
          ),
          onPressed: () => _openExplore(keyword: _searchController.text.trim()),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _smartPlannerCard() {
    return Material(
      color: const Color(0xFFFAEDE6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openTourPlanner,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADFD5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Smart Tour Planner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _heading,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFC96F4A),
                          size: 17,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Generate a budget-friendly Sri Lanka route.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            'Explore\nPlaces',
            Icons.account_balance,
            const Color(0xFFF8DFD5),
            _accent,
            _explore,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            'Nearby',
            Icons.location_on,
            const Color(0xFFDDE8FF),
            const Color(0xFF416DAB),
            _nearbyPlaces,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            'Create\nTour',
            Icons.route,
            const Color(0xFFFFE8C8),
            _primary,
            _createTour,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color circleColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: const Color(0xFFFAF7F4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: circleColor,
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: _heading),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _heading,
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(50, 36),
          ),
          child: const Text('See All →', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _featuredPlaces() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _featured.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _placeCard(_featured[i])),
        ],
      ],
    );
  }

  Widget _nearbyCards() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _nearby.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return SizedBox(width: 130, child: _placeCard(_nearby[index]));
        },
      ),
    );
  }

  Widget _placeCard(_HomePlace place) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAE5DF)),
      ),
      child: InkWell(
        onTap: _openingPlace ? null : () => _openPlace(place),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 100,
              child: _image(place.image),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32,
                    child: Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _heading,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: _accent, size: 13),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          place.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tourBanner() {
    return Material(
      color: const Color(0xFFFAEDE6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _createTour,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.route, color: _accent, size: 35),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Your Heritage Tour',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select places and create your own tour.',
                      style: TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 19,
                backgroundColor: _primary,
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAE5DF))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _navItem('Home', Icons.home, true, _returnHome),
              _navItem('Explore', Icons.search, false, _explore),
              _navItem('Tours', Icons.add_circle_outline, false, _tours),
              _navItem('Community', Icons.groups_outlined, false, _community),
              _navItem('Profile', Icons.person_outline, false, _profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    final color = selected ? _accent : const Color(0xFF667B99);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePlace {
  const _HomePlace({
    required this.name,
    required this.city,
    required this.image,
  });

  final String name;
  final String city;
  final String image;
}
