import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Corporate Event App Palette
///
/// Clean, refined color scheme for a business-appropriate aesthetic
/// Deep blues, slate grays, and subtle warm accents
class AppPalette {
  // Core brand colors - Professional & Refined
  static const Color primaryBlue = Color.fromARGB(
    255,
    30,
    64,
    175,
  ); // Deep corporate blue
  static const Color accentBlue = Color.fromARGB(
    255,
    59,
    130,
    246,
  ); // Bright accent blue
  static const Color slate = Color.fromARGB(
    255,
    71,
    85,
    105,
  ); // Professional gray
  static const Color emerald = Color(0xFF059669); // Success green
  static const Color amber = Color(0xFFD97706); // Warm accent
  static const Color warmGray = Color(0xFF78716C); // Neutral warm
  static const Color accentPurple = Color(0xFF8B5CF6); // Purple accent

  // Dark Mode - Refined, Professional
  static const Color darkBg = Color(0xFF0F172A); // Slate-900
  static const Color darkSurface = Color(0xFF1E293B); // Slate-800
  static const Color darkSurfaceElevated = Color(0xFF334155); // Slate-700
  static const Color darkSurfaceMuted = Color(0xFF1E293B);
  static const Color darkInk = Color(0xFFF8FAFC); // Slate-50

  // Light Mode - Clean, Professional
  static const Color lightBg = Color(0xFFF8FAFC); // Slate-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate-100
  static const Color lightSurfaceMuted = Color(0xFFE2E8F0); // Slate-200
  static const Color lightInk = Color(0xFF0F172A); // Slate-900

  // Subtle Professional Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentBlue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF2563EB)], // Subtle blue shift
  );

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, Color(0xFF10B981)], // Subtle green shift
  );
}

class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

// Semantic colors for light theme - Professional
const Color lightSuccessColor = Color(0xFF059669); // Emerald-600
const Color lightWarningColor = Color(0xFFD97706); // Amber-600
const Color lightInfoColor = Color(0xFF0284C7); // Sky-600
const Color lightErrorColor = Color(0xFFDC2626); // Red-600
const Color lightOnSurfaceColor = AppPalette.lightInk;
const Color lightOutlineColor = Color(0xFFCBD5E1); // Slate-300
const Color lightSurfaceVariantColor = Color(0xFFF1F5F9); // Slate-100

// Semantic colors for dark theme - Professional
const Color darkSuccessColor = Color(0xFF10B981); // Emerald-500
const Color darkWarningColor = Color(0xFFF59E0B); // Amber-500
const Color darkInfoColor = Color(0xFF0EA5E9); // Sky-500
const Color darkErrorColor = Color(0xFFEF4444); // Red-500
const Color darkOnSurfaceColor = AppPalette.darkInk;
const Color darkOutlineColor = Color(0xFF475569); // Slate-600
const Color darkSurfaceVariantColor = Color(0xFF334155); // Slate-700

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
  Color get textTertiary => outline;
  Color get surfaceContainer => surfaceContainerHighest;

  // Premium accent colors - Professional
  Color get accentPink =>
      brightness == Brightness.dark
          ? AppPalette.emerald
          : AppPalette.emerald.withValues(alpha: 0.9);
  Color get accentBlue =>
      brightness == Brightness.dark
          ? AppPalette.accentBlue
          : AppPalette.accentBlue.withValues(alpha: 0.9);
  Color get accentGreen =>
      brightness == Brightness.dark
          ? AppPalette.emerald
          : AppPalette.emerald.withValues(alpha: 0.9);
}

class AppTheme {
  static TextTheme _buildTextTheme(Color color) {
    // Modern geometric typography
    // Headlines: Space Grotesk (bold, geometric)
    // Body/UI: Inter (clean, readable)
    return TextTheme(
      // Hero text - massive, impactful
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        height: 1.0,
        color: color,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.05,
        color: color,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
        color: color,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.12,
        color: color,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: color,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.2,
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
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor:
          isDark
              ? AppPalette.darkSurfaceElevated.withValues(alpha: 0.6)
              : AppPalette.lightSurfaceMuted.withValues(alpha: 0.8),
      hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
      labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
      prefixIconColor: scheme.onSurface.withValues(alpha: 0.55),
      suffixIconColor: scheme.onSurface.withValues(alpha: 0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: AppPalette.accentBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ButtonStyle _filledButtonStyle(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      backgroundColor: WidgetStatePropertyAll(
        isDark ? AppPalette.accentBlue : AppPalette.primaryBlue,
      ),
      foregroundColor: WidgetStatePropertyAll(
        isDark ? AppPalette.darkBg : Colors.white,
      ),
      overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.1)),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle(ColorScheme scheme) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: scheme.outline.withValues(alpha: 0.4), width: 1.5),
      ),
      foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
      overlayColor: WidgetStatePropertyAll(
        scheme.primary.withValues(alpha: 0.08),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  static final ColorScheme _lightScheme = ColorScheme.light(
    primary: AppPalette.primaryBlue,
    secondary: AppPalette.slate,
    tertiary: AppPalette.accentBlue,
    onTertiary: AppPalette.lightInk,
    surface: AppPalette.lightSurface,
    surfaceContainerHighest: lightSurfaceVariantColor,
    onSurface: lightOnSurfaceColor,
    onSurfaceVariant: lightOnSurfaceColor.withValues(alpha: 0.6),
    outline: lightOutlineColor,
    outlineVariant: lightOutlineColor.withValues(alpha: 0.4),
    error: lightErrorColor,
    onPrimary: Colors.white,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppPalette.accentBlue,
    secondary: AppPalette.slate,
    tertiary: AppPalette.emerald,
    onTertiary: AppPalette.darkInk,
    surface: AppPalette.darkSurface,
    surfaceContainerHighest: darkSurfaceVariantColor,
    onSurface: darkOnSurfaceColor,
    onSurfaceVariant: darkOnSurfaceColor.withValues(alpha: 0.6),
    outline: darkOutlineColor,
    outlineVariant: darkOutlineColor.withValues(alpha: 0.5),
    error: darkErrorColor,
    onPrimary: AppPalette.darkBg,
    brightness: Brightness.dark,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: AppPalette.lightBg,
    textTheme: _buildTextTheme(lightOnSurfaceColor),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.lightSurface.withValues(alpha: 0.98),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppPalette.lightSurface.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: BorderSide(
          color: lightOutlineColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: lightOutlineColor.withValues(alpha: 0.2),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.darkSurface.withValues(alpha: 0.95),
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppPalette.lightSurface.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(
          color: lightOutlineColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: _inputTheme(_lightScheme),
    filledButtonTheme: FilledButtonThemeData(
      style: _filledButtonStyle(_lightScheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _outlinedButtonStyle(_lightScheme),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primaryBlue;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return lightOnSurfaceColor.withValues(alpha: 0.7);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: lightOutlineColor.withValues(alpha: 0.3)),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: AppPalette.darkBg,
    textTheme: _buildTextTheme(darkOnSurfaceColor),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.darkSurfaceElevated.withValues(alpha: 0.98),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppPalette.darkSurfaceMuted.withValues(alpha: 0.7),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: BorderSide(
          color: darkOutlineColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkOutlineColor.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.darkSurfaceElevated.withValues(alpha: 0.98),
      contentTextStyle: GoogleFonts.inter(
        color: AppPalette.darkInk,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppPalette.darkSurfaceElevated.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(
          color: darkOutlineColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: _inputTheme(_darkScheme),
    filledButtonTheme: FilledButtonThemeData(
      style: _filledButtonStyle(_darkScheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _outlinedButtonStyle(_darkScheme),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.accentBlue;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.darkBg;
          }
          return darkOnSurfaceColor.withValues(alpha: 0.7);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: darkOutlineColor.withValues(alpha: 0.5)),
        ),
      ),
    ),
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
