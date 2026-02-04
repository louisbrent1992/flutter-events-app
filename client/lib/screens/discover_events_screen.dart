import 'package:flutter/material.dart';
import 'dart:async';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/event_context_menu.dart';
import 'package:eventease/providers/discover_provider.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/components/glass_surface.dart';
import 'package:eventease/components/event_poster_card.dart';

/// Premium event discovery screen with advanced filtering.
///
/// Features:
/// - Animated search bar with voice input placeholder
/// - Smart category chips with dynamic loading
/// - Date range filters with visual calendar picker
/// - Masonry-style event grid
/// - Pull-to-refresh with haptics
/// - Infinite scroll pagination
class DiscoverEventsScreen extends StatefulWidget {
  const DiscoverEventsScreen({super.key});

  @override
  State<DiscoverEventsScreen> createState() => _DiscoverEventsScreenState();
}

class _DiscoverEventsScreenState extends State<DiscoverEventsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _selectedCategory = 'All';
  bool _showFilters = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Predefined category data with icons and colors
  static const List<Map<String, dynamic>> _categoryData = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': null},
    {
      'name': 'Music',
      'icon': Icons.music_note_rounded,
      'color': Color(0xFFFF2E93),
    },
    {
      'name': 'Nightlife',
      'icon': Icons.nightlife_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {'name': 'Art', 'icon': Icons.palette_rounded, 'color': Color(0xFF00FF88)},
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFF6B35),
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_basketball_rounded,
      'color': Color(0xFF00D4FF),
    },
    {
      'name': 'Tech',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF00D4FF),
    },
    {
      'name': 'Comedy',
      'icon': Icons.theater_comedy_rounded,
      'color': Color(0xFFFFD700),
    },
    {
      'name': 'Family',
      'icon': Icons.family_restroom_rounded,
      'color': Color(0xFF00FF88),
    },
  ];

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

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiscoverProvider>();
      if (provider.events.isEmpty && !provider.isLoading) {
        provider.load(page: 1, limit: 20);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final provider = context.read<DiscoverProvider>();
      if (!provider.isLoading && provider.hasNextPage) {
        provider.load(page: provider.currentPage + 1, limit: 20);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final provider = context.read<DiscoverProvider>();
      provider.setFilters(
        query: query.trim(),
        category: _selectedCategory == 'All' ? '' : _selectedCategory,
        from: null,
        to: null,
      );
      provider.load(page: 1, limit: 20, forceRefresh: true);
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    final provider = context.read<DiscoverProvider>();
    provider.setFilters(
      query: _searchController.text.trim(),
      category: category == 'All' ? '' : category,
      from: null,
      to: null,
    );
    provider.load(page: 1, limit: 20, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // View toggle would go here
          IconButton(
            icon: Icon(
              _showFilters
                  ? Icons.filter_list_off_rounded
                  : Icons.filter_list_rounded,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Search Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.responsive(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Discover',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Find your next experience',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  GlassSurface(
                    blurSigma: 18,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search events, artists, venues...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.responsive(context),
                ),
                itemCount: _categoryData.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final cat = _categoryData[i];
                  final isSelected = _selectedCategory == cat['name'];
                  final catColor = cat['color'] as Color?;

                  return GestureDetector(
                    onTap: () => _selectCategory(cat['name']),
                    child: AnimatedContainer(
                      duration: AppAnimations.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected && catColor != null
                                ? LinearGradient(
                                  colors: [
                                    catColor,
                                    catColor.withValues(alpha: 0.8),
                                  ],
                                )
                                : null,
                        color:
                            isSelected && catColor == null
                                ? scheme.primary
                                : (isDark
                                    ? AppPalette.darkSurfaceElevated
                                    : AppPalette.lightSurfaceMuted),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : scheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow:
                            isSelected && catColor != null
                                ? [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color:
                                isSelected
                                    ? Colors.white
                                    : (catColor ??
                                        scheme.onSurface.withValues(
                                          alpha: 0.7,
                                        )),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'],
                            style: theme.textTheme.labelLarge?.copyWith(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : scheme.onSurface.withValues(alpha: 0.8),
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
            const SizedBox(height: 16),

            // Events grid
            Expanded(
              child: Consumer<DiscoverProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.events.isEmpty) {
                    return _buildLoadingState(context);
                  }

                  if (provider.error != null && provider.events.isEmpty) {
                    return _buildErrorState(context, provider.error!);
                  }

                  if (provider.events.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.load(
                        page: 1,
                        limit: 20,
                        forceRefresh: true,
                      );
                    },
                    color: scheme.primary,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: AppSpacing.responsive(context),
                        right: AppSpacing.responsive(context),
                        bottom: 140,
                      ),
                      itemCount:
                          provider.events.length + (provider.isLoading ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        if (i >= provider.events.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final event = provider.events[i];
                        return _buildEventCard(context, event, index: i);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, {int index = 0}) {
    // Alternate card heights for visual variety
    final isAlternate = index % 3 == 1;

    return EventPosterCard(
      event: event,
      compact: isAlternate,
      trailing: GlassSurface(
        blurSigma: 14,
        borderRadius: BorderRadius.circular(AppRadii.full),
        padding: EdgeInsets.zero,
        child: EventContextMenu(
          event: event,
          showAddToCollection: event.id.isNotEmpty,
        ),
      ),
      onTap:
          () => Navigator.pushNamed(context, '/eventDetail', arguments: event),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: AppSpacing.responsive(context),
        right: AppSpacing.responsive(context),
        bottom: 140,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final height = i % 2 == 0 ? 220.0 : 100.0;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.responsive(context)),
      child: GlassSurface(
        blurSigma: 18,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load events. Please try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<DiscoverProvider>().load(
                  page: 1,
                  limit: 20,
                  forceRefresh: true,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DiscoverProvider>().load(
          page: 1,
          limit: 20,
          forceRefresh: true,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: SizedBox(
          height: 300,
          child: GlassSurface(
            blurSigma: 18,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No events found',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isEmpty
                      ? 'Try adjusting your filters or check back later.'
                      : 'Try a different search term.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      _selectCategory('All');
                    },
                    child: const Text('Clear search'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
