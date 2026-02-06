import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../components/app_tutorial.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';
import 'glass_surface.dart';

/// Premium floating bottom navigation bar with modern aesthetics.
///
/// Features:
/// - Smooth morphing selected indicator
/// - Icon-only design with labels on selection
/// - Haptic feedback on navigation
/// - Gradient glow for active item
/// - Responsive sizing across device types
class FloatingBottomBar extends StatefulWidget {
  const FloatingBottomBar({super.key});

  @override
  State<FloatingBottomBar> createState() => _FloatingBottomBarState();
}

class _FloatingBottomBarState extends State<FloatingBottomBar>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;

  List<_NavItem> _navItems(BuildContext context) {
    final isAuthed = context.read<AuthService>().user != null;

    final items = <_NavItem>[
      _NavItem(
        route: '/home',
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        tutorialKey: TutorialKeys.bottomNavHome,
      ),
      _NavItem(
        route: '/discover',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Discover',
        tutorialKey: TutorialKeys.bottomNavDiscover,
      ),
    ];

    if (isAuthed) {
      items.addAll([
        _NavItem(
          route: '/myEvents',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today_rounded,
          label: 'Calendar',
          tutorialKey: TutorialKeys.bottomNavMyEvents,
        ),
        _NavItem(
          route: '/planner',
          icon: Icons.auto_awesome_outlined,
          activeIcon: Icons.auto_awesome_rounded,
          label: 'AI Planner',
          tutorialKey: TutorialKeys.bottomNavGenerate,
          isAccent: true,
        ),
      ]);
    }

    items.add(
      _NavItem(
        route: '/settings',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        tutorialKey: TutorialKeys.bottomNavSettings,
      ),
    );

    return items;
  }

  int _currentIndex(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final items = _navItems(context);
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == currentRoute) return i;
      // Also highlight AI tab if on import screen
      if (items[i].route == '/planner' && currentRoute == '/importEvent') {
        return i;
      }
    }
    return -1;
  }

  void _handleNavigation(BuildContext context, int index) {
    final items = _navItems(context);
    if (index < 0 || index >= items.length) return;

    final targetRoute = items[index].route;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isAuthed = context.read<AuthService>().user != null;

    // Gate authed-only routes
    final requiresAuth =
        targetRoute == '/myEvents' || targetRoute == '/planner';
    if (!isAuthed && requiresAuth) {
      HapticFeedback.heavyImpact();
      SnackBarHelper.showInfo(context, 'Sign in to use this feature.');
      return;
    }

    // Show AI options sheet for planner route
    if (targetRoute == '/planner') {
      HapticFeedback.selectionClick();
      _showAIOptionsSheet(context);
      return;
    }

    if (currentRoute != targetRoute) {
      HapticFeedback.selectionClick();
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  void _showAIOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppPalette.darkSurfaceElevated : scheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Event',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAIOptionTile(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Event Planner',
                  subtitle: 'Generate events with AI assistance',
                  gradient: AppPalette.heroGradient,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/planner');
                  },
                ),
                _buildAIOptionTile(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Import Event',
                  subtitle: 'Add event from URL or manually',
                  gradient: LinearGradient(
                    colors: [AppPalette.emerald, AppPalette.accentBlue],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/importEvent');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildAIOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show on all screens
    // if (!_shouldShow(context)) return const SizedBox.shrink();

    final items = _navItems(context);
    final currentIndex = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          margin: EdgeInsets.only(
            left: AppSpacing.responsive(
              context,
              mobile: 20,
              tablet: 40,
              desktop: 80,
            ),
            right: AppSpacing.responsive(
              context,
              mobile: 20,
              tablet: 40,
              desktop: 80,
            ),
            bottom: 16 + bottomPadding,
          ),
          child: GlassSurface(
            blurSigma: 24,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            tintColor:
                isDark
                    ? AppPalette.darkSurfaceElevated.withValues(alpha: 0.85)
                    : AppPalette.lightSurface.withValues(alpha: 0.92),
            borderColor:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              if (isDark)
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
            ],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isSelected = i == currentIndex;
                final isHovered = _hoveredIndex == i;

                return TutorialShowcase(
                  showcaseKey: item.tutorialKey,
                  title: item.label,
                  description: _getDescription(item.route),
                  isCircular: true,
                  targetPadding: const EdgeInsets.all(12),
                  child: _buildNavItem(
                    context,
                    item: item,
                    isSelected: isSelected,
                    isHovered: isHovered,
                    onTap: () => _handleNavigation(context, i),
                    onHover: (hovered) {
                      setState(() => _hoveredIndex = hovered ? i : null);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required _NavItem item,
    required bool isSelected,
    required bool isHovered,
    required VoidCallback onTap,
    required ValueChanged<bool> onHover,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final iconSize = AppSizing.responsiveIconSize(
      context,
      mobile: 22,
      tablet: 24,
      desktop: 26,
    );

    // Determine colors
    Color iconColor;
    Color? bgColor;
    List<BoxShadow>? shadows;

    if (isSelected) {
      if (item.isAccent) {
        iconColor = Colors.white;
        bgColor = isDark ? AppPalette.primaryBlue : AppPalette.primaryBlue;
        shadows = [
          BoxShadow(
            color: (isDark ? AppPalette.primaryBlue : AppPalette.primaryBlue)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ];
      } else {
        iconColor = isDark ? Colors.white : scheme.onPrimary;
        bgColor = scheme.primary;
        shadows = [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ];
      }
    } else {
      iconColor = scheme.onSurface.withValues(alpha: isHovered ? 0.85 : 0.55);
      bgColor = isHovered ? scheme.primary.withValues(alpha: 0.08) : null;
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.defaultCurve,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppAnimations.fast,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey('${item.route}_$isSelected'),
                  size: iconSize,
                  color: iconColor,
                ),
              ),
              // Animated label that expands when selected
              AnimatedSize(
                duration: AppAnimations.standard,
                curve: AppAnimations.defaultCurve,
                child:
                    isSelected
                        ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            item.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription(String route) {
    switch (route) {
      case '/home':
        return 'Your personalized event feed';
      case '/discover':
        return 'Explore events and map';
      case '/myEvents':
        return 'Your saved events';
      case '/planner':
        return 'AI-powered event planning';
      case '/settings':
        return 'Profile and preferences';
      default:
        return '';
    }
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final GlobalKey tutorialKey;
  final bool isAccent;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tutorialKey,
    this.isAccent = false,
  });
}
