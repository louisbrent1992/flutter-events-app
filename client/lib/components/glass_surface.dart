import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A premium glassy surface with enhanced visual effects.
///
/// Features backdrop blur, color tinting, gradient border support,
/// and subtle glow effects optimized for the new design system.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = 20,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1,
    this.gradient,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.enableGlow = false,
    this.glowColor,
    this.glowIntensity = 0.3,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final bool enableGlow;
  final Color? glowColor;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.lg);

    // Premium glass effect - more translucent in dark mode
    final Color baseTint =
        tintColor ??
        (isDark
            ? AppPalette.darkSurfaceElevated
            : AppPalette.lightSurfaceElevated);
    final double baseAlpha = isDark ? 0.75 : 0.88;
    final Color resolvedTint = baseTint.withValues(alpha: baseAlpha);

    // Subtle border for definition
    final Color resolvedBorder = (borderColor ?? scheme.outline).withValues(
      alpha: isDark ? 0.25 : 0.12,
    );

    // Optional glow effect for accented surfaces
    final List<BoxShadow> resolvedShadows = [
      if (boxShadow != null) ...boxShadow!,
      if (enableGlow)
        BoxShadow(
          color: (glowColor ?? scheme.primary).withValues(alpha: glowIntensity),
          blurRadius: 24,
          spreadRadius: -4,
        ),
    ];

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? resolvedTint : null,
        borderRadius: radius,
        border: Border.all(color: resolvedBorder, width: borderWidth),
        boxShadow: resolvedShadows.isNotEmpty ? resolvedShadows : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    // Apply blur if requested
    if (blurSigma > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}

/// A gradient-bordered glass container for premium accent surfaces
class GradientGlassSurface extends StatelessWidget {
  const GradientGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = 20,
    this.borderGradient,
    this.borderWidth = 1.5,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Gradient? borderGradient;
  final double borderWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.lg);

    final gradient = borderGradient ?? AppPalette.heroGradient;

    final bgColor =
        backgroundColor ??
        (isDark
            ? AppPalette.darkSurfaceElevated.withValues(alpha: 0.8)
            : AppPalette.lightSurface.withValues(alpha: 0.92));

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            (borderRadius?.topLeft.x ?? AppRadii.lg) - borderWidth,
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (blurSigma > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }
}

/// A simple frosted surface without heavy blur for performance
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.lg);

    final resolvedColor =
        color ??
        (isDark
            ? AppPalette.darkSurfaceMuted.withValues(alpha: 0.85)
            : AppPalette.lightSurfaceMuted.withValues(alpha: 0.92));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: radius,
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
