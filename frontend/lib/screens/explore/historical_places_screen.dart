import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_config.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'historical_place_details_screen.dart';

// Separate preview entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Heritage',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9A4F2D),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFFAF6),
      ),
      home: const HistoricalPlacesScreen(),
    ),
  );
}

class HistoricalPlace {
  const HistoricalPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.rating,
    this.reviewCount = 0,
    this.openingHours = '',
    this.visitDuration = '',
    this.entryFee = '',
    this.bestTimeToVisit = '',
    this.accessibility = '',
    this.visitDurationMinutes,
    this.galleryImages = const [],
  });

  final int id;
  final String name;
  final String city;
  final String category;
  final String description;
  final String imageUrl;
  final double? rating;
  final int reviewCount;
  final String openingHours;
  final String visitDuration;
  final String entryFee;
  final String bestTimeToVisit;
  final String accessibility;
  final int? visitDurationMinutes;
  final List<String> galleryImages;

  factory HistoricalPlace.fromJson(Map<String, dynamic> json) {
    int? integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    double? decimal(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    final id = integer(json['id']);
    if (id == null) {
      throw const FormatException('Place ID is missing.');
    }

    final gallery = json['galleryImages'];

    return HistoricalPlace(
      id: id,
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      rating: decimal(json['rating']),
      reviewCount: integer(json['reviewCount']) ?? 0,
      openingHours: json['openingHours']?.toString() ?? '',
      visitDuration: json['visitDuration']?.toString() ?? '',
      entryFee: json['entryFee']?.toString() ?? '',
      bestTimeToVisit: json['bestTimeToVisit']?.toString() ?? '',
      accessibility: json['accessibility']?.toString() ?? '',
      visitDurationMinutes: integer(json['visitDurationMinutes']),
      galleryImages: gallery is List
          ? gallery
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'openingHours': openingHours,
      'visitDuration': visitDuration,
      'entryFee': entryFee,
      'bestTimeToVisit': bestTimeToVisit,
      'accessibility': accessibility,
      'visitDurationMinutes': visitDurationMinutes,
      'galleryImages': galleryImages,
    };
  }

  String? get localImage {
    final value = name.toLowerCase();

    const assets = {
      'sigiriya': 'sigiriya.png',
      'tooth': 'temple_of_the_tooth.png',
      'jaffna': 'jaffna_fort.png',
      'mihintale': 'mihintale.png',
      'gal vihara': 'gal_vihara.png',
      'rankoth': 'rankoth_vehera.png',
      'lankathilaka': 'lankathilaka_temple.png',
      'lankatilaka': 'lankathilaka_temple.png',
      'parakrama': 'parakrama_samudraya.png',
      'polonnaruwa': 'polonnaruwa.png',
      'ruwan': 'ruwanwelisaya.png',
      'galle': 'galle_fort.png',
    };

    for (final entry in assets.entries) {
      if (value.contains(entry.key)) {
        return 'assets/images/${entry.value}';
      }
    }

    return null;
  }
}

class HistoricalPlacesScreen extends StatefulWidget {
  const HistoricalPlacesScreen({
    super.key,
    this.user,
    this.initialKeyword = '',
    this.onHome,
    this.onCommunity,
    this.onTours,
    this.onPlaceSelected,
  });

  final UserProfile? user;
  final String initialKeyword;
  final VoidCallback? onHome;
  final VoidCallback? onCommunity;
  final ValueChanged<List<HistoricalPlace>>? onTours;
  final ValueChanged<HistoricalPlace>? onPlaceSelected;

  @override
  State<HistoricalPlacesScreen> createState() =>
      _HistoricalPlacesScreenState();
}

class _HistoricalPlacesScreenState extends State<HistoricalPlacesScreen> {
  static const _primary = Color(0xFF9A4F2D);
  static const _heading = Color(0xFF3A241B);
  static const _muted = Color(0xFF6F6A66);
  static const _background = Color(0xFFFFFAF6);
  static const _surface = Color(0xFFF1E7DC);

  static const _categories = <String, String>{
    'ALL': 'All',
    'ANCIENT_CITY': 'Ancient Cities',
    'TEMPLE': 'Temples',
    'FORT': 'Forts',
    'MUSEUM': 'Museums',
    'ARCHAEOLOGICAL_SITE': 'Archaeological Sites',
  };

  late final TextEditingController _searchController;
  Timer? _debounce;

  String _category = 'ALL';
  String _sort = 'Recommended';

  List<HistoricalPlace> _popular = [];
  List<HistoricalPlace> _recommended = [];
  List<HistoricalPlace> _results = [];

  final Map<int, HistoricalPlace> _selected = {};

  bool _loading = true;
  String? _error;
  int _requestVersion = 0;

  bool get _searching =>
      _searchController.text.trim().isNotEmpty || _category != 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialKeyword,
    );
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<HistoricalPlace>> _fetch(String path) async {
    final response = await ApiClient.instance
        .get(path, authenticated: false)
        .timeout(const Duration(seconds: 20));

    if (response is! List) {
      throw const FormatException('Unexpected places response.');
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid place data.');
      }

      return HistoricalPlace.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<void> _load() async {
    if (!mounted) return;

    final version = ++_requestVersion;
    final keyword = _searchController.text.trim();
    final category = _category;
    final searching = keyword.isNotEmpty || category != 'ALL';

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (searching) {
        final query = Uri(
          queryParameters: {
            'keyword': keyword,
            'category': category,
          },
        ).query;

        final places = await _fetch('/api/places/search?$query');

        if (!mounted || version != _requestVersion) return;

        setState(() {
          _results = places;
          _loading = false;
        });
      } else {
        final lists = await Future.wait([
          _fetch('/api/places/popular'),
          _fetch('/api/places/recommended'),
        ]);

        if (!mounted || version != _requestVersion) return;

        setState(() {
          _popular = lists[0];
          _recommended = lists[1];
          _loading = false;
        });
      }
    } catch (error) {
      if (!mounted || version != _requestVersion) return;

      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'Could not load places. Check your backend connection.';
      });
    }
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _requestVersion++;

    setState(() {
      _loading = true;
      _error = null;
    });

    _debounce = Timer(
      const Duration(milliseconds: 450),
      _load,
    );
  }

  void _changeCategory(String category) {
    _debounce?.cancel();
    setState(() => _category = category);
    _load();
  }

  List<HistoricalPlace> _sorted(List<HistoricalPlace> source) {
    final places = List<HistoricalPlace>.from(source);

    if (_sort == 'Name A–Z') {
      places.sort(
            (a, b) => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
      );
    } else if (_sort == 'Highest rated') {
      places.sort(
            (a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1),
      );
    }

    return places;
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _togglePlace(HistoricalPlace place) {
    if (!_selected.containsKey(place.id) && _selected.length >= 20) {
      _message('You can select up to 20 places for a tour.');
      return false;
    }

    setState(() {
      if (_selected.containsKey(place.id)) {
        _selected.remove(place.id);
      } else {
        _selected[place.id] = place;
      }
    });

    return true;
  }

  void _openTours() {
    final callback = widget.onTours;

    if (callback != null) {
      callback(
        List<HistoricalPlace>.unmodifiable(_selected.values),
      );
      return;
    }

    _message(
      'Selected ${_selected.length} places. '
          'Tour Planning will be connected next.',
    );
  }

  void _openNotifications() {
    final user = widget.user;

    if (user == null) {
      _message(
        'Notifications are available from your signed-in account.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(user: user),
      ),
    );
  }

  void _openProfile() {
    final user = widget.user;

    if (user == null) {
      _message('Profile is available from your signed-in account.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(user: user),
      ),
    );
  }

  Future<void> _openDetails(HistoricalPlace place) async {
    final callback = widget.onPlaceSelected;

    if (callback != null) {
      callback(place);
      return;
    }

    // Details returns an action. Selection is updated here so the
    // 20-place limit remains controlled by the Explore page.
    final toggleRequested = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (detailsContext) => HistoricalPlaceDetailsScreen(
          placeId: place.id,
          initialPlace: place.toJson(),
          isAddedToTour: _selected.containsKey(place.id),
          onAddToTour: () {
            Navigator.of(detailsContext).pop(true);
          },
        ),
      ),
    );

    if (!mounted || toggleRequested != true) return;

    final wasSelected = _selected.containsKey(place.id);
    final changed = _togglePlace(place);

    if (changed) {
      _message(
        wasSelected
            ? '${place.name} removed from your tour selection.'
            : '${place.name} added to your tour selection.',
      );
    }
  }

  Future<void> _showFilters() async {
    String category = _category;
    String sort = _sort;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Filter places'),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: sort,
                      decoration: const InputDecoration(
                        labelText: 'Sort by',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Recommended',
                        'Name A–Z',
                        'Highest rated',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => sort = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || apply != true) return;

    setState(() {
      _category = category;
      _sort = sort;
    });

    _debounce?.cancel();
    await _load();
  }

  Widget _title(String text, {double size = 22}) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: _heading,
      ),
    );
  }

  Widget _image(HistoricalPlace place) {
    Widget fallback() {
      return Container(
        color: _surface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.landscape_outlined,
          color: _muted,
          size: 32,
        ),
      );
    }

    final asset = place.localImage;

    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => fallback(),
      );
    }

    if (place.imageUrl.isEmpty) return fallback();

    final uri = Uri.tryParse(place.imageUrl);
    if (uri == null) return fallback();

    final url = uri.hasScheme
        ? uri.toString()
        : Uri.parse('${ApiConfig.baseUrl}/')
        .resolve(place.imageUrl)
        .toString();

    final resolved = Uri.tryParse(url);

    if (resolved == null ||
        (resolved.scheme != 'http' && resolved.scheme != 'https')) {
      return fallback();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => fallback(),
    );
  }

  Widget _metadata(HistoricalPlace place) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (place.city.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 13,
                color: _primary,
              ),
              const SizedBox(width: 3),
              Text(
                place.city,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                ),
              ),
            ],
          ),
        if (place.rating != null &&
            place.rating! > 0 &&
            place.reviewCount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFE9A024),
              ),
              const SizedBox(width: 3),
              Text(
                '${place.rating!.toStringAsFixed(1)} '
                    '(${place.reviewCount})',
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Compact cards retain the existing 132px width and 92px image.
  // Measure their text so longer titles and larger text settings fit.
  double _popularCardsHeight() {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context).style;
    double tallest = 0;

    double textHeight(
        String value,
        TextStyle style, {
          required double maxWidth,
          int? maxLines,
        }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: defaultStyle.merge(style),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: maxWidth);

      final height = painter.height;
      painter.dispose();
      return height;
    }

    for (final place in _popular) {
      final titleHeight = textHeight(
        place.name,
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        maxWidth: 116,
        maxLines: 2,
      );

      double metadataHeight = 0;

      if (place.city.isNotEmpty) {
        final cityHeight = textHeight(
          place.city,
          const TextStyle(fontSize: 11, color: _muted),
          maxWidth: double.infinity,
        );
        metadataHeight = cityHeight > 13 ? cityHeight : 13;
      }

      if (place.rating != null &&
          place.rating! > 0 &&
          place.reviewCount > 0) {
        final ratingHeight = textHeight(
          '${place.rating!.toStringAsFixed(1)} '
              '(${place.reviewCount})',
          const TextStyle(fontSize: 11, color: _muted),
          maxWidth: double.infinity,
        );

        // Reserve a second metadata line when reviews are present.
        if (metadataHeight > 0) metadataHeight += 4;
        metadataHeight += ratingHeight > 16 ? ratingHeight : 16;
      }

      final cardHeight = 92 + 16 + titleHeight + 6 + metadataHeight + 14;
      if (cardHeight > tallest) tallest = cardHeight;
    }

    return tallest.ceilToDouble();
  }

  Widget _popularCard(HistoricalPlace place) {
    return SizedBox(
      width: 132,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _surface),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetails(place),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: _image(place),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _metadata(place),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeRow(HistoricalPlace place) {
    final selected = _selected.containsKey(place.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openDetails(place),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 94,
                height: 116,
                child: _image(place),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _heading,
                  ),
                ),
                const SizedBox(height: 5),
                _metadata(place),
                const SizedBox(height: 6),
                Text(
                  place.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton(
                      onPressed: () => _togglePlace(place),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        selected ? '✓ Added' : '+ Add to Tour',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _openDetails(place),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'View Details →',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllPopular() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _title('Popular places'),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _popular.length,
                    separatorBuilder: (_, index) =>
                    const Divider(height: 20),
                    itemBuilder: (_, index) {
                      final place = _popular[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: _image(place),
                          ),
                        ),
                        title: Text(place.name),
                        subtitle: Text(place.city),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openDetails(place);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 70),
        child: Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
              ),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final places = _sorted(
      _searching ? _results : _recommended,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_searching && _popular.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _title('Popular Searches', size: 20),
              ),
              TextButton(
                onPressed: _showAllPopular,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                ),
                child: const Text('See All →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _popularCardsHeight(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popular.length,
              separatorBuilder: (_, index) =>
              const SizedBox(width: 10),
              itemBuilder: (_, index) =>
                  _popularCard(_popular[index]),
            ),
          ),
          const SizedBox(height: 22),
        ],
        _title(
          _searching ? 'Search Results' : 'Recommended Places',
          size: 20,
        ),
        const SizedBox(height: 16),
        if (places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No places found. Try another search or category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else
          ...places.map(_placeRow),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.spa, color: _primary, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEYLON HERITAGE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _heading,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'EXPLORE · DISCOVER · PRESERVE',
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 1.2,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _searchChanged,
            onSubmitted: (_) {
              _debounce?.cancel();
              _load();
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search places, cities...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 21),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _debounce?.cancel();
                  _load();
                },
                icon: const Icon(Icons.close, size: 18),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _surface),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _surface),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _showFilters,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Filter'),
        ),
      ],
    );
  }

  void _navigate(int index) {
    switch (index) {
      case 0:
        if (widget.onHome != null) {
          widget.onHome!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          _message('Home navigation will be connected next.');
        }
        break;
      case 1:
        break;
      case 2:
        _openTours();
        break;
      case 3:
        if (widget.onCommunity != null) {
          widget.onCommunity!();
        } else {
          _message('Community will be connected next.');
        }
        break;
      case 4:
        _openProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        backgroundColor: Colors.white,
        indicatorColor: _surface,
        onDestinationSelected: _navigate,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Tours',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: () {
            _debounce?.cancel();
            return _load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 24),
                      _title('Explore Historical Places', size: 26),
                      const SizedBox(height: 6),
                      const Text(
                        'Search and discover Sri Lanka’s rich heritage',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _searchBar(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 5,
                        children: _categories.entries.map((entry) {
                          final selected = _category == entry.key;

                          return ChoiceChip(
                            label: Text(entry.value),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: _primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : _primary,
                            ),
                            onSelected: (_) =>
                                _changeCategory(entry.key),
                          );
                        }).toList(),
                      ),
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_selected.length} places selected',
                                  style: const TextStyle(
                                    color: _heading,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _openTours,
                                style: TextButton.styleFrom(
                                  foregroundColor: _primary,
                                ),
                                child: const Text('Plan Tour →'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _content(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}