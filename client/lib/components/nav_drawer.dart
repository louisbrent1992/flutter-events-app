import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/theme.dart';
import '../utils/image_utils.dart';
import '../utils/snackbar_helper.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;
  bool get _isAuthed => _user != null;

  int _upcomingCount(List<dynamic> events) {
    final now = DateTime.now();
    int count = 0;
    for (final e in events) {
      try {
        final startAt = (e as dynamic).startAt as DateTime?;
        if (startAt != null && startAt.isAfter(now)) count++;
      } catch (_) {
        // ignore
      }
    }
    return count;
  }

  void _requireAuthOrNavigate(
    BuildContext context, {
    required String route,
    String? authMessage,
  }) {
    if (_isAuthed) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(route);
      return;
    }

    SnackBarHelper.showInfo(
      context,
      authMessage ?? 'Sign in to use this feature.',
      action: SnackBarAction(
        label: 'Sign in',
        onPressed: () {
          Navigator.of(context).pushNamed(
            '/login',
            arguments: {'redirectRoute': route},
          );
        },
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? const [
                      Color(0xFF1A1B2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ]
                    : const [
                      Color(0xFFFFF8F0),
                      Color(0xFFF7EDF0),
                      Color(0xFFFFE5CC),
                    ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(user: _user),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<EventProvider>(
                  builder: (context, ep, _) {
                    final total =
                        (ep.totalEvents > 0) ? ep.totalEvents : ep.userEvents.length;
                    final upcoming = _upcomingCount(ep.userEvents);
                    return Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            icon: Icons.event_rounded,
                            label: 'Saved',
                            value: _isAuthed ? '$total' : '—',
                            onTap:
                                () => _requireAuthOrNavigate(
                                  context,
                                  route: '/myEvents',
                                  authMessage: 'Sign in to save events.',
                                ),
                            locked: !_isAuthed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            icon: Icons.calendar_month_rounded,
                            label: 'Upcoming',
                            value: _isAuthed ? '$upcoming' : '—',
                            onTap:
                                () => _requireAuthOrNavigate(
                                  context,
                                  route: '/myEvents',
                                  authMessage: 'Sign in to view your upcoming events.',
                                ),
                            locked: !_isAuthed,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _SectionTitle('Navigation'),
                    _NavTile(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/home');
                      },
                    ),
                    _NavTile(
                      icon: Icons.event_available_rounded,
                      title: 'My Events',
                      trailingLocked: !_isAuthed,
                      onTap:
                          () => _requireAuthOrNavigate(
                            context,
                            route: '/myEvents',
                            authMessage: 'Sign in to save events.',
                          ),
                    ),
                    const SizedBox(height: 8),
                    _SectionTitle('Tools'),
                    _NavTile(
                      icon: Icons.add_box_rounded,
                      title: 'Create Event',
                      trailingLocked: !_isAuthed,
                      onTap:
                          () => _requireAuthOrNavigate(
                            context,
                            route: '/createEvent',
                            authMessage: 'Sign in to create events.',
                          ),
                    ),
                    _NavTile(
                      icon: Icons.link_rounded,
                      title: 'Import Event',
                      trailingLocked: !_isAuthed,
                      onTap:
                          () => _requireAuthOrNavigate(
                            context,
                            route: '/importEvent',
                            authMessage: 'Sign in to import events.',
                          ),
                    ),
                    _NavTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Planner',
                      trailingLocked: !_isAuthed,
                      onTap:
                          () => _requireAuthOrNavigate(
                            context,
                            route: '/planner',
                            authMessage: 'Sign in to use the AI planner.',
                          ),
                    ),
                    const SizedBox(height: 8),
                    _SectionTitle('Settings'),
                    _NavTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),
                    _NavTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Subscription',
                      trailingLocked: !_isAuthed,
                      onTap:
                          () => _requireAuthOrNavigate(
                            context,
                            route: '/subscription',
                            authMessage: 'Sign in to manage your subscription.',
                          ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'EventEase • v1.0.9',
                        style: TextStyle(
                          color: (isDark ? Colors.white : cs.onSurface).withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.95),
            secondaryColor.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Consumer<UserProfileProvider>(
            builder: (context, profileProvider, _) {
              final photoUrl =
                  profileProvider.profile['photoURL'] as String? ??
                  user?.photoURL ??
                  ImageUtils.defaultProfileIconUrl;
              return CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child: ClipOval(
                  child:
                      ImageUtils.isAssetPath(photoUrl)
                          ? Image.asset(photoUrl, width: 52, height: 52, fit: BoxFit.cover)
                          : CachedNetworkImage(
                            imageUrl: photoUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? (user == null ? 'Guest' : 'Event Organizer'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? (user == null ? 'Browse mode' : 'Signed in'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user == null)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/login');
              },
              child: const Text('Sign in'),
            )
          else
            Icon(
              Icons.verified_rounded,
              color: Colors.white.withValues(alpha: isDark ? 0.95 : 0.9),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.6,
          color: (isDark ? Colors.white : cs.onSurface).withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool trailingLocked;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: isDark ? Colors.white : cs.onSurface),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : cs.onSurface,
        ),
      ),
      trailing: trailingLocked ? const Icon(Icons.lock_rounded, size: 18) : null,
      onTap: onTap,
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool locked;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.75),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    locked ? '$label  🔒' : label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
