import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/api_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
      throw const GoogleAuthException(
        'Google sign in is not configured. Add a web client ID.',
      );
    }

    try {
      await _ensureInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const GoogleAuthException(
          'Google sign in is not supported on this device.',
        );
      }

      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException(
          'Google did not return a login token. Check OAuth client setup.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      throw GoogleAuthException(_googleMessage(error));
    } on UnsupportedError {
      throw const GoogleAuthException(
        'Google sign in is not supported on this platform.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }

  String _googleMessage(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign in was cancelled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign in UI is not available on this device.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google sign in client configuration is incorrect. Check package name, SHA fingerprint and web client ID.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign in provider configuration is missing or incorrect.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A different Google account is already active. Sign out and try again.';
      case GoogleSignInExceptionCode.unknownError:
        return error.description ?? 'Google sign in failed.';
    }
  }
}
