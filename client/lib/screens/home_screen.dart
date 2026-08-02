import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/custom_app_bar.dart';
import '../components/event_poster_card.dart';
import '../components/nav_drawer.dart';
import '../components/section_header.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/discover_provider.dart';
import '../theme/theme.dart';
import '../components/floating_bottom_bar.dart';

/// Home - the editorial cover.
///
/// The screen opens on a single full-bleed photograph rather than a grid,
/// because one strong image sells an evening better than six thumbnails.
/// Underneath, an index rule of categories, a featured rail, and a dense
/// "coming up" list - masthead, cover, contents.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _activeCategory = 'All';

  void _go(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamed(context, route, arguments: args);
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discover = context.read<DiscoverProvider>();
      if (!discover.isHomeLoading && discover.homeEvents.isEmpty) {
        discover.loadHomeEvents();
      }
      if (!discover.isLoading && discover.events.isEmpty) {
        discover.load(page: 1, limit: 16);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const _categories = [
    'All',
    'Concerts',
    'Sports',
    'Theater',
    'Comedy',
    'Nightlife',
    'Family',
    'Tech',
  ];

  Future<void> _openCategory(String category) async {
    setState(() => _activeCategory = category);
    final provider = context.read<DiscoverProvider>();
    provider.setFilters(
      query: '',
      category: category == 'All' ? '' : category,
      from: null,
      to: null,
    );
    await provider.load(page: 1, limit: 20, forceRefresh: true);
    if (!mounted) return;
    Navigator.pushNamed(context, '/discover');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAuthed = context.watch<AuthService>().user != null;
    final discover = context.watch<DiscoverProvider>();
    final pad = AppSpacing.responsive(context);

    final featured = discover.homeEvents;
    final hero = featured.isNotEmpty ? featured.first : null;
    final rail = featured.length > 1 ? featured.sublist(1).take(6).toList() : [];

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: CustomAppBar(
        title: 'SPARK',
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder:
              (context) => IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () => _go(context, '/discover'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<DiscoverProvider>().loadHomeEvents();
                },
                color: scheme.accent,
                backgroundColor: scheme.surface,
                child: CustomScrollView(
                  slivers: [
                    // ---- Cover -------------------------------------------
                    SliverToBoxAdapter(
                      child:
                          hero != null
                              ? EventHeroCard(
                                event: hero,
                                height: 400,
                                actionLabel: 'View event',
                                onTap:
                                    () => _go(
                                      context,
                                      '/eventDetail',
                                      args: hero,
                                    ),
                              )
                              : _heroSkeleton(context),
                    ),

                    // ---- Category index ----------------------------------
                    SliverToBoxAdapter(
                      child: _CategoryRule(
                        categories: _categories,
                        active: _activeCategory,
                        padding: pad,
                        onSelect: _openCategory,
                      ),
                    ),

                    // ---- Featured rail -----------------------------------
                    if (rail.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(pad, 26, pad, 0),
                          child: SectionHeader(
                            title: 'Featured',
                            trailing: SectionAction(
                              onTap: () => _go(context, '/discover'),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 250,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: pad),
                            itemCount: rail.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final e = rail[i] as Event;
                              return SizedBox(
                                width: 230,
                                child: EventPosterCard(
                                  event: e,
                                  compact: true,
                                  onTap:
                                      () =>
                                          _go(context, '/eventDetail', args: e),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // ---- Coming up ---------------------------------------
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, 32, pad, 0),
                        child: SectionHeader(
                          title: 'Coming up',
                          trailing: SectionAction(
                            onTap: () => _go(context, '/discover'),
                          ),
                        ),
                      ),
                    ),
                    if (discover.isLoading && discover.events.isEmpty)
                      SliverToBoxAdapter(child: _rowSkeleton(context, pad))
                    else if (discover.events.isEmpty)
                      SliverToBoxAdapter(child: _emptyState(context, pad))
                    else
                      SliverList.separated(
                        itemCount:
                            discover.events.length > 6
                                ? 6
                                : discover.events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = discover.events[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: pad),
                            child: EventPosterCard(
                              event: e,
                              horizontal: true,
                              onTap: () => _go(context, '/eventDetail', args: e),
                            ),
                          );
                        },
                      ),

                    // ---- Guest CTA ---------------------------------------
                    if (!isAuthed)
                      SliverToBoxAdapter(child: _guestCta(context, pad)),

                    const SliverToBoxAdapter(child: SizedBox(height: 130)),
                  ],
                ),
              ),
            ),
          ),
          const FloatingBottomBar(),
        ],
      ),
    );
  }

  Widget _heroSkeleton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 400,
      color: scheme.well,
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.accent),
      ),
    );
  }

  Widget _rowSkeleton(BuildContext context, double pad) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 98,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: scheme.well,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: scheme.hairline),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, double pad) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 30,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text('Nothing scheduled', style: theme.textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(
              'Check back soon for events near you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestCta(BuildContext context, double pad) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 32, pad, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEMBERS',
              style: theme.textTheme.eyebrow?.copyWith(color: scheme.accent),
            ),
            const SizedBox(height: 10),
            Text(
              'Events picked for you',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to save events, build collections and get '
              'recommendations based on what you actually go to.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
                const SizedBox(width: 10),
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
    );
  }
}

/// The category index: an underline tab row rather than a row of filled
/// pills, so the accent stays reserved for the primary action.
class _CategoryRule extends StatelessWidget {
  const _CategoryRule({
    required this.categories,
    required this.active,
    required this.onSelect,
    required this.padding,
  });

  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelect;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.hairline)),
      ),
      child: SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padding),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 22),
          itemBuilder: (context, i) {
            final c = categories[i];
            final isActive = c == active;
            return GestureDetector(
              onTap: () => onSelect(c),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    c,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color:
                          isActive ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: isActive ? 22 : 0,
                    color: scheme.accent,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
