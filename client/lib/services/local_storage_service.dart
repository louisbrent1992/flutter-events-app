import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/event.dart';

/// Service for persistent local storage using Hive.
///
/// EventEase stores lightweight, event-only caches and metadata (like last sync
/// timestamps). This replaces the legacy local storage layer from the previous
/// app domain.
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  static const String _userEventsBox = 'user_events';
  static const String _discoverEventsBox = 'discover_events';
  static const String _metadataBox = 'storage_metadata';

  static const Duration _eventsCacheDuration = Duration(days: 7);

  Box? _userEventsBoxInstance;
  Box? _discoverEventsBoxInstance;
  Box? _metadataBoxInstance;

  Future<void> initialize() async {
    _userEventsBoxInstance ??= await Hive.openBox(_userEventsBox);
    _discoverEventsBoxInstance ??= await Hive.openBox(_discoverEventsBox);
    _metadataBoxInstance ??= await Hive.openBox(_metadataBox);
    if (kDebugMode) {
      debugPrint('✅ LocalStorageService: initialized');
    }
  }

  Future<Box> _eventsBox() async {
    if (_userEventsBoxInstance == null) {
      await initialize();
    }
    return _userEventsBoxInstance!;
  }

  Future<Box> _metaBox() async {
    if (_metadataBoxInstance == null) {
      await initialize();
    }
    return _metadataBoxInstance!;
  }

  Future<Box> _discoverBox() async {
    if (_discoverEventsBoxInstance == null) {
      await initialize();
    }
    return _discoverEventsBoxInstance!;
  }

  // ==================== User Events ====================

  Future<void> saveUserEvents(
    List<Event> events, {
    int? totalEvents,
    int? totalPages,
  }) async {
    final box = await _eventsBox();

    final eventsJson = events.map((e) => e.toJson()).toList();
    await box.put('events', eventsJson);
    if (totalEvents != null) await box.put('totalEvents', totalEvents);
    if (totalPages != null) await box.put('totalPages', totalPages);

    await setLastSyncTime('events', DateTime.now());
  }

  Future<Map<String, int>> loadUserEventsPagination() async {
    final box = await _eventsBox();
    final totalEvents = box.get('totalEvents') as int?;
    final totalPages = box.get('totalPages') as int?;
    return {'totalEvents': totalEvents ?? 0, 'totalPages': totalPages ?? 1};
  }

  Future<List<Event>> loadUserEvents({bool allowStale = true}) async {
    final box = await _eventsBox();

    final lastSync = await getLastSyncTime('events');
    if (!allowStale && lastSync != null) {
      if (DateTime.now().difference(lastSync) > _eventsCacheDuration) {
        return [];
      }
    }

    final raw = box.get('events') as List?;
    if (raw == null) return [];

    return raw.map((json) {
      if (json is Map) {
        final Map<String, dynamic> converted = {};
        json.forEach((k, v) => converted[k.toString()] = v);
        return Event.fromJson(converted);
      }
      return Event.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveUserEvent(Event event) async {
    final existing = await loadUserEvents();
    final next = [...existing.where((e) => e.id != event.id), event];
    await saveUserEvents(next);
  }

  Future<void> deleteUserEvent(String eventId) async {
    final existing = await loadUserEvents();
    final next = existing.where((e) => e.id != eventId).toList();
    await saveUserEvents(next);
  }

  // ==================== Discover Events ====================

  Future<void> saveDiscoverEvents(List<Event> events) async {
    final box = await _discoverBox();
    final eventsJson = events.map((e) => e.toJson()).toList();
    await box.put('events', eventsJson);
    await setLastSyncTime('discover', DateTime.now());
  }

  Future<List<Event>> loadDiscoverEvents({bool allowStale = true}) async {
    final box = await _discoverBox();
    final lastSync = await getLastSyncTime('discover');
    if (!allowStale && lastSync != null) {
      if (DateTime.now().difference(lastSync) > _eventsCacheDuration) {
        return [];
      }
    }

    final raw = box.get('events') as List?;
    if (raw == null) return [];
    return raw.map((json) {
      if (json is Map) {
        final Map<String, dynamic> converted = {};
        json.forEach((k, v) => converted[k.toString()] = v);
        return Event.fromJson(converted);
      }
      return Event.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  // ==================== Metadata ====================

  Future<void> setLastSyncTime(String dataType, DateTime when) async {
    final box = await _metaBox();
    await box.put('lastSync_$dataType', when.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime(String dataType) async {
    final box = await _metaBox();
    final raw = box.get('lastSync_$dataType') as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearAll() async {
    final eventsBox = await _eventsBox();
    final discoverBox = await _discoverBox();
    final metaBox = await _metaBox();
    await eventsBox.clear();
    await discoverBox.clear();
    await metaBox.clear();
  }
}
