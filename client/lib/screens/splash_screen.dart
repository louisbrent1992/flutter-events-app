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
  late final ImageProvider _logo;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _logo = const AssetImage('assets/icons/eventease_logo.png');
    // Preload the logo so the splash animation doesn't "pop" on first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(_logo, context);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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
      Navigator.pushReplacementNamed(
        context,
        '/importEvent',
        arguments: pendingUrl,
      );
      return;
    }

    // If we have a notification payload, try to route it (eventDetail supported).
    if (pendingNotification != null && pendingNotification.isNotEmpty) {
      try {
        final obj = jsonDecode(pendingNotification) as Map<String, dynamic>;
        final route = obj['route'] as String?;
        final args = obj['args'] as Map<String, dynamic>?;

        if (route == '/eventDetail' &&
            args != null &&
            args['eventId'] != null) {
          final eventId = args['eventId'] as String;
          try {
            final resp = await EventService.getEventById(eventId);
            if (resp.success && resp.data != null && mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/eventDetail',
                arguments: resp.data,
              );
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

    // Route to the normal home entry. The floating nav shell handles the rest.
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mode-specific adjustments for better contrast
    final backdropGlowColor =
        isDark
            ? Colors.white.withValues(alpha: 0.25) // Brighter in dark mode
            : Colors.black.withValues(alpha: 0.15); // Darker in light mode

    final backdropCircleColor =
        isDark
            ? Colors.white.withValues(
              alpha: 0.12,
            ) // Lighter backdrop in dark mode
            : Colors.white.withValues(alpha: 0.08); // Subtle in light mode

    final primaryGlowIntensity =
        isDark ? 0.30 : 0.20; // Stronger glow in dark mode
    final primaryGlowBlur = isDark ? 40.0 : 30.0; // Larger glow in dark mode

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer backdrop glow - stronger in dark mode
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: backdropGlowColor,
                        blurRadius: isDark ? 100 : 80,
                        spreadRadius: isDark ? 40 : 30,
                      ),
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        blurRadius: isDark ? 120 : 100,
                        spreadRadius: isDark ? 50 : 40,
                      ),
                    ],
                  ),
                ),
                // Backdrop circle - more visible in dark mode
                Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backdropCircleColor,
                    boxShadow: [
                      BoxShadow(
                        color: backdropGlowColor,
                        blurRadius: isDark ? 60 : 50,
                        spreadRadius: isDark ? 20 : 15,
                      ),
                    ],
                  ),
                ),
                // Logo with mode-appropriate outer glow
                Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Primary color glow - stronger in dark mode
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: primaryGlowIntensity,
                        ),
                        blurRadius: primaryGlowBlur,
                        spreadRadius: isDark ? 8 : 5,
                      ),
                      // Secondary glow for depth
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.15 : 0.10),
                        blurRadius: isDark ? 25 : 20,
                        spreadRadius: isDark ? 4 : 2,
                      ),
                      // Subtle inner glow in dark mode
                      if (isDark)
                        BoxShadow(
                          color: scheme.secondary.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Image(
                    image: _logo,
                    width: 340,
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.contain,
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
