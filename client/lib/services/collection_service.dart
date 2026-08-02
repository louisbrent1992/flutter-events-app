import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import '../models/event_collection.dart';
import 'api_client.dart';

class CollectionService {
  static final ApiClient _api = ApiClient();

  static Future<ApiResponse<List<EventCollection>>> listCollections() async {
    final resp = await _api.authenticatedGet<Map<String, dynamic>>(
      'collections',
    );
    if (resp.success && resp.data != null) {
      final raw = resp.data!['collections'];
      if (raw is! List) {
        return ApiResponse.error('Invalid response format: collections');
      }
      final collections =
          raw
              .whereType<Map>()
              .map(
                (m) => EventCollection.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList();
      return ApiResponse.success(collections);
    }
    return ApiResponse.error(resp.message ?? 'Failed to load collections');
  }

  static Future<ApiResponse<EventCollection>> createCollection({
    required String name,
    String? description,
  }) async {
    final resp = await _api.authenticatedPost<Map<String, dynamic>>(
      'collections',
      body: {'name': name, 'description': description ?? ''},
    );
    if (resp.success && resp.data != null) {
      final c = resp.data!['collection'];
      if (c is Map) {
        return ApiResponse.success(
          EventCollection.fromJson(Map<String, dynamic>.from(c)),
        );
      }
      return ApiResponse.error('Invalid response format: collection');
    }
    return ApiResponse.error(resp.message ?? 'Failed to create collection');
  }

  static Future<ApiResponse<Map<String, dynamic>>> getCollectionDetail(
    String id,
  ) async {
    final resp = await _api.authenticatedGet<Map<String, dynamic>>(
      'collections/$id',
    );
    if (resp.success && resp.data != null) {
      return ApiResponse.success(resp.data!);
    }
    return ApiResponse.error(resp.message ?? 'Failed to load collection');
  }

  static Future<ApiResponse<void>> deleteCollection(String id) async {
    final resp = await _api.authenticatedDelete<void>('collections/$id');
    if (resp.success) return ApiResponse.success(null);
    return ApiResponse.error(resp.message ?? 'Failed to delete collection');
  }

  static Future<ApiResponse<void>> addEventToCollection({
    required String collectionId,
    required String eventId,
  }) async {
    final resp = await _api.authenticatedPost<Map<String, dynamic>>(
      'collections/$collectionId/items',
      body: {'eventId': eventId},
    );
    if (resp.success) return ApiResponse.success(null);
    return ApiResponse.error(resp.message ?? 'Failed to add event');
  }

  static Future<ApiResponse<void>> removeEventFromCollection({
    required String collectionId,
    required String eventId,
  }) async {
    final resp = await _api.authenticatedDelete<Map<String, dynamic>>(
      'collections/$collectionId/items/$eventId',
    );
    if (resp.success) return ApiResponse.success(null);
    return ApiResponse.error(resp.message ?? 'Failed to remove event');
  }

  static List<Event> parseEvents(dynamic raw) {
    if (raw is! List) return const [];
    final events = <Event>[];
    for (final item in raw) {
      try {
        if (item is Map<String, dynamic>) {
          events.add(Event.fromJson(item));
        } else if (item is Map) {
          events.add(Event.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        debugPrint('Error parsing collection event: $e');
      }
    }
    return events;
  }
}
