import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../main.dart';
import '../services/event_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    // Let auth settle.
    await Future.delayed(const Duration(milliseconds: 350));

    // Enforce minimum splash duration for polish.
    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
    final remainingMs = AppConfig.splashMinDurationMs - elapsed.inMilliseconds;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    if (!mounted) return;

    final auth = context.read<AuthService>();
    final pendingUrl = getPendingSharedUrl();
    final pendingNotification = getPendingNotificationPayload();

    // If user shared a link: require auth, then go to import.
    if (pendingUrl != null && pendingUrl.isNotEmpty) {
      if (auth.user == null) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      Navigator.pushReplacementNamed(context, '/importEvent', arguments: pendingUrl);
      return;
    }

    // If we have a notification payload, try to route it (eventDetail supported).
    if (pendingNotification != null && pendingNotification.isNotEmpty) {
      try {
        final obj = jsonDecode(pendingNotification) as Map<String, dynamic>;
        final route = obj['route'] as String?;
        final args = obj['args'] as Map<String, dynamic>?;

        if (route == '/eventDetail' && args != null && args['eventId'] != null) {
          final eventId = args['eventId'] as String;
          try {
            final resp = await EventService.getEventById(eventId);
            if (resp.success && resp.data != null && mounted) {
              Navigator.pushReplacementNamed(context, '/eventDetail', arguments: resp.data);
              return;
            }
          } catch (_) {}
        }

        if (!mounted) return;
        if (route != null && route.isNotEmpty) {
          Navigator.pushReplacementNamed(context, route, arguments: args);
          return;
        }
      } catch (_) {
        // Fall through to home.
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'EventEase',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



