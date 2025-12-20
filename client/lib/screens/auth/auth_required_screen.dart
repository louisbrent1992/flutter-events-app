import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AuthRequiredScreen extends StatelessWidget {
  final String? redirectRoute;
  final dynamic redirectArgs;
  final String? title;
  final String? message;

  const AuthRequiredScreen({
    super.key,
    this.redirectRoute,
    this.redirectArgs,
    this.title,
    this.message,
  });

  static AuthRequiredScreen fromArgs(dynamic args) {
    if (args is Map) {
      return AuthRequiredScreen(
        redirectRoute: args['redirectRoute'] as String?,
        redirectArgs: args['args'] ?? args['url'],
        title: args['title'] as String?,
        message: args['message'] as String?,
      );
    }
    return const AuthRequiredScreen();
  }

  String _defaultTitle(String? route) {
    switch (route) {
      case '/importEvent':
        return 'Sign in to import events';
      case '/planner':
        return 'Sign in to use AI Planner';
      case '/myEvents':
        return 'Sign in to save events';
      case '/createEvent':
        return 'Sign in to create events';
      case '/subscription':
        return 'Sign in to manage subscription';
      default:
        return 'Sign in required';
    }
  }

  String _defaultMessage(String? route) {
    switch (route) {
      case '/importEvent':
        return 'Importing events is linked to your account so we can sync them across devices.';
      case '/planner':
        return 'AI planning is tied to your account and credits/subscription.';
      case '/myEvents':
        return 'Saving events requires an account so your plans stay backed up.';
      default:
        return 'Create an account or sign in to continue.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedTitle = title ?? _defaultTitle(redirectRoute);
    final resolvedMessage = message ?? _defaultMessage(redirectRoute);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: colorScheme.overlayMedium,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: colorScheme.overlayHeavy,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resolvedTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resolvedMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/login',
                          arguments: {
                            'redirectRoute': redirectRoute,
                            'args': redirectArgs,
                            // Preserve legacy key for import deep links
                            'url': redirectArgs,
                          },
                        );
                      },
                      child: const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: {
                            'redirectRoute': redirectRoute,
                            'args': redirectArgs,
                          },
                        );
                      },
                      child: const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
