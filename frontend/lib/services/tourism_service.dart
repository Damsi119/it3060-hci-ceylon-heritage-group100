import '../models/place_review.dart';
import '../models/tourism_place.dart';
import '../models/weather_forecast.dart';
import 'api_client.dart';

class TourismService {
  TourismService._();

  static final TourismService instance = TourismService._();
  final ApiClient _api = ApiClient.instance;

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
    return _places(await _api.get('/api/places$suffix', authenticated: false));
  }

  Future<TourismPlace> getPlace(int id) async => TourismPlace.fromJson(
    await _api.get('/api/places/$id', authenticated: false)
        as Map<String, dynamic>,
  );

  Future<List<TourismPlace>> getRecommendations(String sort) async => _places(
    await _api.get(
      '/api/places/recommended?sort=${Uri.encodeQueryComponent(sort)}',
      authenticated: false,
    ),
  );

  Future<List<PlaceReview>> getReviews(
    int placeId, {
    String sort = 'latest',
  }) async {
    final response =
        await _api.get(
              '/api/places/$placeId/reviews?sort=${Uri.encodeQueryComponent(sort)}',
              authenticated: false,
            )
            as List<dynamic>;
    return response
        .map((item) => PlaceReview.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlaceRatingSummary> getRatingSummary(int placeId) async =>
      PlaceRatingSummary.fromJson(
        await _api.get('/api/places/$placeId/ratings', authenticated: false)
            as Map<String, dynamic>,
      );

  Future<PlaceReview> submitReview({
    required int placeId,
    required int rating,
    required String comment,
  }) async => PlaceReview.fromJson(
    await _api.post(
          '/api/places/$placeId/reviews',
          body: {'rating': rating, 'comment': comment},
        )
        as Map<String, dynamic>,
  );

  Future<List<TourismPlace>> getFavorites() async =>
      _places(await _api.get('/api/users/me/favourites'));

  Future<TourismPlace> addFavorite(int placeId) async => TourismPlace.fromJson(
    await _api.put('/api/users/me/favourites/$placeId') as Map<String, dynamic>,
  );

  Future<void> removeFavorite(int placeId) async {
    await _api.delete('/api/users/me/favourites/$placeId');
  }

  Future<WeatherForecast> getWeather({String location = 'Galle'}) async =>
      WeatherForecast.fromJson(
        await _api.get(
              '/api/weather?location=${Uri.encodeQueryComponent(location)}',
              authenticated: false,
            )
            as Map<String, dynamic>,
      );

  List<TourismPlace> _places(dynamic data) => (data as List<dynamic>)
      .map((item) => TourismPlace.fromJson(item as Map<String, dynamic>))
      .toList();

  String _categoryValue(String value) => switch (value.toLowerCase()) {
    'restaurant' || 'restaurants' => 'RESTAURANTS',
    'hotel' || 'hotels' => 'HOTELS',
    'shop' || 'shops' => 'SHOPS',
    'historical' || 'cultural heritage' => 'HERITAGE',
    _ => value.toUpperCase(),
  };
}
