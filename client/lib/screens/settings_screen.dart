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
          'Open Settings to manage notifications for EventEase.',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.showInfo(
        context,
        'Open Settings to manage notifications for EventEase.',
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
        'subject': subject ?? 'EventEase Support',
        'body': [
          'Hi EventEase team,',
          '',
          'What I need help with:',
          '',
          '---',
          'Diagnostics:',
          'Platform: $platform',
          'App: EventEase • v1.0.0',
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
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: true,
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
                  // Header
                  Text(
                    'Settings',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account and preferences',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Card
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

                      return _buildProfileCard(
                        context,
                        displayName: displayName,
                        email: email,
                        photoUrl: photoUrl,
                        isAuthed: isAuthed,
                        isPremium: subscription.isPremium,
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
                  const SizedBox(height: 20),

                  // Name editing sheet
                  if (isAuthed && _editingName) _buildNameEditCard(context),
                  if (isAuthed && _editingName) const SizedBox(height: 20),

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
                          iconColor: AppPalette.accentBlue,
                          title: 'Collections',
                          subtitle: 'Organize events into lists',
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/collections'),
                        ),
                        _SettingsItem(
                          icon: Icons.calendar_month_rounded,
                          iconColor: AppPalette.emerald,
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
                        iconColor: AppPalette.amber,
                        title: 'Event reminders',
                        subtitle: 'Get notified before events start',
                        trailing: Switch.adaptive(
                          value: allowReminders,
                          activeColor: scheme.primary,
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
                        iconColor: AppPalette.primaryBlue,
                        title: 'Product updates',
                        subtitle: 'Occasional news and features',
                        trailing: Switch.adaptive(
                          value: allowPromos,
                          activeColor: scheme.primary,
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
                        iconColor: scheme.outline,
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
                        iconColor: AppPalette.accentBlue,
                        title: 'Help center',
                        subtitle: 'FAQs and guides',
                        onTap: () => _contactSupport(context),
                      ),
                      _SettingsItem(
                        icon: Icons.bug_report_outlined,
                        iconColor: AppPalette.amber,
                        title: 'Report a bug',
                        subtitle: 'Help us improve',
                        onTap:
                            () =>
                                _contactSupport(context, subject: 'Bug Report'),
                      ),
                      _SettingsItem(
                        icon: Icons.star_outline_rounded,
                        iconColor: AppPalette.accentPurple,
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
                        iconColor: AppPalette.slate,
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
                      'EventEase • v1.0.0',
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

  Widget _buildProfileCard(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? photoUrl,
    required bool isAuthed,
    required bool isPremium,
    VoidCallback? onEditProfile,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GradientGlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.xxl),
      borderGradient: AppPalette.heroGradient,
      borderWidth: 2,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: onEditProfile,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            photoUrl == null ? AppPalette.accentGradient : null,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.primaryBlue.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            photoUrl == null
                                ? Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: Colors.white.withValues(alpha: 0.9),
                                )
                                : CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget:
                                      (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        size: 36,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                ),
                      ),
                    ),
                    if (isAuthed)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppPalette.darkBg : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: isDark ? AppPalette.darkBg : Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppPalette.amber,
                                  AppPalette.amber.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadii.full,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
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
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (isAuthed) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ProfileActionChip(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            onTap: () => setState(() => _editingName = true),
                          ),
                          const SizedBox(width: 10),
                          _ProfileActionChip(
                            icon: Icons.workspace_premium_rounded,
                            label: isPremium ? 'Manage' : 'Upgrade',
                            isPrimary: !isPremium,
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  '/subscription',
                                ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              () => Navigator.pushNamed(context, '/login'),
                          child: const Text('Sign in'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
            color: AppPalette.accentBlue,
            onTap: () => Navigator.pushNamed(context, '/importEvent'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_rounded,
            label: 'Create',
            color: AppPalette.emerald,
            onTap: () => Navigator.pushNamed(context, '/createEvent'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Plan',
            color: AppPalette.amber,
            onTap: () => Navigator.pushNamed(context, '/planner'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = themeProvider.isDarkMode;

    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isDark ? themeProvider.toggleTheme : null,
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !isDark ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow:
                      !isDark
                          ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.light_mode_rounded,
                      size: 20,
                      color:
                          !isDark
                              ? Colors.white
                              : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Light',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            !isDark
                                ? Colors.white
                                : scheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: !isDark ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: !isDark ? themeProvider.toggleTheme : null,
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow:
                      isDark
                          ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dark_mode_rounded,
                      size: 20,
                      color:
                          isDark
                              ? AppPalette.darkBg
                              : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dark',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            isDark
                                ? AppPalette.darkBg
                                : scheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: isDark ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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

    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: EdgeInsets.zero,
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
                      top: i == 0 ? Radius.circular(AppRadii.xl) : Radius.zero,
                      bottom:
                          isLast ? Radius.circular(AppRadii.xl) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                  Text(
                                    item.subtitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          item.trailing ??
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService auth) {
    final theme = Theme.of(context);

    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await auth.signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        },
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Sign out',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    final theme = Theme.of(context);

    return GradientGlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      borderGradient: AppPalette.heroGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.person_add_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to unlock all features',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save events, get AI recommendations, and more',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
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
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
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
          gradient: isPrimary ? AppPalette.accentGradient : null,
          color: isPrimary ? null : scheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.full),
          border:
              isPrimary
                  ? null
                  : Border.all(color: scheme.outline.withValues(alpha: 0.2)),
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
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassSurface(
        blurSigma: 16,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        padding: const EdgeInsets.symmetric(vertical: 20),
        enableGlow: true,
        glowColor: color,
        glowIntensity: 0.15,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
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
