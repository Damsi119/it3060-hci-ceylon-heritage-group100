import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/tourism_place.dart';

class PlacePhoto {
  const PlacePhoto({
    required this.imageUrl,
    this.sourceUrl,
    this.attribution,
  });

  final String imageUrl;
  final String? sourceUrl;
  final String? attribution;
}

/// Finds Google Places photos first, then OSM/Wikimedia photos as a fallback.
class PlacePhotoService {
  PlacePhotoService._();

  static final instance = PlacePhotoService._();
  final Map<String, Future<List<PlacePhoto>>> _cache = {};

  Future<PlacePhoto?> getCoverPhoto(TourismPlace place) async {
    if (ApiConfig.googlePlacesApiKey.isNotEmpty) {
      final photos = await getPhotos(place);
      if (photos.isNotEmpty) return photos.first;
    }
    final taggedImage = _validHttpUrl(place.imageUrl);
    if (taggedImage != null) {
      return PlacePhoto(
        imageUrl: taggedImage,
        sourceUrl: taggedImage,
        attribution: 'Photo linked from OpenStreetMap place data',
      );
    }
    final photos = await getPhotos(place);
    return photos.isEmpty ? null : photos.first;
  }

  Future<List<PlacePhoto>> getPhotos(TourismPlace place) {
    if (ApiConfig.googlePlacesApiKey.isNotEmpty) {
      // Google photo references and media URLs are transient and must not be
      // persisted in the service's cache.
      return _loadPhotos(place);
    }
    final key = [
      place.slug,
      place.name,
      place.imageUrl ?? '',
      place.latitude?.toString() ?? '',
      place.longitude?.toString() ?? '',
    ].join('|').toLowerCase();
    return _cache.putIfAbsent(key, () => _loadPhotos(place));
  }

  Future<List<PlacePhoto>> _loadPhotos(TourismPlace place) async {
    if (ApiConfig.googlePlacesApiKey.isNotEmpty) {
      try {
        final googlePhotos = await _googlePhotos(place);
        if (googlePhotos.isNotEmpty) return googlePhotos;
      } catch (_) {
        // Keep place cards usable if Google Places is unavailable.
      }
    }

    final photos = <PlacePhoto>[];
    final taggedImage = _validHttpUrl(place.imageUrl);
    if (taggedImage != null) {
      photos.add(
        PlacePhoto(
          imageUrl: taggedImage,
          sourceUrl: taggedImage,
          attribution: 'Photo linked from OpenStreetMap place data',
        ),
      );
    }

    if (place.latitude != null && place.longitude != null) {
      try {
        photos.addAll(await _nearbyCommons(place));
      } catch (_) {
        // Fall back to a Commons search by the place's name.
      }
    }
    if (photos.length < 3) {
      try {
        final commonsPhotos = await _searchCommons(place);
        photos.addAll(commonsPhotos);
      } catch (_) {
        // A place without a matched photo is shown with its category icon.
      }
    }

    final unique = <String, PlacePhoto>{};
    for (final photo in photos) {
      unique.putIfAbsent(photo.imageUrl, () => photo);
      if (unique.length == 3) break;
    }
    return unique.values.toList();
  }

  Future<List<PlacePhoto>> _googlePhotos(TourismPlace place) async {
    final query = [place.name.trim(), place.city.trim(), 'Sri Lanka']
        .where((part) => part.isNotEmpty)
        .join(', ');
    final request = <String, dynamic>{
      'textQuery': query,
      'regionCode': 'LK',
      'maxResultCount': 3,
      if (place.latitude != null && place.longitude != null)
        'locationBias': {
          'circle': {
            'center': {
              'latitude': place.latitude,
              'longitude': place.longitude,
            },
            'radius': 3000,
          },
        },
    };
    final response = await http
        .post(
          Uri.https('places.googleapis.com', '/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': ApiConfig.googlePlacesApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.location,places.photos',
          },
          body: jsonEncode(request),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) return const [];
    final places = payload['places'];
    if (places is! List) return const [];
    final photos = <PlacePhoto>[];
    for (final candidate in places) {
      if (candidate is! Map<String, dynamic>) continue;
      final googleName = candidate['displayName'];
      final googlePlaceName = googleName is Map
          ? googleName['text']?.toString() ?? ''
          : '';
      if (!_isSamePlace(place.name, googlePlaceName)) continue;
      final photoItems = candidate['photos'];
      if (photoItems is! List) continue;
      for (final photo in photoItems.take(3)) {
        if (photo is! Map<String, dynamic>) continue;
        final photoName = photo['name']?.toString();
        if (photoName == null || photoName.isEmpty) continue;
        final mediaUri = Uri.https(
          'places.googleapis.com',
          '/v1/$photoName/media',
          {'maxWidthPx': '900', 'maxHeightPx': '700', 'skipHttpRedirect': 'true'},
        );
        final mediaResponse = await http
            .get(mediaUri, headers: {'X-Goog-Api-Key': ApiConfig.googlePlacesApiKey})
            .timeout(const Duration(seconds: 10));
        if (mediaResponse.statusCode != 200) continue;
        final media = jsonDecode(mediaResponse.body);
        if (media is! Map<String, dynamic>) continue;
        final imageUrl = _validHttpUrl(media['photoUri']?.toString());
        if (imageUrl == null) continue;
        final authors = photo['authorAttributions'];
        final attribution = authors is List
            ? authors
                .whereType<Map>()
                .map((author) => author['displayName']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .join(', ')
            : '';
        photos.add(PlacePhoto(
          imageUrl: imageUrl,
          sourceUrl: 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(googlePlaceName)}',
          attribution: attribution.isEmpty ? 'Google Maps' : '$attribution · Google Maps',
        ));
      }
      if (photos.isNotEmpty) break;
    }
    return photos;
  }

  bool _isSamePlace(String requested, String found) {
    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final wanted = normalize(requested);
    final actual = normalize(found);
    return wanted.isNotEmpty &&
        actual.isNotEmpty &&
        (actual == wanted || actual.contains(wanted) || wanted.contains(actual));
  }

  Future<List<PlacePhoto>> _searchCommons(TourismPlace place) async {
    final terms = [
      place.name.trim(),
      if (place.city.trim().isNotEmpty && place.city != 'Sri Lanka')
        place.city.trim(),
      'Sri Lanka',
    ].join(' ');
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': terms,
      'gsrnamespace': '6',
      'gsrlimit': '8',
      'prop': 'imageinfo',
      'iiprop': 'url|extmetadata',
      'iiurlwidth': '640',
      'format': 'json',
      'origin': '*',
    });
    return _requestPhotos(uri);
  }

  Future<List<PlacePhoto>> _nearbyCommons(TourismPlace place) async {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'geosearch',
      'ggsprimary': 'all',
      'ggsnamespace': '6',
      'ggsradius': '1000',
      'ggscoord': '${place.latitude}|${place.longitude}',
      'ggslimit': '8',
      'prop': 'imageinfo',
      'iiprop': 'url|extmetadata',
      'iiurlwidth': '640',
      'format': 'json',
      'origin': '*',
    });
    return _requestPhotos(uri);
  }

  Future<List<PlacePhoto>> _requestPhotos(Uri uri) async {
    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const [];

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) return const [];
    final query = payload['query'];
    if (query is! Map<String, dynamic>) return const [];
    final pages = query['pages'];
    if (pages is! Map<String, dynamic>) return const [];

    final photos = <PlacePhoto>[];
    for (final value in pages.values) {
      if (value is! Map<String, dynamic>) continue;
      final infoList = value['imageinfo'];
      if (infoList is! List || infoList.isEmpty || infoList.first is! Map) {
        continue;
      }
      final info = infoList.first as Map<String, dynamic>;
      final imageUrl = _validHttpUrl(
        info['thumburl']?.toString() ?? info['url']?.toString(),
      );
      if (imageUrl == null) continue;

      final metadata = info['extmetadata'] as Map<String, dynamic>? ?? const {};
      final artist = _plainMetadata(metadata['Artist']);
      final license = _plainMetadata(metadata['LicenseShortName']);
      final attribution = [artist, license]
          .where((part) => part != null && part.isNotEmpty)
          .join(' - ');
      photos.add(
        PlacePhoto(
          imageUrl: imageUrl,
          sourceUrl: _validHttpUrl(info['descriptionurl']?.toString()),
          attribution: attribution.isEmpty ? 'Wikimedia Commons' : attribution,
        ),
      );
    }
    return photos;
  }

  String? _plainMetadata(dynamic value) {
    if (value is! Map) return null;
    final raw = value['value']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _validHttpUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }
}
