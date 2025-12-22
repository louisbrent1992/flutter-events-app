import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

/// EventEase home: lightweight entrypoint.
/// - If guest: show a simple landing with auth + primary actions.
/// - If signed in: show quick actions (no auto-redirect; nav shell handles this).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuthed = context.watch<AuthService>().user != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.responsive(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'EventEase',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Import events from links or flyers, plan your night with AI, and keep everything in one place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              if (!isAuthed) ...[
                FilledButton(
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        '/login',
                        arguments: {'redirectRoute': '/myEvents'},
                      ),
                  child: const Text('Sign in'),
                ),
                SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        '/register',
                        arguments: {'redirectRoute': '/myEvents'},
                      ),
                  child: const Text('Create account'),
                ),
                SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        '/login',
                        arguments: {'redirectRoute': '/importEvent'},
                      ),
                  child: const Text('Import an event'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/random'),
                  child: const Text('Random event'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/importEvent'),
                  child: const Text('Import an event'),
                ),
                SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/planner'),
                  child: const Text('AI Planner'),
                ),
                SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/collections'),
                  child: const Text('Collections'),
                ),
                SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/random'),
                  child: const Text('Random event'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/myEvents'),
                  child: const Text('Go to My Events'),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
