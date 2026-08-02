import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../components/app_tutorial.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';
import 'glass_surface.dart';

/// Editorial bottom navigation.
///
/// A floating bar on a near-solid elevated surface with a hairline edge.
/// Every destination shows its icon and label at all times - the active one
/// is marked by a short accent rule above it and by taking the accent colour.
/// Nothing morphs, nothing glows: the bar stays quiet so the photography
/// above it carries the screen.
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: EdgeInsets.only(
              left: 14,
              right: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: scheme.elevated,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: scheme.hairline),
              boxShadow: AppShadows.lifted(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'CREATE',
                    style: theme.textTheme.eyebrow?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildAIOptionTile(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI event planner',
                  subtitle: 'Generate a plan from a prompt',
                  gradient: AppPalette.energyGradient,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/planner');
                  },
                ),
                _buildAIOptionTile(
                  context,
                  icon: Icons.link_rounded,
                  title: 'Import an event',
                  subtitle: 'From a URL, or enter it manually',
                  gradient: AppPalette.heroGradient,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
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
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: scheme.onSurface.withValues(alpha: 0.35),
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
            blurSigma: 28,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            tintColor: (isDark
                    ? AppPalette.surfaceElevated
                    : AppPalette.paperSurface)
                .withValues(alpha: isDark ? 0.88 : 0.94),
            borderColor: scheme.hairline,
            boxShadow: AppShadows.lifted(context),
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

    final iconSize = AppSizing.responsiveIconSize(
      context,
      mobile: 21,
      tablet: 23,
      desktop: 24,
    );

    // The accent marks the active destination and nothing else.
    final Color fg =
        isSelected
            ? scheme.accent
            : scheme.onSurface.withValues(alpha: isHovered ? 0.80 : 0.45);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent rule above the active item.
              AnimatedContainer(
                duration: AppAnimations.standard,
                curve: AppAnimations.defaultCurve,
                height: 2,
                width: isSelected ? 18 : 0,
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: scheme.accent,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: iconSize,
                color: fg,
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontSize: 9.5,
                  letterSpacing: 0.4,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
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
