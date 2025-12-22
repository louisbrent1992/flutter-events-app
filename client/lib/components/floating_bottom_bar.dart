import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/app_tutorial.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

/// Recipease-style floating bottom navigation bar (route-based).
///
/// - Tabs change based on auth state.
/// - Selected state is derived from `ModalRoute.of(context)?.settings.name`.
/// - Uses `Navigator.pushNamed` to switch routes.
class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({super.key});

  List<String> _navRoutes(BuildContext context) {
    final isAuthed = context.read<AuthService>().user != null;

    // Guest mode: Home, Discover, Settings.
    if (!isAuthed) {
      return const ['/home', '/discover', '/settings'];
    }

    // Authed mode: Home, Discover, My Events, Planner, Settings.
    return const ['/home', '/discover', '/myEvents', '/planner', '/settings'];
  }

  bool _shouldShow(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (currentRoute.isEmpty) return false;
    return _navRoutes(context).contains(currentRoute);
  }

  bool _isNavSelected(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final routes = _navRoutes(context);
    if (index < 0 || index >= routes.length) return false;
    return currentRoute == routes[index];
  }

  void _handleNavigation(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final routes = _navRoutes(context);
    if (index < 0 || index >= routes.length) return;

    final targetRoute = routes[index];
    final isAuthed = context.read<AuthService>().user != null;

    // Gate authed-only routes when in guest mode.
    final requiresAuth =
        targetRoute == '/myEvents' || targetRoute == '/planner';
    if (!isAuthed && requiresAuth) {
      SnackBarHelper.showInfo(context, 'Sign in to use this feature.');
      return;
    }

    if (currentRoute != targetRoute) {
      Navigator.pushNamed(context, targetRoute);
    }
  }

  Widget _navIcon({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.65);

    final size = AppSizing.responsiveIconSize(
      context,
      mobile: 22,
      tablet: 26,
      desktop: 28,
    );

    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Icon(icon, color: color, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow(context)) return const SizedBox.shrink();

    final isAuthed = context.watch<AuthService>().user != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Heights mirror Recipease intent: compact but tappable.
    final height =
        AppBreakpoints.isDesktop(context)
            ? 54.0
            : AppBreakpoints.isTablet(context)
            ? 50.0
            : 44.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          margin: EdgeInsets.only(
            left: AppSpacing.responsive(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
            right: AppSpacing.responsive(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
            bottom:
                AppSpacing.responsive(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ) +
                bottomPadding,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: Theme.of(context).colorScheme.surfaceHeavy,
            ),
            borderRadius: BorderRadius.circular(
              AppBreakpoints.isDesktop(context) ? 26 : 20,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: Theme.of(context).colorScheme.shadowLight,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavHome,
                title: 'Home',
                description: 'Your dashboard and quick actions.',
                isCircular: true,
                targetPadding: const EdgeInsets.all(12),
                child: _navIcon(
                  context: context,
                  icon: Icons.home_rounded,
                  isSelected: _isNavSelected(context, 0),
                  onTap: () => _handleNavigation(context, 0),
                ),
              ),
              TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavDiscover,
                title: 'Discover',
                description: 'Explore events and trends.',
                isCircular: true,
                targetPadding: const EdgeInsets.all(12),
                child: _navIcon(
                  context: context,
                  icon: Icons.explore_rounded,
                  isSelected: _isNavSelected(context, 1),
                  onTap: () => _handleNavigation(context, 1),
                ),
              ),
              if (isAuthed)
                TutorialShowcase(
                  showcaseKey: TutorialKeys.bottomNavMyEvents,
                  title: 'My Events',
                  description: 'Your saved events.',
                  isCircular: true,
                  targetPadding: const EdgeInsets.all(12),
                  child: _navIcon(
                    context: context,
                    icon: Icons.event_available_rounded,
                    isSelected: _isNavSelected(context, 2),
                    onTap: () => _handleNavigation(context, 2),
                  ),
                ),
              if (isAuthed)
                TutorialShowcase(
                  showcaseKey: TutorialKeys.bottomNavGenerate,
                  title: 'Planner',
                  description: 'Plan your night with AI.',
                  isCircular: true,
                  targetPadding: const EdgeInsets.all(12),
                  child: _navIcon(
                    context: context,
                    icon: Icons.auto_awesome_rounded,
                    isSelected: _isNavSelected(context, 3),
                    onTap: () => _handleNavigation(context, 3),
                  ),
                ),
              TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavSettings,
                title: 'Settings',
                description: 'Preferences and account.',
                isCircular: true,
                targetPadding: const EdgeInsets.all(12),
                child: _navIcon(
                  context: context,
                  icon: Icons.settings_rounded,
                  isSelected: _isNavSelected(context, isAuthed ? 4 : 2),
                  onTap: () => _handleNavigation(context, isAuthed ? 4 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
