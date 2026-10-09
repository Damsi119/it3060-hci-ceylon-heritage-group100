import '../models/user_profile.dart';
import 'api_client.dart';

class AdminUserService {
  AdminUserService._();

  static final AdminUserService instance = AdminUserService._();
  final ApiClient _api = ApiClient.instance;

  Future<List<UserProfile>> getUsers({String? role}) async {
    final suffix = role == null ? '' : '?role=$role';
    final data = await _api.get('/api/admin/users$suffix') as List<dynamic>;
    return data
        .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> updateStatus(int userId, bool enabled) async {
    final data =
        await _api.put(
              '/api/admin/users/$userId/status',
              body: {'enabled': enabled},
            )
            as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<void> deleteUser(int userId) async {
    await _api.delete('/api/admin/users/$userId');
  }
}
