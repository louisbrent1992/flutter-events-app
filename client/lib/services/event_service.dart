import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import 'api_client.dart';

/// Event API client (auth required).
class EventService {
  static final ApiClient _api = ApiClient();

  /// Get all user events with pagination
  static Future<ApiResponse<Map<String, dynamic>>> getUserEvents({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.authenticatedGet<Map<String, dynamic>>(
      'events?page=$page&limit=$limit',
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
          debugPrint('Error converting event item: $e');
        }
      }

      return ApiResponse.success({
        'events': events,
        'pagination': response.data!['pagination'],
      });
    }

    return ApiResponse.error(
      response.message ?? 'Failed to get events',
      statusCode: response.statusCode,
    );
  }

  /// Fetch a single event by id
  static Future<ApiResponse<Event>> getEventById(String id) async {
    final response = await _api.authenticatedGet<Map<String, dynamic>>(
      'events/$id',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(Event.fromJson(response.data!));
    }

    return ApiResponse.error(
      response.message ?? 'Failed to fetch event',
      statusCode: response.statusCode,
    );
  }

  /// Create a new event
  static Future<ApiResponse<Event>> createEvent(Event event) async {
    final response = await _api.authenticatedPost<Map<String, dynamic>>(
      'events',
      body: event.toJson(),
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(
        Event.fromJson(response.data!),
        message: 'Event created successfully',
      );
    }

    return ApiResponse.error(
      response.message ?? 'Failed to create event',
      statusCode: response.statusCode,
    );
  }

  /// Update an existing event
  static Future<ApiResponse<Event>> updateEvent(Event event) async {
    final response = await _api.authenticatedPut<Map<String, dynamic>>(
      'events/${event.id}',
      body: event.toJson(),
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(
        Event.fromJson(response.data!),
        message: 'Event updated successfully',
      );
    }

    return ApiResponse.error(
      response.message ?? 'Failed to update event',
      statusCode: response.statusCode,
    );
  }

  /// Delete an event
  static Future<ApiResponse<void>> deleteEvent(String id) async {
    final response = await _api.authenticatedDelete<Map<String, dynamic>>(
      'events/$id',
    );

    if (response.success) {
      return ApiResponse.success(null, message: 'Event deleted');
    }

    return ApiResponse.error(
      response.message ?? 'Failed to delete event',
      statusCode: response.statusCode,
    );
  }
}


