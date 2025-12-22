import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/bottom_nav_bar.dart';
import '../components/persistent_banner_layout.dart';
import 'home_screen.dart';
import 'my_events_screen.dart';
import 'ai_planner_screen.dart';
import 'settings_screen.dart';

/// Main screen with bottom navigation bar
/// This is the primary navigation hub for authenticated users
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 2; // Default to My Events
    // Create screens once in initState to prevent recreation
    _screens = [
      const PersistentBannerLayout(child: HomeScreen(redirectIfAuthed: false)),
      const PersistentBannerLayout(child: _DiscoverPlaceholderScreen()),
      const PersistentBannerLayout(child: MyEventsScreen()),
      const PersistentBannerLayout(child: AiPlannerScreen()),
      const PersistentBannerLayout(child: SettingsScreen()),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthed = context.watch<AuthService>().user != null;

    // If not authenticated, default to home (index 0)
    if (!isAuthed && _currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Protect routes that require authentication
          if (!isAuthed && (index == 1 || index == 2 || index == 3)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sign in to access this feature'),
                action: SnackBarAction(
                  label: 'Sign in',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/login',
                      arguments: {'redirectRoute': '/home'},
                    );
                  },
                ),
              ),
            );
            return;
          }
          _onTabTapped(index);
        },
      ),
    );
  }
}

/// Placeholder screen for discover functionality
class _DiscoverPlaceholderScreen extends StatelessWidget {
  const _DiscoverPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(child: Text('Discover screen coming soon')),
    );
  }
}
