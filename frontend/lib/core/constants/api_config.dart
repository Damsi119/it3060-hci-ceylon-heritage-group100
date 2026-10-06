import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static final String baseUrl =
      const String.fromEnvironment('API_BASE_URL').trim().isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL').trim()
      : kIsWeb
      ? 'http://localhost:8081'
      : 'http://10.0.2.2:8081';

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
