import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Deep Forest & Metallic Gold Palette ---
const Color primaryColor = Color(0xFF1B4332); // Deep Forest Green
Color secondaryColor = const Color(
  0xFF2D6A4F,
).withValues(alpha: 0.8); // Medium Forest
const Color backgroundColor = Color(0xFFF8F9F8); // Crisp Off-White
const Color accentColor = Color(0xFFD4AF37); // Classic Gold
const Color neutralColor = Color(0xFFE9ECEF); // Light Grey-Green
const Color charcoalColor = Color(0xFF403D39); // Deep Onyx

// Dark theme colors
const Color darkPrimaryColor = Color(0xFF081C15); // Deepest Forest
const Color darkSecondaryColor = Color(0xFF1B4332); // Dark Forest
const Color darkBackgroundColor = Color(0xFF0D1B1E); // Midnight Green
const Color darkAccentColor = Color(0xFFC5A059); // Metallic Antique Gold
const Color darkNeutralColor = Color(0xFF2D6A4F); // Muted Forest
const Color darkPurpleColor = Color(0xFFC5A059); // Metallic Gold accent

// Semantic colors for light theme
const Color lightSuccessColor = Color(0xFF4CAF50); // Green
const Color lightWarningColor = Color(0xFFFF9800); // Orange
const Color lightInfoColor = Color(0xFF2196F3); // Blue
const Color lightErrorColor = Color(0xFFF44336); // Red
const Color lightOnSurfaceColor = Color(0xFF1C1B1F); // Dark text
const Color lightOutlineColor = Color(0xFF79747E); // Border/outline
const Color lightSurfaceVariantColor = Color(0xFFF3EDF7); // Surface variant

// Semantic colors for dark theme
const Color darkSuccessColor = Color(0xFF81C784); // Light green
const Color darkWarningColor = Color(0xFFFFB74D); // Light orange
const Color darkInfoColor = Color(0xFF64B5F6); // Light blue
const Color darkErrorColor = Color(0xFFEF5350); // Light red
const Color darkOnSurfaceColor = Color(0xFFE6E1E5); // Light text
const Color darkOutlineColor = Color(0xFF938F99); // Light border/outline
const Color darkSurfaceVariantColor = Color(0xFF49454F); // Dark surface variant

/// Responsive breakpoints - ORIGINAL
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

/// Responsive spacing system - ORIGINAL
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

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

/// Standardized animation durations - ORIGINAL
class AppAnimations {
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.easeOutBack;
}

/// Typography System - ORIGINAL
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

/// Sizing utilities - ORIGINAL
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
        return const EdgeInsets.all(12.0);
      case ScreenSize.tablet:
        return const EdgeInsets.all(16.0);
      case ScreenSize.desktop:
        return const EdgeInsets.all(20.0);
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

/// Elevation system - ORIGINAL
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
  Color get success =>
      brightness == Brightness.light ? lightSuccessColor : darkSuccessColor;
  Color get warning =>
      brightness == Brightness.light ? lightWarningColor : darkWarningColor;
  Color get info =>
      brightness == Brightness.light ? lightInfoColor : darkInfoColor;
  Color get successContainer => success.withValues(alpha: 0.1);
  Color get warningContainer => warning.withValues(alpha: 0.1);
  Color get infoContainer => info.withValues(alpha: 0.1);
  Color get onSuccess =>
      brightness == Brightness.light ? lightOnSurfaceColor : darkOnSurfaceColor;

  Color get textPrimary => onSurface;
  Color get textSecondary => onSurfaceVariant;
  Color get textTertiary => outline;
  Color get surfaceContainer => surfaceContainerHighest;
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onTertiary: charcoalColor,
      surface: backgroundColor,
      surfaceContainerHighest: lightSurfaceVariantColor,
      onSurface: lightOnSurfaceColor,
      onSurfaceVariant: lightOnSurfaceColor.withValues(alpha: 0.6),
      outline: lightOutlineColor,
      outlineVariant: lightOutlineColor.withValues(alpha: 0.3),
      error: lightErrorColor,
      onPrimary: backgroundColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: neutralColor,
    textTheme: _buildTextTheme(lightOnSurfaceColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: darkAccentColor, // Metallic Gold
      secondary: darkSecondaryColor,
      tertiary: darkAccentColor,
      onTertiary: darkPurpleColor,
      surface: darkBackgroundColor,
      surfaceContainerHighest: darkOnSurfaceColor,
      onSurface: darkOnSurfaceColor,
      onSurfaceVariant: darkOnSurfaceColor.withValues(alpha: 0.6),
      outline: darkOutlineColor,
      outlineVariant: darkOutlineColor.withValues(alpha: 0.3),
      error: darkErrorColor,
      onPrimary: darkPrimaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkSecondaryColor,
    textTheme: _buildTextTheme(darkOnSurfaceColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccentColor,
        foregroundColor: darkPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      bodyLarge: GoogleFonts.sourceSans3(fontSize: 16, color: color),
      bodyMedium: GoogleFonts.sourceSans3(fontSize: 14, color: color),
      labelLarge: GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

/// AppDialog - ORIGINAL
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
