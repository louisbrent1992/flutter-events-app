import '../models/api_response.dart';
import '../models/event.dart';
import 'api_client.dart';

class RandomEventService {
  static final ApiClient _api = ApiClient();

  static Future<ApiResponse<Event?>> getRandomEvent({
    String? query,
    String? category,
    String? city,
    String? region,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty)
      queryParams['q'] = query.trim();
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (city != null && city.trim().isNotEmpty)
      queryParams['city'] = city.trim();
    if (region != null && region.trim().isNotEmpty)
      queryParams['region'] = region.trim();

    final resp = await _api.publicGet<Map<String, dynamic>>(
      'random',
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (resp.success && resp.data != null) {
      final raw = resp.data!['event'];
      if (raw == null) return ApiResponse.success(null);
      if (raw is Map) {
        return ApiResponse.success(
          Event.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return ApiResponse.error('Invalid response format: event');
    }

    return ApiResponse.error(resp.message ?? 'Failed to load random event');
  }
}
