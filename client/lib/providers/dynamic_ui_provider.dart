import 'package:flutter/foundation.dart';
import '../models/dynamic_ui.dart';
import '../services/dynamic_ui_service.dart';
import 'dart:async';

class DynamicUiProvider with ChangeNotifier {
  final DynamicUiService _service = DynamicUiService();
  DynamicUiConfig? _config;
  bool _loading = false;
  Timer? _timer;

  // Default fallback config for offline mode (matches server default)
  static DynamicUiConfig get _defaultConfig => DynamicUiConfig(
    version: 1,
    fetchedAt: DateTime.now(),
    banners: [],
    globalBackground: const DynamicBackgroundConfig(
      // Match app theme primary/secondary (see theme.dart)
      // Use light tints so logos/headers remain readable on top of the background.
      colors: ['#E6F9FC', '#F1ECFF'], // light cyan tint → light purple tint
      animateGradient: true,
      kenBurns: true,
      opacity: 1.0,
    ),
    welcomeMessage: 'Welcome,',
    heroSubtitle: 'What are you planning today?',
    sectionVisibility: {
      'yourEventsList': true,
      'upcomingSection': true,
      'featuresSection': true,
    },
  );

  // Return config from server, or default fallback if offline
  DynamicUiConfig? get config => _config ?? _defaultConfig;
  bool get isLoading => _loading;

  DynamicUiProvider() {
    refresh();
    // Periodic refresh so the server can change UI without a new build.
    // Keep this gentle to avoid excess network use.
    const interval = Duration(minutes: 15);
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final cfg = await _service.fetchConfig();
      _config = cfg;
    } catch (e) {
      // If fetch fails (offline), use default config
      // _config remains null, so getter will return _defaultConfig
      debugPrint('⚠️ Failed to fetch dynamic UI config, using default: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<DynamicBannerConfig> bannersForPlacement(String placement) {
    final list =
        _config?.banners
            .where((b) => b.placement == placement && b.isActive)
            .toList() ??
        [];
    list.sort((a, b) => b.priority.compareTo(a.priority));
    return list;
  }
}
