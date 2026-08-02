import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../components/custom_app_bar.dart';
import '../components/floating_bottom_bar.dart';
import '../components/glass_surface.dart';
import '../components/nav_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../config/app_config.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

/// Premium Settings screen with bento-grid layout.
///
/// Features:
/// - Hero profile card with gradient background
/// - Bento-grid style settings sections
/// - Visual theme toggle with preview
/// - Quick action buttons
/// - Premium subscription status indicator
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _editingName = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  User? get _user => FirebaseAuth.instance.currentUser;

  static const String _prefsBox = 'preferences';
  static const String _kAllowReminders = 'settings_allow_reminders';
  static const String _kAllowPromos = 'settings_allow_promos';

  String? _photoUrl(Map<String, dynamic> profile) {
    final url = (profile['photoURL'] as String?) ?? _user?.photoURL;
    final v = (url ?? '').trim();
    return v.isEmpty ? null : v;
  }

  bool _getBool(String key, bool fallback) {
    try {
      final box = Hive.box(_prefsBox);
      final v = box.get(key);
      return v is bool ? v : fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final box = Hive.box(_prefsBox);
      await box.put(key, value);
    } catch (_) {}
  }

  Future<void> _openSystemNotificationSettings(BuildContext context) async {
    try {
      final ok = await openAppSettings();
      if (!ok && context.mounted) {
        SnackBarHelper.showInfo(
          context,
          'Open Settings to manage notifications for Spark Events.',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.showInfo(
        context,
        'Open Settings to manage notifications for Spark Events.',
      );
    }
  }

  Future<void> _contactSupport(BuildContext context, {String? subject}) async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final platform =
        Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Other');

    final uri = Uri(
      scheme: 'mailto',
      path: 'support@eventease.app',
      queryParameters: <String, String>{
        'subject': subject ?? 'Spark Events Support',
        'body': [
          'Hi Spark Events team,',
          '',
          'What I need help with:',
          '',
          '---',
          'Diagnostics:',
          'Platform: $platform',
          'App: Spark Events • v1.0.0',
          'Server: $base',
        ].join('\n'),
      },
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      SnackBarHelper.showError(
        context,
        'Could not open your email app. Please email support@eventease.app.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final provider = context.read<UserProfileProvider>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackBarHelper.showInfo(context, 'Please enter a name.');
      return;
    }
    try {
      await provider.updateProfile(displayName: name);
      if (!mounted) return;
      setState(() => _editingName = false);
      SnackBarHelper.showSuccess(context, 'Profile updated.');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();
    final subscription = context.watch<SubscriptionProvider>();
    final isAuthed = auth.user != null;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allowReminders = _getBool(_kAllowReminders, true);
    final allowPromos = _getBool(_kAllowPromos, false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const NavDrawer(),
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: EdgeInsets.only(
                  left: AppSpacing.responsive(context),
                  right: AppSpacing.responsive(context),
                  top: AppSpacing.sm,
                  bottom: 140,
                ),
                children: [
                  // ── Profile hero ────────────────────────────
                  Consumer<UserProfileProvider>(
                    builder: (context, profile, _) {
                      final displayName =
                          (profile.profile['displayName'] as String?) ??
                          _user?.displayName ??
                          (isAuthed ? 'Event Organizer' : 'Guest');
                      final email =
                          (profile.profile['email'] as String?) ??
                          _user?.email ??
                          (isAuthed ? 'Signed in' : 'Browse mode');
                      if (!_editingName) _nameController.text = displayName;
                      final photoUrl = _photoUrl(profile.profile);

                      return _buildProfileHero(
                        context,
                        displayName: displayName,
                        email: email,
                        photoUrl: photoUrl,
                        isAuthed: isAuthed,
                        isPremium: subscription.isPremium,
                        subscription: subscription,
                        onEditProfile:
                            isAuthed
                                ? () async {
                                  try {
                                    await profile.uploadProfilePicture();
                                    if (!context.mounted) return;
                                    SnackBarHelper.showSuccess(
                                      context,
                                      'Photo updated',
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    SnackBarHelper.showError(
                                      context,
                                      'Could not update photo',
                                    );
                                  }
                                }
                                : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Name editing sheet
                  if (isAuthed && _editingName) _buildNameEditCard(context),
                  if (isAuthed && _editingName) const SizedBox(height: 16),

                  // Quick actions (for authed users)
                  if (isAuthed) ...[
                    _buildQuickActionsRow(context),
                    const SizedBox(height: 24),
                  ],

                  // Appearance Section
                  _buildSectionTitle(context, 'Appearance'),
                  const SizedBox(height: 12),
                  _buildThemeToggle(context, themeProvider),
                  const SizedBox(height: 24),

                  // Organizer Tools (for authed users)
                  if (isAuthed) ...[
                    _buildSectionTitle(context, 'Organizer Tools'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      items: [
                        _SettingsItem(
                          icon: Icons.collections_bookmark_rounded,
                          title: 'Collections',
                          subtitle: 'Organize events into lists',
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/collections'),
                        ),
                        _SettingsItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'My Events',
                          subtitle: 'View your saved events',
                          onTap:
                              () => Navigator.pushNamed(context, '/myEvents'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notifications Section
                  _buildSectionTitle(context, 'Notifications'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Event reminders',
                        subtitle: 'Get notified before events start',
                        trailing: Switch.adaptive(
                          value: allowReminders,
                          onChanged: (v) async {
                            HapticFeedback.selectionClick();
                            await _setBool(_kAllowReminders, v);
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.campaign_rounded,
                        title: 'Product updates',
                        subtitle: 'Occasional news and features',
                        trailing: Switch.adaptive(
                          value: allowPromos,
                          onChanged: (v) async {
                            HapticFeedback.selectionClick();
                            await _setBool(_kAllowPromos, v);
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.settings_rounded,
                        title: 'System settings',
                        subtitle: 'Manage permissions',
                        onTap: () => _openSystemNotificationSettings(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionTitle(context, 'Support'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    items: [
                      _SettingsItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help center',
                        subtitle: 'FAQs and guides',
                        onTap: () => _contactSupport(context),
                      ),
                      _SettingsItem(
                        icon: Icons.bug_report_outlined,
                        title: 'Report a bug',
                        subtitle: 'Help us improve',
                        onTap:
                            () =>
                                _contactSupport(context, subject: 'Bug Report'),
                      ),
                      _SettingsItem(
                        icon: Icons.star_outline_rounded,
                        title: 'Review app',
                        subtitle:
                            Platform.isIOS
                                ? 'Rate us on the App Store'
                                : 'Rate us on Google Play',
                        onTap: () {
                          // Placeholder for store review integration
                          SnackBarHelper.showInfo(
                            context,
                            'Store review coming soon!',
                          );
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy & data',
                        subtitle: 'View our privacy policy',
                        onTap: () async {
                          final base = AppConfig.apiUrl.replaceFirst(
                            RegExp(r'/api/?$'),
                            '',
                          );
                          final uri = Uri.parse('$base/data-deletion');
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign out / Sign in
                  if (isAuthed)
                    _buildSignOutButton(context, auth)
                  else
                    _buildSignInButton(context),

                  const SizedBox(height: 32),

                  // App version
                  Center(
                    child: Text(
                      'Spark Events • v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FloatingBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProfileHero(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? photoUrl,
    required bool isAuthed,
    required bool isPremium,
    required SubscriptionProvider subscription,
    VoidCallback? onEditProfile,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final importCredits = subscription.credits['eventImports'] ?? 0;
    final aiCredits = subscription.credits['aiPlans'] ?? 0;

    // Left-aligned masthead rather than a centred badge card: name reads as
    // a headline, credits as a fact strip beneath a rule.
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEditProfile,
                child: Stack(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.well,
                        border: Border.all(color: scheme.hairline),
                      ),
                      child: ClipOval(
                        child:
                            photoUrl == null
                                ? Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: scheme.onSurfaceVariant,
                                )
                                : CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget:
                                      (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        size: 28,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                      ),
                    ),
                    if (isAuthed)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: scheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadii.full,
                              ),
                              border: Border.all(color: AppPalette.amber),
                            ),
                            child: Text(
                              'PRO',
                              style: theme.textTheme.eyebrow?.copyWith(
                                color: AppPalette.amber,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Fact strip ──────────────────────────────
          if (isAuthed) ...[
            const SizedBox(height: 22),
            Container(height: 1, color: scheme.hairline),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatItem(
                    context,
                    label: 'IMPORTS',
                    value:
                        subscription.unlimitedUsage || subscription.trialActive
                            ? '∞'
                            : '$importCredits',
                  ),
                  _buildStatDivider(context),
                  _buildStatItem(
                    context,
                    label: 'AI PLANS',
                    value:
                        subscription.unlimitedUsage || subscription.trialActive
                            ? '∞'
                            : '$aiCredits',
                  ),
                  _buildStatDivider(context),
                  _buildStatItem(
                    context,
                    label: 'TIER',
                    value:
                        isPremium
                            ? 'Pro'
                            : subscription.trialActive
                            ? 'Trial'
                            : 'Free',
                  ),
                ],
              ),
            ),
          ],

          // ── Actions ─────────────────────────────────
          if (isAuthed) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _ProfileActionChip(
                  icon: Icons.edit_rounded,
                  label: 'Edit name',
                  onTap: () => setState(() => _editingName = true),
                ),
                const SizedBox(width: 10),
                _ProfileActionChip(
                  icon: Icons.workspace_premium_rounded,
                  label: isPremium ? 'Manage plan' : 'Upgrade',
                  isPrimary: !isPremium,
                  onTap: () => Navigator.pushNamed(context, '/subscription'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Sign in'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.eyebrow?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.stamp),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Theme.of(context).colorScheme.hairline,
    );
  }

  Widget _buildNameEditCard(BuildContext context) {
    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display name'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editingName = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveName,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.link_rounded,
            label: 'Import',
            onTap: () => Navigator.pushNamed(context, '/importEvent'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_rounded,
            label: 'Create',
            onTap: () => Navigator.pushNamed(context, '/createEvent'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'AI plan',
            onTap: () => Navigator.pushNamed(context, '/planner'),
          ),
        ),
      ],
    );
  }

  /// Section headings are eyebrows here, not titles - Settings is a list of
  /// groups, and the groups shouldn't shout louder than the profile name.
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.eyebrow?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.well,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: scheme.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeSegment(
              icon: Icons.light_mode_rounded,
              label: 'Light',
              selected: !isDark,
              onTap: isDark ? themeProvider.toggleTheme : null,
            ),
          ),
          Expanded(
            child: _ThemeSegment(
              icon: Icons.dark_mode_rounded,
              label: 'Dark',
              selected: isDark,
              onTap: !isDark ? themeProvider.toggleTheme : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<_SettingsItem> items,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // A settings group is a boxed list: hairline frame, plain glyphs, rows
    // separated by inset rules. No tinted icon tiles - twelve of them turned
    // the screen into a colour swatch.
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.hairline),
      ),
      child: Column(
        children:
            items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? Radius.circular(AppRadii.lg) : Radius.zero,
                      bottom:
                          isLast ? Radius.circular(AppRadii.lg) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Icon(
                              item.icon,
                              color: scheme.onSurfaceVariant,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      item.subtitle!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          item.trailing ??
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 19,
                                color: scheme.onSurface.withValues(alpha: 0.3),
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 54, color: scheme.hairline),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService auth) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await auth.signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        },
        icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
        label: Text(
          'Sign out',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEMBERS',
            style: theme.textTheme.eyebrow?.copyWith(color: scheme.accent),
          ),
          const SizedBox(height: 10),
          Text('Sign in to unlock', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Save events, build collections and get AI recommendations.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Sign in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

class _ProfileActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ProfileActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? scheme.accent : null,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border:
              isPrimary
                  ? null
                  : Border.all(color: scheme.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isPrimary
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color:
                    isPrimary
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(height: 9),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of the light/dark control. Filled when selected; the unselected
/// half stays transparent so the pair reads as a single segmented switch.
class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? Colors.white : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? scheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
