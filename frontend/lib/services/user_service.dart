import '../models/user_profile.dart';
import 'api_client.dart';
import 'token_store.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();
  final ApiClient _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final data = await _api.get('/api/users/me') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    final data =
        await _api.put(
              '/api/users/me',
              body: {
                'firstName': firstName,
                'lastName': lastName,
                'phone': phone,
                'address': address,
              },
            )
            as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data =
        await _api.put(
              '/api/users/me/password',
              body: {
                'currentPassword': currentPassword,
                'newPassword': newPassword,
                'confirmPassword': confirmPassword,
              },
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Password changed';
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/users/logout');
    } finally {
      await TokenStore.clear();
    }
  }

  Future<String> deleteAccount(String currentPassword) async {
    final data =
        await _api.delete(
              '/api/users/me',
              body: {'currentPassword': currentPassword},
            )
            as Map<String, dynamic>;
    await TokenStore.clear();
    return data['message'] as String? ?? 'Account deleted';
  }
}
