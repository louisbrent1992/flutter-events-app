import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/custom_app_bar.dart';
import '../components/event_poster_card.dart';
import '../components/nav_drawer.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/discover_provider.dart';
import '../theme/theme.dart';
import '../components/glass_surface.dart';

/// Premium EventEase Home screen with immersive discovery experience.
///
/// Features:
/// - Hero search with animated gradient background
/// - "For You" AI-powered recommendations section
/// - Mood-based browsing chips (Chill, Hype, Social, etc.)
/// - Trending events carousel with parallax cards
/// - Quick category access with iconography
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  String _selectedMood = 'All';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Mood categories for browsing - Professional colors
  static const List<Map<String, dynamic>> _moods = [
    {'label': 'All', 'icon': Icons.apps_rounded, 'color': null},
    {
      'label': 'Featured',
      'icon': Icons.star_rounded,
      'color': Color(0xFF1E40AF), // Primary blue
    },
    {
      'label': 'Business',
      'icon': Icons.business_center_rounded,
      'color': Color(0xFF475569), // Slate
    },
    {
      'label': 'Networking',
      'icon': Icons.people_rounded,
      'color': Color(0xFF059669), // Emerald
    },
    {
      'label': 'Workshop',
      'icon': Icons.school_rounded,
      'color': Color(0xFF0284C7), // Sky
    },
    {
      'label': 'Conference',
      'icon': Icons.event_rounded,
      'color': Color(0xFFD97706), // Amber
    },
  ];

  void _go(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discover = context.read<DiscoverProvider>();
      if (!discover.isLoading && discover.events.isEmpty) {
        discover.load(page: 1, limit: 16);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<String> _categoryChips(List<Event> events) {
    final set = <String>{};
    for (final e in events) {
      for (final c in e.categories) {
        final cleaned = c.trim();
        if (cleaned.isNotEmpty) set.add(cleaned);
      }
    }
    final list = set.toList()..sort();
    return ['All', ...list.take(8)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAuthed = context.watch<AuthService>().user != null;
    final discover = context.watch<DiscoverProvider>();
    final categories = _categoryChips(discover.events);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const NavDrawer(),
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: false,

        leading: Builder(
          builder: (context) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            );
          },
        ),
        actions: [
          // Profile avatar
          GestureDetector(
            onTap: () => _go(context, '/settings'),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppPalette.accentGradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: AppSpacing.sm, bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section with Greeting
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.responsive(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  AppPalette.primaryBlue,
                                  AppPalette.accentBlue,
                                ],
                              ).createShader(bounds),
                          child: Text(
                            'Welcome to EventEase',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Premium Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.responsive(context),
                    ),
                    child: GestureDetector(
                      onTap: () => _go(context, '/discover'),
                      child: GlassSurface(
                        blurSigma: 20,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        enableGlow: true,
                        glowColor: scheme.primary,
                        glowIntensity: 0.15,
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search events, venues, artists...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood-Based Browsing
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.responsive(context),
                      bottom: 12,
                    ),
                    child: Text(
                      'What\'s your vibe?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.responsive(context),
                      ),
                      itemCount: _moods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final mood = _moods[i];
                        final isSelected = _selectedMood == mood['label'];
                        final moodColor = mood['color'] as Color?;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedMood = mood['label']);
                            // Navigate to discover with mood filter
                            if (mood['label'] != 'All') {
                              _go(context, '/discover');
                            }
                          },
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  isSelected && moodColor != null
                                      ? LinearGradient(
                                        colors: [
                                          moodColor,
                                          moodColor.withValues(alpha: 0.8),
                                        ],
                                      )
                                      : null,
                              color:
                                  isSelected && moodColor == null
                                      ? scheme.primary
                                      : (isDark
                                          ? AppPalette.darkSurfaceElevated
                                          : AppPalette.lightSurfaceMuted),
                              borderRadius: BorderRadius.circular(
                                AppRadii.full,
                              ),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.transparent
                                        : scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mood['icon'] as IconData,
                                  size: 18,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (moodColor ??
                                              scheme.onSurface.withValues(
                                                alpha: 0.7,
                                              )),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  mood['label'],
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : scheme.onSurface.withValues(
                                              alpha: 0.8,
                                            ),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Featured / Trending Section
                  _buildSectionHeader(
                    context,
                    title: 'Trending Now',
                    subtitle: 'Hot events this week',
                    onViewAll: () => _go(context, '/discover'),
                  ),
                  const SizedBox(height: 14),
                  if (discover.isLoading && discover.events.isEmpty)
                    _buildLoadingCards(context)
                  else if (discover.events.isEmpty)
                    _buildEmptyState(context)
                  else
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.responsive(context),
                        ),
                        itemCount: discover.events.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) {
                          final e = discover.events[i];
                          return _buildFeaturedCard(context, e, index: i);
                        },
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Quick Categories Grid
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.responsive(context),
                    ),
                    child: Text(
                      'Browse by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(context, categories),
                  const SizedBox(height: 32),

                  // Upcoming Events List
                  _buildSectionHeader(
                    context,
                    title: 'Coming Up',
                    subtitle: 'Happening soon near you',
                    onViewAll: () => _go(context, '/discover'),
                  ),
                  const SizedBox(height: 14),
                  if (discover.events.length > 6)
                    ...discover.events
                        .skip(6)
                        .take(4)
                        .map(
                          (e) => Padding(
                            padding: EdgeInsets.only(
                              left: AppSpacing.responsive(context),
                              right: AppSpacing.responsive(context),
                              bottom: 12,
                            ),
                            child: EventPosterCard(
                              event: e,
                              compact: true,
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/eventDetail',
                                    arguments: e,
                                  ),
                            ),
                          ),
                        ),

                  // Guest Sign-in CTA
                  if (!isAuthed) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.responsive(context),
                      ),
                      child: GradientGlassSurface(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        borderGradient: AppPalette.heroGradient,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppPalette.accentBlue.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppPalette.accentBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Get Personalized',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        'Sign in for AI-powered recommendations',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed:
                                        () => _go(
                                          context,
                                          '/login',
                                          args: {'redirectRoute': '/home'},
                                        ),
                                    child: const Text('Sign in'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => _go(
                                          context,
                                          '/register',
                                          args: {'redirectRoute': '/home'},
                                        ),
                                    child: const Text('Create account'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.responsive(context)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    Event event, {
    int index = 0,
  }) {
    final theme = Theme.of(context);
    final hasImage = (event.imageUrl ?? '').trim().isNotEmpty;

    // Professional accent colors for visual variety
    final accentColors = [
      AppPalette.primaryBlue,
      AppPalette.accentBlue,
      AppPalette.emerald,
      AppPalette.slate,
      AppPalette.amber,
    ];
    final accentColor = accentColors[index % accentColors.length];

    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(context, '/eventDetail', arguments: event),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: event.imageUrl!.trim(),
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.4),
                              accentColor.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                  errorWidget:
                      (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.4),
                              accentColor.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.5),
                        accentColor.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    if (event.categories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          event.categories.first,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Date badge
                    if (event.startAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _formatShortDate(event.startAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((event.venueName ?? '').trim().isNotEmpty ||
                        (event.city ?? '').trim().isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if ((event.venueName ?? '').trim().isNotEmpty)
                                  event.venueName!.trim(),
                                if ((event.city ?? '').trim().isNotEmpty)
                                  event.city!.trim(),
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildCategoryGrid(BuildContext context, List<String> categories) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Category icons mapping
    IconData getIcon(String cat) {
      final c = cat.toLowerCase();
      if (c.contains('music') || c.contains('concert'))
        return Icons.music_note_rounded;
      if (c.contains('night') || c.contains('party'))
        return Icons.nightlife_rounded;
      if (c.contains('art') || c.contains('gallery'))
        return Icons.palette_rounded;
      if (c.contains('tech') || c.contains('startup'))
        return Icons.computer_rounded;
      if (c.contains('sport') || c.contains('fitness'))
        return Icons.sports_basketball_rounded;
      if (c.contains('food') || c.contains('culinary'))
        return Icons.restaurant_rounded;
      if (c.contains('theater') || c.contains('comedy'))
        return Icons.theater_comedy_rounded;
      if (c.contains('family') || c.contains('kids'))
        return Icons.family_restroom_rounded;
      if (c == 'all') return Icons.grid_view_rounded;
      return Icons.local_activity_rounded;
    }

    final filteredCategories =
        categories.where((c) => c != 'All').take(6).toList();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.responsive(context),
        ),
        itemCount: filteredCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = filteredCategories[i];
          // Professional category colors
          final colors = [
            AppPalette.primaryBlue,
            AppPalette.accentBlue,
            AppPalette.emerald,
            AppPalette.slate,
            AppPalette.amber,
            AppPalette.warmGray,
          ];
          final color = colors[i % colors.length];

          return GestureDetector(
            onTap: () async {
              final provider = context.read<DiscoverProvider>();
              provider.setFilters(
                query: '',
                category: cat,
                from: null,
                to: null,
              );
              await provider.load(page: 1, limit: 20, forceRefresh: true);
              if (!mounted) return;
              Navigator.pushNamed(context, '/discover');
            },
            child: Container(
              width: 85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppPalette.darkSurfaceElevated
                        : AppPalette.lightSurfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(getIcon(cat), color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCards(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.responsive(context),
        ),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.responsive(context)),
      child: GlassSurface(
        blurSigma: 18,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for new events in your area.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
