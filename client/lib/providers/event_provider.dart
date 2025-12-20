import 'dart:async';
import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final StreamController<void> _eventsChangedController =
      StreamController<void>.broadcast();
  Stream<void> get onEventsChanged => _eventsChangedController.stream;

  List<Event> _userEvents = [];
  bool _isLoading = false;
  ApiResponse<Event>? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  int _totalEvents = 0;

  List<Event> get userEvents => _userEvents;
  bool get isLoading => _isLoading;
  ApiResponse<Event>? get error => _error;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _hasNextPage;
  bool get hasPrevPage => _hasPrevPage;
  int get totalEvents => _totalEvents;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _error = ApiResponse<Event>.error(
      message ?? 'An unexpected error occurred',
    );
    notifyListeners();
  }

  Future<void> loadUserEvents({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    clearError();
    _setLoading(true);

    try {
      final response = await EventService.getUserEvents(page: page, limit: limit);
      if (response.success && response.data != null) {
        final events = response.data!['events'] as List<Event>? ?? <Event>[];
        final pagination = response.data!['pagination'] as Map<String, dynamic>?;

        _userEvents = events;

        if (pagination != null) {
          _currentPage = pagination['page'] ?? page;
          _totalPages = pagination['totalPages'] ?? 1;
          _hasNextPage = pagination['hasNextPage'] ?? false;
          _hasPrevPage = pagination['hasPrevPage'] ?? (page > 1);
          _totalEvents = pagination['total'] ?? events.length;
        } else {
          _currentPage = page;
          _totalPages = 1;
          _hasNextPage = false;
          _hasPrevPage = page > 1;
          _totalEvents = events.length;
        }

        notifyListeners();
      } else {
        _setError(response.message ?? 'Failed to load events');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Event?> createEvent(Event event, BuildContext context) async {
    clearError();

    try {
      final resp = await EventService.createEvent(event);
      if (resp.success && resp.data != null) {
        final created = resp.data!;
        _userEvents = [created, ..._userEvents];
        _totalEvents = (_totalEvents + 1).clamp(0, 1 << 31);
        notifyListeners();
        _eventsChangedController.add(null);
        return created;
      }
      _setError(resp.message ?? 'Failed to create event');
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> deleteEvent(String id, BuildContext context) async {
    clearError();

    final before = _userEvents.length;
    _userEvents = _userEvents.where((e) => e.id != id).toList();
    if (_userEvents.length != before) {
      notifyListeners();
    }

    try {
      final resp = await EventService.deleteEvent(id);
      if (resp.success) {
        _totalEvents = (_totalEvents - 1).clamp(0, 1 << 31);
        _eventsChangedController.add(null);
        return true;
      }
      _setError(resp.message ?? 'Failed to delete event');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _eventsChangedController.close();
    super.dispose();
  }
}


