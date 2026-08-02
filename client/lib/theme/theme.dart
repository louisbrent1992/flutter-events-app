import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark Editorial Event Palette
///
/// Near-black canvas, a single crimson accent, and neutrals that step in
/// small increments so event photography carries the colour. Everything
/// chromatic is deliberate: the accent marks one action per screen.
class AppPalette {
  // ---------------------------------------------------------------------
  // Accent - a single crimson, three weights
  // ---------------------------------------------------------------------
  /// The brand accent. One per screen: the primary action.
  static const Color accent = Color(0xFFE11D48);

  /// Lifted accent for dark surfaces, where the base crimson reads muddy.
  static const Color accentBright = Color(0xFFFF4D6D);

  /// Pressed / deep states and accent-on-light text.
  static const Color accentDeep = Color(0xFF9F1239);

  /// Faint accent wash for containers and selected rows.
  static const Color accentWash = Color(0x1AE11D48);

  // ---------------------------------------------------------------------
  // Dark theme - the primary theme
  // ---------------------------------------------------------------------
  static const Color canvas = Color(0xFF0B0B0F); // page background
  static const Color surface = Color(0xFF14141A); // cards, sheets
  static const Color surfaceElevated = Color(0xFF1D1D26); // menus, dialogs
  static const Color surfaceMuted = Color(0xFF101015); // recessed wells
  static const Color ink = Color(0xFFF5F5F7); // primary text
  static const Color inkMuted = Color(0xFF9A9AA5); // secondary text
  static const Color hairline = Color(0xFF2A2A34); // 1px separators

  // ---------------------------------------------------------------------
  // Light theme - warm paper, same crimson
  // ---------------------------------------------------------------------
  static const Color paper = Color(0xFFF7F6F4); // page background
  static const Color paperSurface = Color(0xFFFFFFFF); // cards, sheets
  static const Color paperElevated = Color(0xFFFFFFFF); // menus, dialogs
  static const Color paperMuted = Color(0xFFEDEBE7); // recessed wells
  static const Color paperInk = Color(0xFF0B0B0F); // primary text
  static const Color paperInkMuted = Color(0xFF6B6B76); // secondary text
  static const Color paperHairline = Color(0xFFE0DDD8); // 1px separators

  // ---------------------------------------------------------------------
  // Supporting hues - used only for status, never for decoration
  // ---------------------------------------------------------------------
  static const Color emerald = Color(0xFF10B981); // success
  static const Color amber = Color(0xFFF0A500); // warning / featured
  static const Color slate = Color(0xFF71717A); // neutral chrome
  static const Color warmGray = Color(0xFF8A8A94);
  static const Color accentPurple = Color(0xFF9333EA); // AI / generated

  // ---------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFB4123C)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBright, accent],
  );

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accent],
  );

  /// The editorial scrim: bottom-anchored, four stops so titles stay legible
  /// over any photograph without visibly greying the top of the image.
  static const LinearGradient posterScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x1A000000),
      Color(0xA6000000),
      Color(0xF2000000),
    ],
    stops: [0.0, 0.45, 0.78, 1.0],
  );

  /// A shorter scrim for full-bleed heroes that carry a top-aligned app bar.
  static const LinearGradient heroScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x99000000),
      Color(0x00000000),
      Color(0x66000000),
      Color(0xF7000000),
    ],
    stops: [0.0, 0.28, 0.62, 1.0],
  );

  // ---------------------------------------------------------------------
  // Legacy aliases
  //
  // The app referenced a blue corporate palette in ~180 places. These keep
  // those call sites compiling and repoint them at the editorial roles.
  // Prefer the semantic names above in new code.
  // ---------------------------------------------------------------------
  static const Color primaryBlue = accent;
  static const Color accentBlue = accentBright;
  static const Color darkBg = canvas;
  static const Color darkSurface = surface;
  static const Color darkSurfaceElevated = surfaceElevated;
  static const Color darkSurfaceMuted = surfaceMuted;
  static const Color darkInk = ink;
  static const Color lightBg = paper;
  static const Color lightSurface = paperSurface;
  static const Color lightSurfaceElevated = paperElevated;
  static const Color lightSurfaceMuted = paperMuted;
  static const Color lightInk = paperInk;
}

/// Editorial radii - tighter than the previous system so cards read as
/// printed plates rather than bubbles.
class AppRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double full = 999;
}

/// Shadows. In dark editorial the canvas is nearly black, so elevation is
/// carried by a hairline border plus a deep, soft shadow - never by tint.
class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.08),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> lifted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.12),
        blurRadius: 40,
        offset: const Offset(0, 18),
      ),
    ];
  }

  /// Accent glow, reserved for the single primary action on a screen.
  static List<BoxShadow> accentGlow({double alpha = 0.35}) => [
    BoxShadow(
      color: AppPalette.accent.withValues(alpha: alpha),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];
}

// Semantic colors - light (paper)
const Color lightSuccessColor = Color(0xFF047857);
const Color lightWarningColor = Color(0xFFB45309);
const Color lightInfoColor = Color(0xFF3F3F46);
const Color lightErrorColor = Color(0xFFBE123C);
const Color lightOnSurfaceColor = AppPalette.paperInk;
const Color lightOutlineColor = AppPalette.paperHairline;
const Color lightSurfaceVariantColor = AppPalette.paperMuted;

// Semantic colors - dark (canvas)
const Color darkSuccessColor = Color(0xFF34D399);
const Color darkWarningColor = Color(0xFFFBBF24);
const Color darkInfoColor = Color(0xFFA1A1AA);
const Color darkErrorColor = Color(0xFFFF4D6D);
const Color darkOnSurfaceColor = AppPalette.ink;
const Color darkOutlineColor = AppPalette.hairline;
const Color darkSurfaceVariantColor = AppPalette.surfaceElevated;

/// Responsive breakpoints
class AppBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double ultraWide = 1440;

  static const double small = 400;
  static const double medium = 600;
  static const double large = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}

enum ScreenSize { mobile, tablet, desktop }

/// Responsive spacing system
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static double responsive(
    BuildContext context, {
    double mobile = md,
    double tablet = lg,
    double desktop = xl,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets horizontalResponsive(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: responsive(context, mobile: md, tablet: lg, desktop: xl),
      );

  static EdgeInsets allResponsive(BuildContext context) =>
      EdgeInsets.all(responsive(context, mobile: md, tablet: lg, desktop: xl));
}

/// Standardized animation durations with premium curves
class AppAnimations {
  static const Duration micro = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration dramatic = Duration(milliseconds: 600);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOutExpo;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve springCurve = Curves.elasticOut;
}

/// Typography System
class AppTypography {
  static double responsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 18.0,
    double desktop = 20.0,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static double responsiveHeadingSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static double responsiveCaptionSize(
    BuildContext context, {
    double mobile = 11.0,
    double tablet = 12.0,
    double desktop = 14.0,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }
}

/// Sizing utilities
class AppSizing {
  static double responsiveIconSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets responsiveCardPadding(BuildContext context) {
    final size = AppBreakpoints.getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(16.0);
      case ScreenSize.tablet:
        return const EdgeInsets.all(20.0);
      case ScreenSize.desktop:
        return const EdgeInsets.all(24.0);
    }
  }

  static int responsiveGridCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 2,
    int desktop = 2,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static double responsiveAspectRatio(
    BuildContext context, {
    double mobile = 0.72,
    double tablet = 0.80,
    double desktop = 0.85,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }

  static double responsiveMaxWidth(BuildContext context) {
    final size = AppBreakpoints.getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 600.0;
      case ScreenSize.desktop:
        return 1200.0;
    }
  }
}

/// Elevation system
class AppElevation {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;

  static const double appBar = level0;
  static const double card = level2;
  static const double button = level1;
  static const double fab = level3;
  static const double dialog = level5;
  static const double bottomSheet = level4;
  static const double menu = level3;

  static double responsive(
    BuildContext context, {
    double mobile = level2,
    double tablet = level3,
    double desktop = level4,
  }) {
    if (AppBreakpoints.isMobile(context)) return mobile;
    if (AppBreakpoints.isTablet(context)) return tablet;
    return desktop;
  }
}

extension AppColors on ColorScheme {
  // Opacity / overlay constants with enhanced dark-mode visibility
  double get overlayLight => brightness == Brightness.dark ? 0.14 : 0.08;
  double get overlayMedium => brightness == Brightness.dark ? 0.24 : 0.14;
  double get overlayHeavy => brightness == Brightness.dark ? 0.36 : 0.22;

  double get shadowLight => brightness == Brightness.dark ? 0.30 : 0.10;

  double get alphaHigh => 0.88;
  double get alphaVeryHigh => 0.96;

  // Glass surfaces - higher opacity for visibility
  double get surfaceHeavy => brightness == Brightness.dark ? 0.95 : 0.85;

  Color get success =>
      brightness == Brightness.light ? lightSuccessColor : darkSuccessColor;
  Color get warning =>
      brightness == Brightness.light ? lightWarningColor : darkWarningColor;
  Color get info =>
      brightness == Brightness.light ? lightInfoColor : darkInfoColor;
  Color get successContainer => success.withValues(alpha: 0.15);
  Color get warningContainer => warning.withValues(alpha: 0.15);
  Color get infoContainer => info.withValues(alpha: 0.15);
  Color get onSuccess =>
      brightness == Brightness.light ? lightOnSurfaceColor : darkOnSurfaceColor;

  Color get textPrimary => onSurface;
  Color get textSecondary => onSurfaceVariant;
  Color get textTertiary => onSurface.withValues(alpha: 0.45);
  Color get surfaceContainer => surfaceContainerHighest;

  /// The page background, as distinct from card surfaces.
  Color get canvas =>
      brightness == Brightness.dark ? AppPalette.canvas : AppPalette.paper;

  /// Recessed well - search fields, inactive chips, code blocks.
  Color get well =>
      brightness == Brightness.dark
          ? AppPalette.surfaceMuted
          : AppPalette.paperMuted;

  /// One step above `surface` - menus, sheets, dialogs.
  Color get elevated =>
      brightness == Brightness.dark
          ? AppPalette.surfaceElevated
          : AppPalette.paperSurface;

  /// The brand accent, already corrected for the current brightness.
  Color get accent =>
      brightness == Brightness.dark
          ? AppPalette.accentBright
          : AppPalette.accent;

  /// Hairline separator.
  Color get hairline =>
      brightness == Brightness.dark
          ? AppPalette.hairline
          : AppPalette.paperHairline;

  // Legacy accent aliases, repointed at the editorial roles.
  Color get accentPink => accent;
  Color get accentBlue => accent;
  Color get accentGreen => success;
}

/// Editorial type devices that aren't part of Material's TextTheme.
extension AppTextStyles on TextTheme {
  /// Uppercase, widely tracked kicker: "TONIGHT · 20:00", "FEATURED".
  TextStyle? get eyebrow => labelSmall;

  /// The number in a date stamp.
  TextStyle? get stamp => headlineMedium?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1,
  );
}

class AppTheme {
  static TextTheme _buildTextTheme(Color color) {
    // Editorial typography.
    // Headlines: Space Grotesk, set tight and heavy so they read as a
    // magazine masthead rather than UI chrome.
    // Body/UI: Inter.
    return TextTheme(
      // Hero text - massive, impactful
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        height: 0.98,
        color: color,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.0,
        color: color,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        height: 1.04,
        color: color,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.08,
        color: color,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.12,
        color: color,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.16,
        color: color,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: color,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color.withValues(alpha: 0.75),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      ),
      // The editorial eyebrow: uppercase, widely tracked, used for kickers
      // like "TONIGHT · 20:00" and section rules.
      labelSmall: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    // Editorial fields sit in a recessed well with no border at rest; the
    // accent only appears on focus, so a form reads as quiet until touched.
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppPalette.surfaceMuted : AppPalette.paperMuted,
      hintStyle: GoogleFonts.inter(
        color: scheme.onSurface.withValues(alpha: 0.40),
        fontSize: 15,
      ),
      labelStyle: GoogleFonts.inter(
        color: scheme.onSurface.withValues(alpha: 0.65),
        fontSize: 15,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: isDark ? AppPalette.accentBright : AppPalette.accent,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: scheme.onSurface.withValues(alpha: 0.50),
      suffixIconColor: scheme.onSurface.withValues(alpha: 0.50),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.9 : 0.7),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(
          color: isDark ? AppPalette.accentBright : AppPalette.accent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    );
  }

  /// The one loud element on a screen: a crimson pill.
  static ButtonStyle _filledButtonStyle(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = isDark ? AppPalette.accentBright : AppPalette.accent;
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 28, vertical: 17),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) return AppPalette.accentDeep;
        return base;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return Colors.white;
      }),
      overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  /// Secondary action: a hairline pill that never competes with the accent.
  static ButtonStyle _outlinedButtonStyle(ColorScheme scheme) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 28, vertical: 17),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return BorderSide(color: scheme.onSurface.withValues(alpha: 0.5));
        }
        return BorderSide(color: scheme.outline, width: 1);
      }),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
      overlayColor: WidgetStatePropertyAll(
        scheme.onSurface.withValues(alpha: 0.06),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  static ButtonStyle _textButtonStyle(ColorScheme scheme) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
      overlayColor: WidgetStatePropertyAll(
        scheme.onSurface.withValues(alpha: 0.06),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  static final ColorScheme _lightScheme = ColorScheme.light(
    primary: AppPalette.accent,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.accentWash,
    onPrimaryContainer: AppPalette.accentDeep,
    secondary: AppPalette.paperInkMuted,
    onSecondary: Colors.white,
    tertiary: AppPalette.accentPurple,
    onTertiary: Colors.white,
    surface: AppPalette.paperSurface,
    surfaceContainerHighest: lightSurfaceVariantColor,
    onSurface: lightOnSurfaceColor,
    onSurfaceVariant: AppPalette.paperInkMuted,
    outline: lightOutlineColor,
    outlineVariant: lightOutlineColor.withValues(alpha: 0.5),
    error: lightErrorColor,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppPalette.accentBright,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.accentWash,
    onPrimaryContainer: AppPalette.accentBright,
    secondary: AppPalette.inkMuted,
    onSecondary: AppPalette.canvas,
    tertiary: AppPalette.accentPurple,
    onTertiary: Colors.white,
    surface: AppPalette.surface,
    surfaceContainerHighest: darkSurfaceVariantColor,
    onSurface: darkOnSurfaceColor,
    onSurfaceVariant: AppPalette.inkMuted,
    outline: darkOutlineColor,
    outlineVariant: darkOutlineColor.withValues(alpha: 0.6),
    error: darkErrorColor,
    brightness: Brightness.dark,
  );

  /// Shared chrome between the two themes, so light stays a true counterpart
  /// of dark rather than a separate design.
  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required Color surface,
    required Color elevated,
    required Color outline,
    required Color snackBg,
    required Color snackFg,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: _buildTextTheme(scheme.onSurface),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      // Elevation by hairline + shadow, never by tint.
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: elevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBg,
        actionTextColor: AppPalette.accentBright,
        contentTextStyle: GoogleFonts.inter(
          color: snackFg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppPalette.surfaceMuted : AppPalette.paper,
        selectedColor: scheme.primary,
        side: BorderSide(color: outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: outline,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppPalette.inkMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isDark ? AppPalette.surfaceElevated : AppPalette.paperMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return outline;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: outline,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(scheme),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(scheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(scheme),
      ),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle(scheme)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ),
        ),
      ),
    );
  }

  static final ThemeData lightTheme = _build(
    scheme: _lightScheme,
    scaffold: AppPalette.paper,
    surface: AppPalette.paperSurface,
    elevated: AppPalette.paperElevated,
    outline: lightOutlineColor,
    snackBg: AppPalette.canvas,
    snackFg: AppPalette.ink,
  );

  static final ThemeData darkTheme = _build(
    scheme: _darkScheme,
    scaffold: AppPalette.canvas,
    surface: AppPalette.surface,
    elevated: AppPalette.surfaceElevated,
    outline: darkOutlineColor,
    snackBg: AppPalette.surfaceElevated,
    snackFg: AppPalette.ink,
  );
}

/// AppDialog
class AppDialog {
  static double responsiveMaxWidth(BuildContext context) =>
      AppBreakpoints.isDesktop(context)
          ? 500
          : (AppBreakpoints.isTablet(context) ? 450 : 400);
  static EdgeInsets responsivePadding(BuildContext context) => EdgeInsets.all(
    AppBreakpoints.isDesktop(context)
        ? 28
        : (AppBreakpoints.isTablet(context) ? 24 : 20),
  );
  static double responsiveTitleSize(BuildContext context) =>
      AppBreakpoints.isDesktop(context)
          ? 24
          : (AppBreakpoints.isTablet(context) ? 22 : 20);
  static double responsiveContentSize(BuildContext context) =>
      AppBreakpoints.isDesktop(context)
          ? 16
          : (AppBreakpoints.isTablet(context) ? 15 : 14);
  static double responsiveBorderRadius(BuildContext context) =>
      AppBreakpoints.isDesktop(context)
          ? 24
          : (AppBreakpoints.isTablet(context) ? 20 : 16);
  static EdgeInsets responsiveButtonPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal:
            AppBreakpoints.isDesktop(context)
                ? 24
                : (AppBreakpoints.isTablet(context) ? 20 : 16),
        vertical:
            AppBreakpoints.isDesktop(context)
                ? 14
                : (AppBreakpoints.isTablet(context) ? 12 : 10),
      );
}
