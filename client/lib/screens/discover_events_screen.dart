import 'package:flutter/material.dart';
import 'dart:async';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/components/nav_drawer.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/event_context_menu.dart';
import 'package:eventease/components/pill_chip.dart';
import 'package:eventease/providers/discover_provider.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/components/event_poster_card.dart';
import 'package:eventease/components/floating_bottom_bar.dart';

/// Discover - the index.
///
/// A masthead, a recessed search well, a single row of outline filters, then
/// results. Three densities are available (poster list, two-up grid, compact
/// rows) because "browsing" and "looking for one thing" want different shapes.
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
  int _layoutMode = 0; // 0: poster list, 1: 2-up grid, 2: compact rows
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // The toggle button shows the NEXT mode's icon as a preview.
  static const List<Map<String, dynamic>> _layoutModes = [
    {'icon': Icons.view_agenda_rounded, 'label': 'List'},
    {'icon': Icons.grid_view_rounded, 'label': 'Grid'},
    {'icon': Icons.view_list_rounded, 'label': 'Compact'},
  ];

  // Category data matching SeatGeek API event types. Colours were removed
  // deliberately: one accent per screen, and the filter row is not it.
  static const List<Map<String, dynamic>> _categoryData = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {
      'name': 'Sports',
      'icon': Icons.sports_basketball_rounded,
      'keywords': [
        'nfl',
        'nba',
        'mlb',
        'nhl',
        'ncaa',
        'soccer',
        'mls',
        'sports',
        'racing',
        'boxing',
        'mma',
        'tennis',
        'golf',
      ],
    },
    {
      'name': 'Concerts',
      'icon': Icons.music_note_rounded,
      'keywords': [
        'concert',
        'music',
        'festival',
        'rock',
        'pop',
        'hip_hop',
        'country',
        'jazz',
        'classical',
      ],
    },
    {
      'name': 'Theater',
      'icon': Icons.theater_comedy_rounded,
      'keywords': ['theater', 'broadway', 'musical', 'opera', 'ballet', 'dance'],
    },
    {
      'name': 'Comedy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'keywords': ['comedy', 'stand_up', 'comedian'],
    },
    {
      'name': 'Family',
      'icon': Icons.family_restroom_rounded,
      'keywords': ['family', 'kids', 'circus', 'disney'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiscoverProvider>();

      // Sync local state if the provider already has filters (e.g. arriving
      // from a category tap on Home).
      if (provider.category.isNotEmpty) {
        final match = _categoryData.firstWhere((c) {
          final name = c['name'].toString().toLowerCase();
          final keywords = (c['keywords'] as List<String>?) ?? [];
          final target = provider.category.toLowerCase();
          return name == target || keywords.any((k) => target.contains(k));
        }, orElse: () => {'name': 'All'});
        setState(() {
          _selectedCategory = match['name'] as String? ?? 'All';
          _searchController.text = provider.query;
        });
      }

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
    final pad = AppSpacing.responsive(context);

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip:
                'Switch to '
                '${_layoutModes[(_layoutMode + 1) % _layoutModes.length]['label']}',
            icon: Icon(
              _layoutModes[(_layoutMode + 1) % _layoutModes.length]['icon']
                  as IconData,
              size: 21,
            ),
            onPressed:
                () => setState(() {
                  _layoutMode = (_layoutMode + 1) % _layoutModes.length;
                }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Discover', style: theme.textTheme.displaySmall),
                        const SizedBox(height: 4),
                        Text(
                          'Everything happening near you',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildSearchField(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Filter row - outline chips, one fills with the accent.
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: _categoryData.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categoryData[i];
                        final name = cat['name'] as String;
                        return PillChip(
                          label: name,
                          icon: cat['icon'] as IconData,
                          selected: _selectedCategory == name,
                          onTap: () => _selectCategory(name),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: Consumer<DiscoverProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading && provider.events.isEmpty) {
                          return _buildLoadingState(context);
                        }
                        if (provider.error != null && provider.events.isEmpty) {
                          return _buildErrorState(context);
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
                          color: scheme.accent,
                          backgroundColor: scheme.surface,
                          child: _buildEventsList(context, provider),
                        );
                      },
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

  /// A recessed search well. No border at rest, accent hairline on focus -
  /// the field announces itself only once it has focus.
  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              _onSearchChanged(v);
              setState(() {}); // reveal/hide the clear affordance
            },
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search events, artists, venues',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.full),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.full),
                borderSide: BorderSide(color: scheme.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.full),
                borderSide: BorderSide(color: scheme.accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Map is a peer of search, not a widget buried inside it.
        SizedBox(
          height: 50,
          width: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/map'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              side: BorderSide(color: scheme.hairline),
            ),
            child: const Icon(Icons.map_outlined, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(BuildContext context, DiscoverProvider provider) {
    final pad = AppSpacing.responsive(context);
    final bottomInset = EdgeInsets.only(left: pad, right: pad, bottom: 140);

    // 0: poster list
    if (_layoutMode == 0) {
      return ListView.separated(
        controller: _scrollController,
        padding: bottomInset,
        itemCount: provider.events.length + (provider.isLoading ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i >= provider.events.length) return _buildLoadingSpinner();
          return _buildEventCard(context, provider.events[i]);
        },
      );
    }

    // 1: two-up grid
    if (_layoutMode == 1) {
      return GridView.builder(
        controller: _scrollController,
        padding: bottomInset,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.74,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: provider.events.length + (provider.isLoading ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= provider.events.length) return _buildLoadingSpinner();
          final event = provider.events[i];
          return EventPosterCard(
            event: event,
            compact: true,
            onTap:
                () => Navigator.pushNamed(
                  context,
                  '/eventDetail',
                  arguments: event,
                ),
          );
        },
      );
    }

    // 2: compact rows
    return ListView.separated(
      controller: _scrollController,
      padding: bottomInset,
      itemCount: provider.events.length + (provider.isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= provider.events.length) return _buildLoadingSpinner();
        return _buildEventCard(context, provider.events[i], horizontal: true);
      },
    );
  }

  Widget _buildLoadingSpinner() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Event event, {
    bool horizontal = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return EventPosterCard(
      event: event,
      horizontal: horizontal,
      trailing: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: horizontal ? scheme.well : Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color:
                horizontal
                    ? scheme.hairline
                    : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: EventContextMenu(
          event: event,
          showAddToCollection: event.id.isNotEmpty,
        ),
      ),
      onTap:
          () => Navigator.pushNamed(context, '/eventDetail', arguments: event),
    );
  }

  /// Skeletons rather than spinners: the page keeps its shape while loading,
  /// so results don't cause a layout jump.
  Widget _buildLoadingState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = AppSpacing.responsive(context);

    return ListView.separated(
      padding: EdgeInsets.only(left: pad, right: pad, bottom: 140),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        return Container(
          height: 260,
          decoration: BoxDecoration(
            color: scheme.well,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: scheme.hairline),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return _MessagePanel(
      icon: Icons.wifi_off_rounded,
      title: 'Couldn\'t load events',
      body: 'Check your connection and try again.',
      action: FilledButton(
        onPressed: () {
          context.read<DiscoverProvider>().load(
            page: 1,
            limit: 20,
            forceRefresh: true,
          );
        },
        child: const Text('Try again'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasQuery = _searchController.text.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DiscoverProvider>().load(
          page: 1,
          limit: 20,
          forceRefresh: true,
        );
      },
      color: Theme.of(context).colorScheme.accent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _MessagePanel(
            icon: Icons.search_off_rounded,
            title: 'No events found',
            body:
                hasQuery
                    ? 'Nothing matches "${_searchController.text}".'
                    : 'Try a different filter, or check back later.',
            action:
                hasQuery
                    ? OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        _selectCategory('All');
                      },
                      child: const Text('Clear search'),
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}

/// The shared empty/error plate: hairline box, muted glyph, one action.
class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pad = AppSpacing.responsive(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 140),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
