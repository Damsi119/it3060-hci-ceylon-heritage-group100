import '../models/tour_plan.dart';
import 'api_client.dart';

class TourPlanService {
  TourPlanService._();

  static final TourPlanService instance = TourPlanService._();

  Future<TourPlan> generate(String prompt) async {
    final response = await ApiClient.instance.post(
      '/api/tour-planner/generate',
      authenticated: false,
      body: {'prompt': prompt},
    );

    if (response is! Map) {
      throw const FormatException('Invalid tour plan response');
    }

    return TourPlan.fromJson(Map<String, dynamic>.from(response));
  }
}
