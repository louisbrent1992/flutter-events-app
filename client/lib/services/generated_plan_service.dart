import '../models/api_response.dart';
import '../models/generated_plan.dart';
import 'api_client.dart';

class GeneratedPlanService {
  static final ApiClient _api = ApiClient();

  static Future<ApiResponse<Map<String, dynamic>>> listPlans({
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _api.authenticatedGet<Map<String, dynamic>>(
      'generated/plans',
      queryParams: {'page': '$page', 'limit': '$limit'},
    );
    if (resp.success && resp.data != null) {
      return ApiResponse.success(resp.data!);
    }
    return ApiResponse.error(resp.message ?? 'Failed to load history');
  }

  static Future<ApiResponse<GeneratedPlan>> getPlan(String id) async {
    final resp = await _api.authenticatedGet<Map<String, dynamic>>(
      'generated/plans/$id',
    );
    if (resp.success && resp.data != null) {
      final planRaw = resp.data!['plan'];
      if (planRaw is Map) {
        return ApiResponse.success(
          GeneratedPlan.fromJson(Map<String, dynamic>.from(planRaw)),
        );
      }
      return ApiResponse.error('Invalid response format: plan');
    }
    return ApiResponse.error(resp.message ?? 'Failed to load plan');
  }

  static Future<ApiResponse<GeneratedPlan>> savePlan({
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
    String? title,
    String kind = 'itinerary',
  }) async {
    final resp = await _api.authenticatedPost<Map<String, dynamic>>(
      'generated/plans',
      body: {'kind': kind, 'title': title, 'input': input, 'output': output},
    );

    if (resp.success && resp.data != null) {
      final planRaw = resp.data!['plan'];
      if (planRaw is Map) {
        return ApiResponse.success(
          GeneratedPlan.fromJson(Map<String, dynamic>.from(planRaw)),
        );
      }
      return ApiResponse.error('Invalid response format: plan');
    }

    return ApiResponse.error(resp.message ?? 'Failed to save plan');
  }

  static Future<ApiResponse<void>> deletePlan(String id) async {
    final resp = await _api.authenticatedDelete<Map<String, dynamic>>(
      'generated/plans/$id',
    );
    if (resp.success) return ApiResponse.success(null);
    return ApiResponse.error(resp.message ?? 'Failed to delete plan');
  }
}
