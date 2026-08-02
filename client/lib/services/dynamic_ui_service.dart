import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dynamic_ui.dart';
import 'api_client.dart';

class DynamicUiService {
  final ApiClient _api = ApiClient();

  static const String _cacheBox = 'preferences';
  static const String _cacheKeyJson = 'dynamic_ui_config_json';
  static const String _cacheKeySavedAt = 'dynamic_ui_config_saved_at';

  Future<void> _saveCache(Map<String, dynamic> json) async {
    try {
      final box = Hive.box(_cacheBox);
      await box.put(_cacheKeyJson, jsonEncode(json));
      await box.put(_cacheKeySavedAt, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  DynamicUiConfig? _readCache() {
    try {
      final box = Hive.box(_cacheBox);
      final raw = box.get(_cacheKeyJson);
      if (raw is! String || raw.trim().isEmpty) return null;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      return DynamicUiConfig.fromJson(obj);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _normalizeUrls(Map<String, dynamic> obj) async {
    // Allow server to return relative URLs (e.g. "/ui/background.png")
    // by prefixing with "<server-origin>" (baseUrl without "/api").
    try {
      final apiBase = await _api.baseUrl; // e.g. https://.../api
      final origin = apiBase.endsWith('/api')
          ? apiBase.substring(0, apiBase.length - 4)
          : apiBase;

      String? normalize(String? url) {
        final u = (url ?? '').trim();
        if (u.isEmpty) return null;
        if (u.startsWith('http://') || u.startsWith('https://') || u.startsWith('assets/')) {
          return u;
        }
        if (u.startsWith('/')) return '$origin$u';
        return u;
      }

      // globalBackground.imageUrl
      final gb = obj['globalBackground'];
      if (gb is Map) {
        final m = Map<String, dynamic>.from(gb);
        m['imageUrl'] = normalize(m['imageUrl'] as String?);
        obj['globalBackground'] = m;
      }

      // heroImageUrl
      obj['heroImageUrl'] = normalize(obj['heroImageUrl'] as String?);

      // banner imageUrls
      final banners = obj['banners'];
      if (banners is List) {
        obj['banners'] =
            banners.map((b) {
              if (b is Map) {
                final m = Map<String, dynamic>.from(b);
                m['imageUrl'] = normalize(m['imageUrl'] as String?);
                return m;
              }
              return b;
            }).toList();
      }
    } catch (_) {}
    return obj;
  }

  Future<DynamicUiConfig?> fetchConfig() async {
    try {
      final res = await _api.publicGet<Map<String, dynamic>>(
        'ui/config',
        fromJson: (map) => map,
      );
      if (res.success && res.data != null) {
        // The ApiClient already unwraps { data: ... } into res.data
        final Map<String, dynamic> obj = res.data!;
        final normalized = await _normalizeUrls(obj);
        await _saveCache(normalized);
        return DynamicUiConfig.fromJson(normalized);
      }
      return _readCache();
    } catch (e) {
      debugPrint('DynamicUiService.fetchConfig error: $e');
      return _readCache();
    }
  }
}
