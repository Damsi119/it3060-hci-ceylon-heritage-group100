import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/api_config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      serverClientId: ApiConfig.googleServerClientId,
    );
    _initialized = true;
  }

  Future<String> getIdToken() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      throw Exception('Google Server Client ID is not configured');
    }

    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception('Google sign in is not supported on this platform');
    }

    final account = await _googleSignIn.authenticate(
      scopeHint: const ['email', 'profile'],
    );
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}
