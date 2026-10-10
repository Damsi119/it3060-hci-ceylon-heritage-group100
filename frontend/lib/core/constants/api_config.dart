import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return 'http://$host:8081';
    }

    return 'http://10.0.2.2:8081';
  }

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '668109690310-q3cmtd9olaptsnp7q8snphdqemcrncis.apps.googleusercontent.com',
  );

  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
}
