import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_review.dart';
import '../models/tourism_place.dart';
import '../models/weather_forecast.dart';
import 'api_client.dart';

class TourismService {
  TourismService._();

  static final TourismService instance = TourismService._();
  final ApiClient _api = ApiClient.instance;
  final List<TourismPlace> _localFavorites = [];
  final Map<int, List<PlaceReview>> _localReviews = {};
  List<TourismPlace>? _sriLankaOsmCache;
  final Map<String, List<TourismPlace>> _nearbyOsmCache = {};
  final Map<String, (double, double)?> _osmSearchCenterCache = {};

  Future<(double, double)?> getOsmSearchCenter(String search) async {
    final term = search
        .trim()
        .replaceFirst(RegExp(r'[,\s]+sri lanka$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (term.length < 3) return null;
    final cacheKey = term.toLowerCase();
    if (_osmSearchCenterCache.containsKey(cacheKey)) {
      return _osmSearchCenterCache[cacheKey];
    }

    const bounds = '5.8,79.4,10.1,82.1';
    final escaped = RegExp.escape(term);
    final query =
        '''[out:json][timeout:25];
(
  nwr["name"~"${escaped}",i]($bounds);
  nwr["name:en"~"${escaped}",i]($bounds);
);
out center tags;''';
    final response = await http
        .get(
          Uri.https('overpass-api.de', '/api/interpreter', {'data': query}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      throw Exception('OpenStreetMap search returned ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? const [];
    final candidates = <({int priority, double lat, double lon})>[];
    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final tags = raw['tags'] as Map<String, dynamic>? ?? const {};
      final name = (tags['name'] ?? tags['name:en'] ?? '').toString();
      final normalizedName = name.toLowerCase();
      if (!normalizedName.contains(cacheKey) &&
          !cacheKey.contains(normalizedName)) {
        continue;
      }
      final coordinates = _osmCoordinates(raw);
      if (coordinates == null) continue;
      final placeType = tags['place']?.toString();
      final placePriority = switch (placeType) {
        'city' => 0,
        'town' => 1,
        'village' => 2,
        'suburb' => 3,
        _ when tags['boundary'] == 'administrative' => 4,
        _ => 5,
      };
      final priority = (normalizedName == cacheKey ? 0 : 10) + placePriority;
      candidates.add((
        priority: priority,
        lat: coordinates.$1,
        lon: coordinates.$2,
      ));
    }
    candidates.sort((a, b) => a.priority.compareTo(b.priority));
    final result = candidates.isEmpty
        ? null
        : (candidates.first.lat, candidates.first.lon);
    _osmSearchCenterCache[cacheKey] = result;
    return result;
  }

  Future<List<TourismPlace>> getOsmNearbyPlaces({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    final key =
        '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)},$radiusMeters';
    if (_nearbyOsmCache.containsKey(key)) {
      return List<TourismPlace>.of(_nearbyOsmCache[key]!);
    }
    final query =
        '''[out:json][timeout:35];
(
  nwr(around:$radiusMeters,$latitude,$longitude)["historic"];
  nwr(around:$radiusMeters,$latitude,$longitude)["tourism"~"attraction|museum|artwork|viewpoint|hotel|guest_house|hostel"];
  nwr(around:$radiusMeters,$latitude,$longitude)["amenity"~"restaurant|cafe|fast_food|food_court"];
  nwr(around:$radiusMeters,$latitude,$longitude)["shop"];
);
out center tags;''';
    final places = await _queryOsmPlaces(query);
    _nearbyOsmCache[key] = places;
    return List<TourismPlace>.of(places);
  }

  Future<List<TourismPlace>> getSriLankaPlaces({
    String category = 'All',
  }) async {
    try {
      _sriLankaOsmCache ??= await _loadSriLankaOsmPlaces();
      final selected = category == 'All' ? null : _categoryValue(category);
      return _sriLankaOsmCache!
          .where(
            (place) =>
                selected == null ||
                place.category == selected ||
                (category == 'Historical' && place.category == 'MUSEUM'),
          )
          .toList();
    } catch (_) {
      // Keep the map usable if the public OSM query service is unavailable.
      return getPlaces(category: category);
    }
  }

  Future<List<TourismPlace>> _loadSriLankaOsmPlaces() async {
    const bounds = '5.8,79.4,10.1,82.1';
    const query =
        '''[out:json][timeout:60];
(
  nwr["historic"]($bounds);
  nwr["tourism"~"attraction|museum|artwork|viewpoint|hotel|guest_house|hostel"]($bounds);
  nwr["amenity"~"restaurant|cafe|fast_food|food_court"]($bounds);
  nwr["shop"]($bounds);
);
out center tags;''';
    return _queryOsmPlaces(query);
  }

  Future<List<TourismPlace>> _queryOsmPlaces(String query) async {
    final response = await http
        .get(
          Uri.https('overpass-api.de', '/api/interpreter', {'data': query}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 75));
    if (response.statusCode != 200) {
      throw Exception('OpenStreetMap query returned ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? const [];
    final unique = <String, TourismPlace>{};
    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final tags = raw['tags'] as Map<String, dynamic>? ?? const {};
      final name = (tags['name'] ?? tags['name:en'] ?? '').toString().trim();
      final coordinates = _osmCoordinates(raw);
      final category = _osmCategory(tags);
      final osmId = (raw['id'] as num?)?.toInt();
      if (name.isEmpty ||
          coordinates == null ||
          category == null ||
          osmId == null) {
        continue;
      }
      final type = raw['type']?.toString() ?? 'place';
      unique['$type:$osmId'] = TourismPlace(
        id: -osmId,
        slug: 'osm-$type-$osmId',
        name: name,
        category: category,
        description:
            (tags['description'] ??
                    tags['historic'] ??
                    tags['tourism'] ??
                    tags['amenity'] ??
                    tags['shop'] ??
                    'OpenStreetMap place in Sri Lanka')
                .toString(),
        address: _osmAddress(tags),
        city:
            (tags['addr:city'] ??
                    tags['addr:town'] ??
                    tags['addr:village'] ??
                    'Sri Lanka')
                .toString(),
        province: (tags['addr:state'] ?? tags['addr:province'] ?? '')
            .toString(),
        rating: 0,
        reviewCount: 0,
        distanceMeters: 0,
        isOpen: true,
        openingHours: tags['opening_hours']?.toString(),
        imageUrl: _osmImageUrl(tags),
        latitude: coordinates.$1,
        longitude: coordinates.$2,
      );
    }
    return unique.values.toList();
  }

  (double, double)? _osmCoordinates(Map<String, dynamic> element) {
    final center = element['center'] as Map<String, dynamic>?;
    final lat = element['lat'] ?? center?['lat'];
    final lon = element['lon'] ?? center?['lon'];
    if (lat is num && lon is num) return (lat.toDouble(), lon.toDouble());
    return null;
  }

  String? _osmImageUrl(Map<String, dynamic> tags) {
    final directImage = tags['image']?.toString().trim();
    if (directImage != null && directImage.isNotEmpty) {
      final uri = Uri.tryParse(directImage);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty &&
          uri.host != 'commons.wikimedia.org') {
        return uri.toString();
      }
      final filePrefix = '/wiki/File:';
      if (uri?.host == 'commons.wikimedia.org' &&
          uri!.path.startsWith(filePrefix)) {
        final filename = Uri.decodeComponent(
          uri.path.substring(filePrefix.length),
        );
        return _commonsFileUrl(filename);
      }
      if (uri?.host == 'commons.wikimedia.org' &&
          uri!.path.startsWith('/wiki/Special:FilePath/')) {
        return uri.toString();
      }
    }

    final commons = (tags['wikimedia_commons'] ?? tags['image'])
        ?.toString()
        .trim();
    if (commons == null || !commons.startsWith('File:')) return null;
    return _commonsFileUrl(commons.substring('File:'.length).trim());
  }

  String? _commonsFileUrl(String filename) {
    if (filename.isEmpty) return null;
    return Uri.https(
      'commons.wikimedia.org',
      '/wiki/Special:FilePath/$filename',
      {'width': '640'},
    ).toString();
  }

  String? _osmCategory(Map<String, dynamic> tags) {
    if (tags.containsKey('shop')) return 'SHOPS';
    final amenity = tags['amenity']?.toString();
    if (const {
      'restaurant',
      'cafe',
      'fast_food',
      'food_court',
    }.contains(amenity)) {
      return 'RESTAURANTS';
    }
    final tourism = tags['tourism']?.toString();
    if (const {'hotel', 'guest_house', 'hostel'}.contains(tourism))
      return 'HOTELS';
    if (tourism == 'museum') return 'MUSEUM';
    if (tags.containsKey('historic') ||
        const {'attraction', 'artwork', 'viewpoint'}.contains(tourism)) {
      return 'HERITAGE';
    }
    return null;
  }

  String _osmAddress(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Sri Lanka' : parts.join(', ');
  }

  Future<List<TourismPlace>> getPlaces({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    int radiusMeters = 5000,
  }) async {
    final query = <String, String>{};
    if (category != null && category != 'All') {
      query['category'] = _categoryValue(category);
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (latitude != null && longitude != null) {
      query['latitude'] = latitude.toStringAsFixed(6);
      query['longitude'] = longitude.toStringAsFixed(6);
      query['radiusMeters'] = radiusMeters.toString();
    }
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    try {
      final places = _places(
        await _api.get('/api/tourism/places$suffix', authenticated: false),
      );
      return places;
    } catch (_) {
      // Keep the nearby and map screens usable while the tourism API is offline.
      final normalizedCategory = category == null || category == 'All'
          ? null
          : _categoryValue(category);
      final normalizedSearch = search?.trim().toLowerCase() ?? '';
      return _samplePlaces.where((place) {
        final categoryMatches =
            normalizedCategory == null || place.category == normalizedCategory;
        final searchMatches =
            normalizedSearch.isEmpty ||
            '${place.name} ${place.category} ${place.city}'
                .toLowerCase()
                .contains(normalizedSearch);
        return categoryMatches && searchMatches;
      }).toList();
    }
  }

  Future<TourismPlace> getPlace(int id) async => TourismPlace.fromJson(
    await _api.get('/api/tourism/places/$id', authenticated: false)
        as Map<String, dynamic>,
  );

  Future<List<TourismPlace>> getRecommendations(String sort) async {
    try {
      return _places(
        await _api.get(
          '/api/tourism/places/recommended?sort=${Uri.encodeQueryComponent(sort)}',
          authenticated: false,
        ),
      );
    } catch (_) {
      // Keep the recommendations design usable while the API is offline.
      final places = List<TourismPlace>.of(_recommendedPlaces);
      if (sort == 'popular') {
        places.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      } else if (sort == 'trending') {
        places.sort((a, b) => b.rating.compareTo(a.rating));
      }
      return places;
    }
  }

  Future<List<PlaceReview>> getReviews(
    int placeId, {
    String sort = 'latest',
  }) async {
    late List<PlaceReview> reviews;
    try {
      final response =
          await _api.get(
                '/api/tourism/places/$placeId/reviews?sort=${Uri.encodeQueryComponent(sort)}',
                authenticated: false,
              )
              as List<dynamic>;
      reviews = response
          .map((item) => PlaceReview.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Show the review screen preview while the reviews API is unavailable.
      reviews = List<PlaceReview>.of(_sampleReviews);
    }

    final merged = <int, PlaceReview>{
      for (final review in reviews) review.id: review,
    };
    for (final review in _localReviews[placeId] ?? const <PlaceReview>[]) {
      merged.putIfAbsent(review.id, () => review);
    }
    final result = merged.values.toList();
    if (sort == 'highest-rated') {
      result.sort((a, b) {
        final ratingOrder = b.rating.compareTo(a.rating);
        if (ratingOrder != 0) return ratingOrder;
        return _reviewTime(b).compareTo(_reviewTime(a));
      });
    } else {
      result.sort((a, b) => _reviewTime(b).compareTo(_reviewTime(a)));
    }
    return result;
  }

  Future<PlaceRatingSummary> getRatingSummary(int placeId) async =>
      PlaceRatingSummary.fromJson(
        await _api.get(
              '/api/tourism/places/$placeId/ratings',
              authenticated: false,
            )
            as Map<String, dynamic>,
      );

  Future<PlaceReview> submitReview({
    required int placeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final review = PlaceReview.fromJson(
        await _api.post(
              '/api/tourism/places/$placeId/reviews',
              body: {'rating': rating, 'comment': comment},
            )
            as Map<String, dynamic>,
      );
      _rememberReview(placeId, review);
      return review;
    } catch (_) {
      final now = DateTime.now().toUtc();
      final review = PlaceReview(
        id: -now.microsecondsSinceEpoch,
        authorName: 'You',
        authorLabel: 'Your review',
        rating: rating,
        comment: comment,
        createdAt: now.toIso8601String(),
      );
      _rememberReview(placeId, review);
      return review;
    }
  }

  Future<PlaceReview> updateReview({
    required int placeId,
    required PlaceReview review,
    required int rating,
    required String comment,
  }) async {
    if (review.id > 0) {
      await _api.put('/api/tourism/places/$placeId/reviews/${review.id}', body: {
        'rating': rating,
        'comment': comment,
      });
    }
    final updated = PlaceReview(
      id: review.id,
      authorName: review.authorName,
      authorLabel: review.authorLabel,
      rating: rating,
      comment: comment,
      createdAt: review.createdAt,
    );
    _rememberReview(placeId, updated);
    return updated;
  }

  Future<void> deleteReview(int placeId, PlaceReview review) async {
    if (review.id > 0) {
      await _api.delete('/api/tourism/places/$placeId/reviews/${review.id}');
    }
    _localReviews[placeId]?.removeWhere((item) => item.id == review.id);
  }
  void _rememberReview(int placeId, PlaceReview review) {
    final reviews = _localReviews.putIfAbsent(placeId, () => []);
    final existingIndex = reviews.indexWhere((item) => item.id == review.id);
    if (existingIndex == -1) {
      reviews.insert(0, review);
    } else {
      reviews[existingIndex] = review;
    }
  }

  int _reviewTime(PlaceReview review) =>
      DateTime.tryParse(review.createdAt)?.millisecondsSinceEpoch ?? 0;

  bool isFavorite(int placeId) =>
      _localFavorites.any((place) => place.id == placeId);

  Future<List<TourismPlace>> getFavorites() async {
    try {
      final remote = _places(await _api.get('/api/users/me/favourites'));
      final merged = <int, TourismPlace>{
        for (final place in remote) place.id: place,
        for (final place in _localFavorites) place.id: place,
      };
      return merged.values.toList();
    } catch (_) {
      // Keep locally saved places visible when the account API is unavailable.
      return List<TourismPlace>.of(_localFavorites);
    }
  }

  Future<TourismPlace> addFavorite(int placeId, {TourismPlace? place}) async {
    try {
      final result = TourismPlace.fromJson(
        await _api.put('/api/users/me/favourites/$placeId')
            as Map<String, dynamic>,
      );
      _rememberFavorite(result);
      return result;
    } catch (_) {
      final localPlace = place ?? _findPlace(placeId);
      if (localPlace == null) rethrow;
      _rememberFavorite(localPlace);
      return localPlace;
    }
  }

  Future<void> removeFavorite(int placeId) async {
    _localFavorites.removeWhere((place) => place.id == placeId);
    try {
      await _api.delete('/api/users/me/favourites/$placeId');
    } catch (_) {
      // Local removal still works while the account API is unavailable.
    }
  }

  void _rememberFavorite(TourismPlace place) {
    _localFavorites.removeWhere((item) => item.id == place.id);
    _localFavorites.add(place);
  }

  TourismPlace? _findPlace(int id) {
    for (final place in [..._samplePlaces, ..._recommendedPlaces]) {
      if (place.id == id) return place;
    }
    return null;
  }

  Future<WeatherForecast> getWeather({String location = 'Galle'}) async {
    try {
      return WeatherForecast.fromJson(
        await _api.get(
              '/api/weather?location=${Uri.encodeQueryComponent(location)}',
              authenticated: false,
            )
            as Map<String, dynamic>,
      );
    } catch (_) {
      // Preview forecast matching the supplied Galle screen design.
      return WeatherForecast(
        location: location,
        province: 'Southern Province',
        temperatureCelsius: 28,
        condition: 'Partly Cloudy Day',
        humidityPercent: 78,
        windKmh: 12,
        uvIndex: 'Moderate',
        demoData: true,
        hourly: const [
          HourlyForecast('Now', 28, 'Partly Cloudy'),
          HourlyForecast('10 AM', 27, 'Sunny'),
          HourlyForecast('11 AM', 28, 'Sunny'),
          HourlyForecast('12 PM', 27, 'Partly Cloudy'),
          HourlyForecast('1 PM', 28, 'Sunny'),
        ],
        fiveDay: const [
          DailyForecast('Today', 28, 24, 'Partly Cloudy'),
          DailyForecast('Tomorrow', 29, 25, 'Sunny Intervals'),
          DailyForecast('Wed', 26, 23, 'Heavy Rain'),
          DailyForecast('Thu', 27, 24, 'Light Showers'),
          DailyForecast('Fri', 28, 24, 'Partly Cloudy'),
        ],
      );
    }
  }

  List<TourismPlace> _places(dynamic data) => (data as List<dynamic>)
      .map((item) => TourismPlace.fromJson(item as Map<String, dynamic>))
      .toList();

  static const _samplePlaces = <TourismPlace>[
    TourismPlace(
      id: 1,
      slug: 'fort-paradise-restaurant',
      name: 'Fort Paradise Restaurant',
      category: 'RESTAURANTS',
      description: 'Seafood and Sri Lankan cuisine near Galle Fort.',
      address: 'Galle Fort',
      city: 'Galle',
      province: 'Southern Province',
      rating: 4.2,
      reviewCount: 124,
      distanceMeters: 250,
      isOpen: true,
      openingHours: '8:00 AM - 10:00 PM',
      priceRange: 'LKR 1,500 - 3,000',
      latitude: 6.0260,
      longitude: 80.2170,
    ),
    TourismPlace(
      id: 2,
      slug: 'heritage-hotel',
      name: 'The Heritage Hotel',
      category: 'HOTELS',
      description: 'A quiet heritage stay in Galle.',
      address: 'Church Street',
      city: 'Galle',
      province: 'Southern Province',
      rating: 4.4,
      reviewCount: 86,
      distanceMeters: 400,
      isOpen: true,
      latitude: 6.0270,
      longitude: 80.2180,
    ),
    TourismPlace(
      id: 3,
      slug: 'galle-heritage-cafe',
      name: 'Galle Heritage Cafe',
      category: 'RESTAURANTS',
      description: 'Coffee and desserts in the old town.',
      address: 'Lighthouse Street',
      city: 'Galle',
      province: 'Southern Province',
      rating: 4.5,
      reviewCount: 52,
      distanceMeters: 550,
      isOpen: false,
      latitude: 6.0280,
      longitude: 80.2190,
    ),
    TourismPlace(
      id: 4,
      slug: 'galle-fort',
      name: 'Galle Fort',
      category: 'HERITAGE',
      description: 'UNESCO World Heritage Site in Galle.',
      address: 'Galle Fort',
      city: 'Galle',
      province: 'Southern Province',
      rating: 4.8,
      reviewCount: 318,
      distanceMeters: 350,
      isOpen: true,
      latitude: 6.0260,
      longitude: 80.2170,
    ),
  ];

  static const _sampleReviews = <PlaceReview>[
    PlaceReview(
      id: -1,
      authorName: 'Sarah M.',
      authorLabel: 'Verified Local Guide',
      rating: 5,
      comment:
          'A useful and interesting place to visit. There are plenty of historical details, museums and cozy cafes here.',
      createdAt: '2026-10-08T09:00:00Z',
    ),
    PlaceReview(
      id: -2,
      authorName: 'Kavindu P.',
      authorLabel: 'Verified Local Guide',
      rating: 5,
      comment:
          'Stunning heritage views. Recommend visiting near the evening sunset to catch gorgeous beach photographs.',
      createdAt: '2026-10-07T09:00:00Z',
    ),
    PlaceReview(
      id: -3,
      authorName: 'Sandhya R.',
      authorLabel: 'Verified Local Guide',
      rating: 5,
      comment:
          'Loved the quiet colonial pathways and the museum relics. Best experienced with local walking tours.',
      createdAt: '2026-10-06T09:00:00Z',
    ),
  ];

  static const _recommendedPlaces = <TourismPlace>[
    TourismPlace(
      id: 4,
      slug: 'galle-fort',
      name: 'Galle Fort',
      category: 'HISTORICAL',
      description: 'UNESCO World Heritage Site in Galle.',
      address: 'Galle Fort',
      city: 'Galle',
      province: 'Southern Province',
      rating: 4.8,
      reviewCount: 318,
      distanceMeters: 350,
      isOpen: true,
      latitude: 6.0260,
      longitude: 80.2170,
    ),
    TourismPlace(
      id: 5,
      slug: 'sigiriya',
      name: 'Sigiriya',
      category: 'HISTORICAL',
      description: 'Ancient rock fortress and UNESCO World Heritage Site.',
      address: 'Sigiriya Rock Fortress',
      city: 'Sigiriya',
      province: 'Central Province',
      rating: 4.8,
      reviewCount: 864,
      distanceMeters: 245000,
      isOpen: true,
      latitude: 7.9570,
      longitude: 80.7603,
    ),
    TourismPlace(
      id: 6,
      slug: 'white-temple',
      name: 'White Temple',
      category: 'CULTURAL HERITAGE',
      description: 'The Temple of the Tooth, a revered temple in Kandy.',
      address: 'Sri Dalada Veediya',
      city: 'Kandy',
      province: 'Central Province',
      rating: 4.7,
      reviewCount: 512,
      distanceMeters: 175000,
      isOpen: true,
      latitude: 7.2936,
      longitude: 80.6413,
    ),
    TourismPlace(
      id: 7,
      slug: 'national-museum-colombo',
      name: 'National Museum, Colombo',
      category: 'MUSEUM',
      description:
          'Explore Sri Lankan history, archaeology, and cultural artifacts.',
      address: 'Sir Marcus Fernando Mawatha',
      city: 'Colombo',
      province: 'Western Province',
      rating: 4.6,
      reviewCount: 620,
      distanceMeters: 120000,
      isOpen: true,
      latitude: 6.9104,
      longitude: 79.8612,
    ),
  ];

  String _categoryValue(String value) => switch (value.toLowerCase()) {
    'restaurant' || 'restaurants' => 'RESTAURANTS',
    'hotel' || 'hotels' => 'HOTELS',
    'shop' || 'shops' => 'SHOPS',
    'historical' || 'cultural heritage' => 'HERITAGE',
    _ => value.toUpperCase(),
  };
}
