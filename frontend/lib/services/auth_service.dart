import '../models/auth_response.dart';
import 'api_client.dart';
import 'token_store.dart';

class RegisterResult {
  const RegisterResult({
    required this.message,
    required this.verificationRequired,
  });

  final String message;
  final bool verificationRequired;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final ApiClient _api = ApiClient.instance;

  Future<RegisterResult> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
    String? address,
  }) async {
    final data =
        await _api.post(
              '/api/auth/register',
              authenticated: false,
              body: {
                'username': username,
                'email': email,
                'phone': phone,
                'password': password,
                'confirmPassword': confirmPassword,
                'firstName': firstName,
                'lastName': lastName,
                'address': address,
                'role': 'TOURIST',
              },
            )
            as Map<String, dynamic>;

    return RegisterResult(
      message: data['message'] as String? ?? 'Registration successful',
      verificationRequired: data['verificationRequired'] as bool? ?? true,
    );
  }

  Future<String> verifyEmail(String email, String code) async {
    final data =
        await _api.post(
              '/api/auth/verify-email',
              authenticated: false,
              body: {'email': email, 'code': code},
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Email verified';
  }

  Future<String> resendEmailOtp(String email) async {
    final data =
        await _api.post(
              '/api/auth/resend-otp',
              authenticated: false,
              body: {'email': email},
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Verification code sent';
  }

  Future<AuthResponse> login(String identifier, String password) async {
    final data =
        await _api.post(
              '/api/auth/login',
              authenticated: false,
              body: {'identifier': identifier, 'password': password},
            )
            as Map<String, dynamic>;
    final response = AuthResponse.fromJson(data);
    await TokenStore.saveTokens(response.accessToken, response.refreshToken);
    return response;
  }

  Future<AuthResponse> googleLogin(String idToken) async {
    final data =
        await _api.post(
              '/api/auth/google',
              authenticated: false,
              body: {'idToken': idToken, 'role': 'TOURIST'},
            )
            as Map<String, dynamic>;
    final response = AuthResponse.fromJson(data);
    await TokenStore.saveTokens(response.accessToken, response.refreshToken);
    return response;
  }

  Future<String> requestPasswordReset({
    String? username,
    String? email,
    String? phone,
  }) async {
    final data =
        await _api.post(
              '/api/auth/password/forgot',
              authenticated: false,
              body: {
                'username': _nullIfBlank(username),
                'email': _nullIfBlank(email),
                'phone': _nullIfBlank(phone),
              },
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Reset code sent';
  }

  Future<String> verifyPasswordResetOtp(String email, String code) async {
    final data =
        await _api.post(
              '/api/auth/password/verify',
              authenticated: false,
              body: {'email': email, 'code': code},
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Code verified';
  }

  Future<String> resendPasswordResetOtp(String email) async {
    final data =
        await _api.post(
              '/api/auth/password/resend',
              authenticated: false,
              body: {'email': email},
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'New reset code sent';
  }

  Future<String> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data =
        await _api.post(
              '/api/auth/password/reset',
              authenticated: false,
              body: {
                'email': email,
                'newPassword': newPassword,
                'confirmPassword': confirmPassword,
              },
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Password reset successfully';
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
