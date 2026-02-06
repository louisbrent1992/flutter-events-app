import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import '../services/discover_service.dart';
import '../services/local_storage_service.dart';

class DiscoverProvider extends ChangeNotifier {
  List<Event> _events = [];
  List<Event> _homeEvents =
      []; // Separate list for Home screen to ignore filters
  bool _isLoading = false;
  bool _isHomeLoading = false;
  ApiResponse<Event>? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  int _totalEvents = 0;

  // Current filters
  String _query = '';
  String _category = 'All';
  String _city = '';
  String _region = '';
  DateTime? _from;
  DateTime? _to;

  List<Event> get events => _events;
  List<Event> get homeEvents => _homeEvents;
  bool get isLoading => _isLoading;
  bool get isHomeLoading => _isHomeLoading;
  ApiResponse<Event>? get error => _error;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _hasNextPage;
  bool get hasPrevPage => _hasPrevPage;
  int get totalEvents => _totalEvents;

  String get query => _query;
  String get category => _category;
  String get city => _city;
  String get region => _region;
  DateTime? get from => _from;
  DateTime? get to => _to;

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

  void setFilters({
    String? query,
    String? category,
    String? city,
    String? region,
    DateTime? from,
    DateTime? to,
  }) {
    _query = query ?? _query;
    _category = category ?? _category;
    _city = city ?? _city;
    _region = region ?? _region;
    _from = from ?? _from;
    _to = to ?? _to;
    notifyListeners();
  }

  Future<void> load({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    // Prevent concurrent loads
    if (_isLoading && !forceRefresh) return;

    clearError();
    _setLoading(true);

    try {
      final resp = await DiscoverService.getDiscoverEvents(
        query: _query,
        category: _category == 'All' ? null : _category,
        city: _city.isEmpty ? null : _city,
        region: _region.isEmpty ? null : _region,
        from: _from,
        to: _to,
        page: page,
        limit: limit,
      );

      if (resp.success && resp.data != null) {
        final events = resp.data!['events'] as List<Event>? ?? <Event>[];
        final pagination = resp.data!['pagination'] as Map<String, dynamic>?;

        _events = events;

        // Cache for offline use (best-effort)
        try {
          await LocalStorageService().saveDiscoverEvents(events);
        } catch (_) {}

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
        // Fallback to cached discover events (best-effort)
        try {
          final cached = await LocalStorageService().loadDiscoverEvents();
          if (cached.isNotEmpty) {
            _events = cached;
            _currentPage = 1;
            _totalPages = 1;
            _hasNextPage = false;
            _hasPrevPage = false;
            _totalEvents = cached.length;
            notifyListeners();
          }
        } catch (_) {}
        _setError(resp.message ?? 'Failed to load discover events');
      }
    } catch (e) {
      // Fallback to cached discover events (best-effort)
      try {
        final cached = await LocalStorageService().loadDiscoverEvents();
        if (cached.isNotEmpty) {
          _events = cached;
          _currentPage = 1;
          _totalPages = 1;
          _hasNextPage = false;
          _hasPrevPage = false;
          _totalEvents = cached.length;
          notifyListeners();
        }
      } catch (_) {}
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadHomeEvents() async {
    if (_isHomeLoading) return;

    _isHomeLoading = true;
    notifyListeners();

    try {
      // Fetch general trending/upcoming events (no filters applied)
      final resp = await DiscoverService.getDiscoverEvents(
        limit: 10,
        // Ensure no filters are passed
      );

      if (resp.success && resp.data != null) {
        final events = resp.data!['events'] as List<Event>? ?? <Event>[];
        _homeEvents = events;
      }
    } catch (e) {
      debugPrint('Error loading home events: $e');
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }
}
