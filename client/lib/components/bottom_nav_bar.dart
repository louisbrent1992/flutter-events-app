import 'package:flutter/material.dart';
import '../components/app_tutorial.dart';

/// Bottom navigation bar for main app navigation
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavHome,
                title: 'Home',
                description: 'Return to the home screen',
                child: Icon(
                  currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavDiscover,
                title: 'Discover',
                description: 'Discover and explore events',
                child: Icon(
                  currentIndex == 1
                      ? Icons.explore_rounded
                      : Icons.explore_outlined,
                ),
              ),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavMyEvents,
                title: 'My Events',
                description: 'View your saved events',
                child: Icon(
                  currentIndex == 2
                      ? Icons.event_available_rounded
                      : Icons.event_available_outlined,
                ),
              ),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavGenerate,
                title: 'AI Planner',
                description: 'Generate event plans with AI',
                child: Icon(
                  currentIndex == 3
                      ? Icons.auto_awesome_rounded
                      : Icons.auto_awesome_outlined,
                ),
              ),
              label: 'Planner',
            ),
            BottomNavigationBarItem(
              icon: TutorialShowcase(
                showcaseKey: TutorialKeys.bottomNavSettings,
                title: 'Settings',
                description: 'App settings and preferences',
                child: Icon(
                  currentIndex == 4
                      ? Icons.settings_rounded
                      : Icons.settings_outlined,
                ),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
