import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/snackbar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _editingName = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'Account'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Consumer<UserProfileProvider>(
                builder: (context, profile, _) {
                  final displayName =
                      (profile.profile['displayName'] as String?) ??
                      _user?.displayName ??
                      (isAuthed ? 'Event Organizer' : 'Guest');
                  final email =
                      (profile.profile['email'] as String?) ??
                      _user?.email ??
                      (isAuthed ? 'Signed in' : 'Browse mode');

                  if (!_editingName) {
                    _nameController.text = displayName;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!isAuthed)
                            FilledButton(
                              onPressed:
                                  () => Navigator.pushNamed(context, '/login'),
                              child: const Text('Sign in'),
                            )
                          else
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  await profile.uploadProfilePicture();
                                  if (!context.mounted) return;
                                  SnackBarHelper.showSuccess(
                                    context,
                                    'Profile photo updated.',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  SnackBarHelper.showError(
                                    context,
                                    e.toString(),
                                  );
                                }
                              },
                              child: const Text('Photo'),
                            ),
                        ],
                      ),
                      if (isAuthed) ...[
                        const SizedBox(height: 12),
                        if (_editingName) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () =>
                                          setState(() => _editingName = false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saveName,
                                  child: const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    () => setState(() => _editingName = true),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit name'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/subscription',
                                    ),
                                icon: const Icon(
                                  Icons.workspace_premium_rounded,
                                ),
                                label: Text(
                                  subscription.isPremium
                                      ? 'Premium'
                                      : 'Subscription',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isAuthed) ...[
            _sectionTitle(context, 'Organizer tools'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark_rounded),
                    title: const Text('Collections'),
                    subtitle: const Text('Group events into lists'),
                    onTap: () => Navigator.pushNamed(context, '/collections'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _sectionTitle(context, 'Appearance'),
          Card(
            child: SwitchListTile(
              title: const Text('Dark mode'),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Support'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded),
                  title: const Text('Privacy & data deletion'),
                  subtitle: const Text('How we handle your data'),
                  onTap: () {
                    // Server hosts the compliant data deletion page.
                    SnackBarHelper.showInfo(
                      context,
                      'Data deletion is available via the server’s data-deletion page.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isAuthed) ...[
            _sectionTitle(context, 'Sign out'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () async {
                  await auth.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text(
              'EventEase • v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: (isDark ? Colors.white : cs.onSurface).withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
