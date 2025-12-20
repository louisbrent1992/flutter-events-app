import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

/// EventEase home: lightweight entrypoint.
/// - If signed in: send user straight to My Events.
/// - If guest: show a simple landing with auth + primary actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_redirected) return;
    final isAuthed = context.read<AuthService>().user != null;
    if (isAuthed) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/myEvents');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuthed = context.watch<AuthService>().user != null;

    if (isAuthed) {
      // While redirecting.
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}



