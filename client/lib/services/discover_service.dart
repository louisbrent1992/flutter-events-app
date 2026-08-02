import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import 'api_client.dart';

/// Discover API client (public; guest-safe).
class DiscoverService {
  static final ApiClient _api = ApiClient();

  static Future<ApiResponse<Map<String, dynamic>>> getDiscoverEvents({
    String? query,
    String? category,
    String? city,
    String? region,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParams['city'] = city.trim();
    }
    if (region != null && region.trim().isNotEmpty) {
      queryParams['region'] = region.trim();
    }
    if (from != null) queryParams['from'] = from.toIso8601String();
    if (to != null) queryParams['to'] = to.toIso8601String();

    final response = await _api.publicGet<Map<String, dynamic>>(
      'discover',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final eventsData = response.data!['events'];
      if (eventsData is! List) {
        return ApiResponse.error(
          'Invalid response format: events is not a list',
        );
      }

      final events = <Event>[];
      for (final item in eventsData) {
        try {
          if (item is Map<String, dynamic>) {
            events.add(Event.fromJson(item));
          } else if (item is Map) {
            events.add(Event.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          debugPrint('Error converting discover event item: $e');
        }
      }

      return ApiResponse.success({
        'events': events,
        'pagination': response.data!['pagination'],
      });
    }

    return ApiResponse.error(
      response.message ?? 'Failed to load discover events',
      statusCode: response.statusCode,
    );
  }
}
