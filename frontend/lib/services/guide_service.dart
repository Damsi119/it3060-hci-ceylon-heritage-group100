import '../models/guide_application.dart';
import 'api_client.dart';

class GuideService {
  GuideService._();

  static final GuideService instance = GuideService._();
  final ApiClient _api = ApiClient.instance;

  Future<GuideApplication> submitRequest({
    required String name,
    required String email,
    required String phone,
    required String primaryServiceArea,
    required String languages,
    required String experience,
  }) async {
    final data =
        await _api.post(
              '/api/guide-requests',
              authenticated: false,
              body: {
                'name': name,
                'email': email,
                'phone': phone,
                'primaryServiceArea': primaryServiceArea,
                'languages': languages,
                'experience': experience,
              },
            )
            as Map<String, dynamic>;
    return GuideApplication.fromJson(data);
  }

  Future<GuideApplication> checkStatus({
    required String email,
    required String phone,
  }) async {
    final query = Uri(queryParameters: {'email': email, 'phone': phone}).query;

    final data =
        await _api.get(
              '/api/guide-requests/status?$query',
              authenticated: false,
            )
            as Map<String, dynamic>;
    return GuideApplication.fromJson(data);
  }

  Future<List<GuideApplication>> getByStatus(String status) async {
    final data =
        await _api.get('/api/admin/guides?status=$status') as List<dynamic>;
    return data
        .map((item) => GuideApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GuideApplication> review({
    required int id,
    required String status,
    String? note,
  }) async {
    final data =
        await _api.put(
              '/api/admin/guides/$id/review',
              body: {'status': status, 'reviewNote': note},
            )
            as Map<String, dynamic>;
    return GuideApplication.fromJson(data);
  }
}
