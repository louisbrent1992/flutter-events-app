import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../main.dart';
import '../services/event_service.dart';
import '../theme/theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    // Soft glow color behind the logo
    final logoGlowColor =
        isDark
            ? scheme.primary.withValues(alpha: 0.25)
            : scheme.primary.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo with subtle warm glow
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: logoGlowColor,
                        blurRadius: isDark ? 60 : 40,
                        spreadRadius: isDark ? 15 : 10,
                      ),
                    ],
                  ),
                  child: Image(
                    image: _logo,
                    width: 140,
                    height: 140,
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                // Wordmark, set as a masthead: tracked caps under the logo.
                Text(
                  'SPARK',
                  style: textTheme.displayMedium?.copyWith(
                    color: scheme.onSurface,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'EVENTS, EDITED',
                  style: textTheme.eyebrow?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(flex: 2),

                // A hairline progress rule rather than a spinner - quieter,
                // and it echoes the rules used throughout the app.
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: scheme.hairline,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.accent),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
