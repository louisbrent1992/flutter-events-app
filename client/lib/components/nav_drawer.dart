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
                  color: scheme.hairline,
                  indent: 8,
                  endIndent: 8,
                ),
                const SizedBox(height: 8),

                // Tools
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'TOOLS',
                    style: theme.textTheme.eyebrow?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.link_rounded,
                  label: 'Import Event',
                  isSelected: currentRoute == '/importEvent',
                  onTap: () => _navigate(context, '/importEvent'),
                ),
                _NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Event',
                  isSelected: currentRoute == '/createEvent',
                  onTap: () => _navigate(context, '/createEvent'),
                ),
                if (isAuthed)
                  _NavItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Planner',
                    isSelected: currentRoute == '/planner',
                    badge: isPremium ? null : 'PRO',
                    onTap: () => _navigate(context, '/planner'),
                  ),

                const SizedBox(height: 8),
                Divider(
                  color: scheme.hairline,
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
      if (route == '/home') {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        Navigator.pushNamed(context, route);
      }
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
      // Flat masthead: no gradient. The drawer is chrome, so it stays on
      // canvas and is separated by a hairline rather than a colour block.
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.well,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.hairline,
                  ),
                ),
                child: ClipOval(
                  child:
                      photoUrl == null
                          ? Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          )
                          : CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 24,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                ),
              ),
              const Spacer(),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(color: AppPalette.amber, width: 1),
                  ),
                  child: Text(
                    'PRO',
                    style: theme.textTheme.eyebrow?.copyWith(
                      color: AppPalette.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isAuthed) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Sign in'),
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
          top: BorderSide(color: scheme.hairline),
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
                            ? Colors.white
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
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // One accent across the whole drawer - per-item colours turned the nav
    // into a colour chart and competed with the event photography.
    final color = scheme.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? scheme.well : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border(
                left: BorderSide(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? color : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? scheme.onSurface : scheme.onSurface,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: AppPalette.amber),
                    ),
                    child: Text(
                      badge!,
                      style: theme.textTheme.eyebrow?.copyWith(
                        color: AppPalette.amber,
                        fontSize: 9,
                      ),
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
