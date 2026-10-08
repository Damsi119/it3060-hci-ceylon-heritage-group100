import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore._();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() => _read(_accessKey);
  static Future<String?> getRefreshToken() => _read(_refreshKey);

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Browser secure-storage keys can become unreadable if browser site data
      // is cleared or the app origin changes. Discard that stale session so
      // the app can return the user to login instead of failing every request.
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}
