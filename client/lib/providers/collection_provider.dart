import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/event.dart';
import '../models/event_collection.dart';
import '../services/collection_service.dart';

class CollectionProvider extends ChangeNotifier {
  bool _isLoading = false;
  ApiResponse<void>? _error;

  List<EventCollection> _collections = [];
  EventCollection? _activeCollection;
  List<Event> _activeCollectionEvents = [];

  bool get isLoading => _isLoading;
  ApiResponse<void>? get error => _error;
  List<EventCollection> get collections => _collections;
  EventCollection? get activeCollection => _activeCollection;
  List<Event> get activeCollectionEvents => _activeCollectionEvents;

  void _setLoading(bool v) {
    if (_isLoading != v) {
      _isLoading = v;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _error = ApiResponse<void>.error(message);
    notifyListeners();
  }

  Future<void> loadCollections({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    clearError();
    _setLoading(true);
    try {
      final resp = await CollectionService.listCollections();
      if (resp.success && resp.data != null) {
        _collections = resp.data!;
        notifyListeners();
      } else {
        _setError(resp.message ?? 'Failed to load collections');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<EventCollection?> createCollection({
    required String name,
    String? description,
  }) async {
    clearError();
    _setLoading(true);
    try {
      final resp = await CollectionService.createCollection(
        name: name,
        description: description,
      );
      if (resp.success && resp.data != null) {
        _collections = [resp.data!, ..._collections];
        notifyListeners();
        return resp.data!;
      } else {
        _setError(resp.message ?? 'Failed to create collection');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCollectionDetail(String id) async {
    clearError();
    _setLoading(true);
    try {
      final resp = await CollectionService.getCollectionDetail(id);
      if (resp.success && resp.data != null) {
        final rawCollection = resp.data!['collection'];
        final rawEvents = resp.data!['events'];

        if (rawCollection is Map) {
          _activeCollection = EventCollection.fromJson(
            Map<String, dynamic>.from(rawCollection),
          );
        }
        _activeCollectionEvents = CollectionService.parseEvents(rawEvents);
        notifyListeners();
      } else {
        _setError(resp.message ?? 'Failed to load collection');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCollection(String id) async {
    clearError();
    _setLoading(true);
    try {
      final resp = await CollectionService.deleteCollection(id);
      if (resp.success) {
        _collections = _collections.where((c) => c.id != id).toList();
        if (_activeCollection?.id == id) {
          _activeCollection = null;
          _activeCollectionEvents = [];
        }
        notifyListeners();
      } else {
        _setError(resp.message ?? 'Failed to delete collection');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEventToActiveCollection(String eventId) async {
    final collectionId = _activeCollection?.id;
    if (collectionId == null) return;

    clearError();
    final resp = await CollectionService.addEventToCollection(
      collectionId: collectionId,
      eventId: eventId,
    );
    if (!resp.success) {
      _setError(resp.message ?? 'Failed to add event');
      return;
    }
    await loadCollectionDetail(collectionId);
  }

  Future<void> removeEventFromActiveCollection(String eventId) async {
    final collectionId = _activeCollection?.id;
    if (collectionId == null) return;

    clearError();
    final resp = await CollectionService.removeEventFromCollection(
      collectionId: collectionId,
      eventId: eventId,
    );
    if (!resp.success) {
      _setError(resp.message ?? 'Failed to remove event');
      return;
    }
    await loadCollectionDetail(collectionId);
  }
}
