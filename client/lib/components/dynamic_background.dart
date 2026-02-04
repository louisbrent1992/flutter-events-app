import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show ImageFilter;
import '../models/dynamic_ui.dart';
import '../providers/dynamic_ui_provider.dart';
import '../main.dart' show MyApp;

class DynamicGlobalBackground extends StatefulWidget {
  const DynamicGlobalBackground({super.key});

  @override
  State<DynamicGlobalBackground> createState() =>
      _DynamicGlobalBackgroundState();
}

class _DynamicGlobalBackgroundState extends State<DynamicGlobalBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<Alignment> _beginAlign;
  late final Animation<Alignment> _endAlign;
  bool _wasAnimatingBeforeKeyboard = false;
  bool _wasAnimatingBeforeTransition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 1.05,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _beginAlign = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _endAlign = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes to pause animation during transitions
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      MyApp.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // Pause animation when route is being pushed
  @override
  void didPush() {
    if (_controller.isAnimating) {
      _wasAnimatingBeforeTransition = true;
      _controller.stop();
    }
  }

  // Resume animation when route transition completes
  @override
  void didPopNext() {
    if (_wasAnimatingBeforeTransition && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
      _wasAnimatingBeforeTransition = false;
    }
  }

  // Also pause when popping (swiping back)
  @override
  void didPop() {
    if (_controller.isAnimating) {
      _wasAnimatingBeforeTransition = true;
      _controller.stop();
    }
  }

  // Resume when next route is pushed (transition complete)
  @override
  void didPushNext() {
    if (_wasAnimatingBeforeTransition && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
      _wasAnimatingBeforeTransition = false;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Detect keyboard visibility by checking bottom view insets
    final bottomInset =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom;

    if (bottomInset > 0) {
      // Keyboard is visible - pause animation to prevent stuttering
      if (_controller.isAnimating) {
        _wasAnimatingBeforeKeyboard = true;
        _controller.stop();
      }
    } else {
      // Keyboard is hidden - resume animation if it was running before
      if (_wasAnimatingBeforeKeyboard && !_controller.isAnimating) {
        _controller.repeat(reverse: true);
        _wasAnimatingBeforeKeyboard = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicUiProvider>(
      builder: (context, dyn, _) {
        final DynamicBackgroundConfig? bg = dyn.config?.globalBackground;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isDarkMode = theme.brightness == Brightness.dark;

        // Fallback: if there is no remote background config, still render a
        // premium animated gradient so the UI keeps the intended “poster/glass”
        // aesthetic.
        if (bg == null) {
          return IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final colors = [
                  scheme.surface,
                  scheme.primary.withValues(alpha: 0.15),
                  scheme.secondary.withValues(alpha: 0.12),
                  scheme.tertiary.withValues(alpha: 0.10),
                ];

                return Transform.scale(
                  scale: _scaleAnim.value,
                  alignment: _beginAlign.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: _beginAlign.value,
                        end: _endAlign.value,
                        colors: colors,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        final double overlayOpacity = (bg.opacity ?? 1.0).clamp(0.0, 1.0);
        // When using an image background, apply a mode-aware scrim so foreground
        // content stays readable in both light and dark themes.
        //
        // - Light mode: brighten/soften the image (white scrim)
        // - Dark mode: deepen the image (black scrim)
        final Color scrimBaseColor = isDarkMode ? Colors.black : Colors.white;
        // Light mode: reduce the heavy whitening so the background feels richer.
        final double scrimStrength = isDarkMode ? 0.42 : 0.40;
        final double scrimSoftStrength = isDarkMode ? 0.18 : 0.18;
        final double imageBlur = isDarkMode ? 0.0 : 6.0;

        // Note: This widget should be placed inside a Positioned.fill or SizedBox.expand
        // when used in a Stack to ensure it fills the available space
        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bg.hasImage)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double scale = bg.kenBurns ? _scaleAnim.value : 1.0;
                    final url = bg.imageUrl ?? '';
                    final isAsset = url.startsWith('assets/');
                    final alignment =
                        bg.kenBurns ? _beginAlign.value : Alignment.center;
                    return Transform.scale(
                      scale: scale,
                      child:
                          isAsset
                              ? Image.asset(
                                url,
                                fit: BoxFit.cover,
                                alignment: alignment,
                                filterQuality: FilterQuality.low,
                              )
                              : Image.network(
                                url,
                                fit: BoxFit.cover,
                                alignment: alignment,
                                filterQuality: FilterQuality.low,
                              ),
                    );
                  },
                )
              else if (bg.hasGradient || isDarkMode)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    // Use theme-aware colors if no colors are provided in the config
                    // or if it's dark mode and we want to enforce theme colors.
                    final List<Color> colors =
                        (bg.colors.isEmpty || isDarkMode)
                            ? [
                              scheme.surface,
                              scheme.primary.withValues(alpha: 0.15),
                              scheme.secondary.withValues(alpha: 0.12),
                              scheme.tertiary.withValues(alpha: 0.10),
                            ]
                            : bg.colors
                                .map(_parseColor)
                                .whereType<Color>()
                                .toList();

                    if (colors.length < 2) return const SizedBox.shrink();

                    final double scale = bg.kenBurns ? _scaleAnim.value : 1.0;
                    final alignment =
                        bg.kenBurns ? _beginAlign.value : Alignment.center;

                    return Transform.scale(
                      scale: scale,
                      alignment: alignment,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin:
                                bg.animateGradient
                                    ? _beginAlign.value
                                    : Alignment.topLeft,
                            end:
                                bg.animateGradient
                                    ? _endAlign.value
                                    : Alignment.bottomRight,
                            colors: colors,
                          ),
                        ),
                      ),
                    );
                  },
                )
              else if (bg.hasSolidColor)
                Container(
                  color:
                      (bg.colors.isEmpty)
                          ? scheme.surface
                          : _parseColor(
                            bg.colors.first,
                          )?.withValues(alpha: overlayOpacity),
                ),

              // Image readability layer (scrim + optional blur).
              if (bg.hasImage)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageBlur > 0)
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: imageBlur,
                          sigmaY: imageBlur,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    // Light-mode color wash to avoid a dull/flat look.
                    if (!isDarkMode)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary.withValues(alpha: 0.10),
                              scheme.secondary.withValues(alpha: 0.08),
                              scheme.tertiary.withValues(alpha: 0.06),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scrimBaseColor.withValues(alpha: scrimStrength),
                            scrimBaseColor.withValues(alpha: scrimSoftStrength),
                            scrimBaseColor.withValues(alpha: scrimStrength),
                          ],
                        ),
                      ),
                    ),
                    // Respect server-configured opacity: treat it as "how much of the image shows through".
                    // Lower opacity => stronger scrim.
                    if (overlayOpacity < 1.0)
                      Container(
                        color: scrimBaseColor.withValues(
                          alpha: 1.0 - overlayOpacity,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Color? _parseColor(String hex) {
    String cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return null;
    final int? value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
