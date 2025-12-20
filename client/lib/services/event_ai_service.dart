import '../models/api_response.dart';
import '../services/api_client.dart';
import '../models/event.dart';

class EventAiService {
  static final ApiClient _api = ApiClient();

  static Future<ApiResponse<Event>> importEventFromUrl(String url) async {
    final resp = await _api.publicPost<Map<String, dynamic>>(
      'ai/events/import',
      body: {'url': url},
    );

    if (resp.success && resp.data != null) {
      final fromCache = resp.data!['fromCache'] as bool? ?? false;
      return ApiResponse.success(
        Event.fromJson(resp.data!),
        message: 'Event imported successfully',
        metadata: {'fromCache': fromCache},
      );
    }

    return ApiResponse.error(
      resp.message ?? 'Failed to import event',
      statusCode: resp.statusCode,
    );
  }

  static Future<ApiResponse<Event>> scanFlyerBase64(String imageBase64) async {
    final resp = await _api.publicPost<Map<String, dynamic>>(
      'ai/events/scan',
      body: {'imageBase64': imageBase64},
    );

    if (resp.success && resp.data != null) {
      return ApiResponse.success(
        Event.fromJson(resp.data!),
        message: 'Flyer scanned successfully',
      );
    }

    return ApiResponse.error(
      resp.message ?? 'Failed to scan flyer',
      statusCode: resp.statusCode,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> planItinerary({
    String? vibe,
    String? budget,
    String? location,
    String? dates,
    String? constraints,
  }) async {
    final resp = await _api.publicPost<Map<String, dynamic>>(
      'ai/events/plan',
      body: {
        'vibe': vibe,
        'budget': budget,
        'location': location,
        'dates': dates,
        'constraints': constraints,
      },
    );

    if (resp.success && resp.data != null) {
      return ApiResponse.success(resp.data!, message: 'Plan generated');
    }

    return ApiResponse.error(
      resp.message ?? 'Failed to generate plan',
      statusCode: resp.statusCode,
    );
  }
}


