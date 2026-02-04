import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/theme.dart';
import 'glass_surface.dart';

/// Premium navigation drawer with gradient hero and organized links.
///
/// Features:
/// - Gradient header with user avatar
/// - Glass-morphic navigation tiles
/// - Pro subscription badge
/// - Quick theme toggle
/// - Modern iconography
class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final profile = context.watch<UserProfileProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isAuthed = auth.user != null;
    final isPremium = subscription.isPremium;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    final displayName =
        (profile.profile['displayName'] as String?) ??
        auth.user?.displayName ??
        (isAuthed ? 'Event Organizer' : 'Guest');
    final email = auth.user?.email ?? 'Explore mode';
    final photoUrl = _photoUrl(profile.profile, auth.user?.photoURL);

    return Drawer(
      backgroundColor: isDark ? AppPalette.darkBg : AppPalette.lightBg,
      width: 300,
      child: Column(
        children: [
          // Header
          _buildHeader(
            context,
            displayName: displayName,
            email: email,
            photoUrl: photoUrl,
            isAuthed: isAuthed,
            isPremium: isPremium,
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // Primary navigation
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentRoute == '/home',
                  onTap: () => _navigate(context, '/home'),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  isSelected: currentRoute == '/discover',
                  onTap: () => _navigate(context, '/discover'),
                ),
                _NavItem(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  isSelected: currentRoute == '/map',
                  onTap: () => _navigate(context, '/map'),
                ),
                if (isAuthed) ...[
                  _NavItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'My Events',
                    isSelected: currentRoute == '/myEvents',
                    onTap: () => _navigate(context, '/myEvents'),
                  ),
                  _NavItem(
                    icon: Icons.collections_bookmark_rounded,
                    label: 'Collections',
                    isSelected: currentRoute == '/collections',
                    onTap: () => _navigate(context, '/collections'),
                  ),
                ],

                const SizedBox(height: 8),
                Divider(
                  color: scheme.outline.withValues(alpha: 0.1),
                  indent: 8,
                  endIndent: 8,
                ),
                const SizedBox(height: 8),

                // Tools
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'TOOLS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.link_rounded,
                  label: 'Import Event',
                  isSelected: currentRoute == '/importEvent',
                  accentColor: AppPalette.accentBlue,
                  onTap: () => _navigate(context, '/importEvent'),
                ),
                _NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Event',
                  isSelected: currentRoute == '/createEvent',
                  accentColor: AppPalette.emerald,
                  onTap: () => _navigate(context, '/createEvent'),
                ),
                if (isAuthed)
                  _NavItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Planner',
                    isSelected: currentRoute == '/planner',
                    accentColor: AppPalette.amber,
                    badge: isPremium ? null : 'PRO',
                    onTap: () => _navigate(context, '/planner'),
                  ),

                const SizedBox(height: 8),
                Divider(
                  color: scheme.outline.withValues(alpha: 0.1),
                  indent: 8,
                  endIndent: 8,
                ),
                const SizedBox(height: 8),

                // Settings & Support
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () => _navigate(context, '/settings'),
                ),
                _NavItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _navigate(context, '/settings'),
                ),
              ],
            ),
          ),

          // Footer with theme toggle
          _buildFooter(context, themeProvider),
        ],
      ),
    );
  }

  String? _photoUrl(Map<String, dynamic> profile, String? fallback) {
    final url = (profile['photoURL'] as String?) ?? fallback;
    final v = (url ?? '').trim();
    return v.isEmpty ? null : v;
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (currentRoute != route) {
      HapticFeedback.selectionClick();
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Widget _buildHeader(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? photoUrl,
    required bool isAuthed,
    required bool isPremium,
  }) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.primaryBlue.withValues(alpha: 0.4),
            AppPalette.accentBlue.withValues(alpha: 0.3),
            AppPalette.slate.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: photoUrl == null ? AppPalette.accentGradient : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      photoUrl == null
                          ? Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: Colors.white.withValues(alpha: 0.9),
                          )
                          : CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                ),
              ),
              const Spacer(),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppPalette.amber,
                        AppPalette.amber.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.amber.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          if (!isAuthed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppPalette.primaryBlue,
                ),
                child: const Text('Sign In'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = themeProvider.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + bottomPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: GlassSurface(
        blurSigma: 16,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    isDark
                        ? () {
                          HapticFeedback.selectionClick();
                          themeProvider.toggleTheme();
                        }
                        : null,
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !isDark ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.light_mode_rounded,
                    size: 20,
                    color:
                        !isDark
                            ? Colors.white
                            : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap:
                    !isDark
                        ? () {
                          HapticFeedback.selectionClick();
                          themeProvider.toggleTheme();
                        }
                        : null,
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.dark_mode_rounded,
                    size: 20,
                    color:
                        isDark
                            ? AppPalette.darkBg
                            : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color? accentColor;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? color.withValues(alpha: 0.2)
                            : scheme.surfaceContainerHighest.withValues(
                              alpha: isDark ? 0.3 : 0.5,
                            ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color:
                        isSelected
                            ? color
                            : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected
                              ? color
                              : scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppPalette.amber,
                          AppPalette.amber.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
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
