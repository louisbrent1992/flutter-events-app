import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../components/custom_app_bar.dart';
import '../components/event_context_menu.dart';
import '../components/nav_drawer.dart';
import '../components/event_poster_card.dart';
import '../components/floating_bottom_bar.dart';
import '../components/pill_chip.dart';
import '../components/glass_surface.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

/// Revamped Calendar Screen with Smart Collections
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  bool _hasLoaded = false;
  late final ValueNotifier<DateTime> _focusedDay;
  late final ValueNotifier<DateTime> _selectedDay;
  String _selectedCategory = 'All';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Cache events map for the calendar
  Map<DateTime, List<Event>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = ValueNotifier(DateTime.now());
    _selectedDay = ValueNotifier(DateTime.now());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded && mounted) {
        _hasLoaded = true;
        final provider = context.read<EventProvider>();
        if (!provider.isLoading && provider.userEvents.isEmpty) {
          provider.loadUserEvents();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _selectedDay.dispose();
    _animController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _groupEvents(List<Event> events) {
    _eventsMap = {};
    for (final e in events) {
      if (e.startAt == null) continue;
      final date = DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
      if (_eventsMap[date] == null) _eventsMap[date] = [];
      _eventsMap[date]!.add(e);
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _eventsMap[date] ?? [];
  }

  List<Event> _getFilteredEventsForUi() {
    final dayEvents = _getEventsForDay(_selectedDay.value);
    if (_selectedCategory == 'All') return dayEvents;
    return dayEvents
        .where((e) => e.categories.any((c) => c.trim() == _selectedCategory))
        .toList();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- Smart Collection Getters ---

  List<Event> _getUpcomingEvents(List<Event> all) {
    final now = DateTime.now();
    return all
        .where((e) => e.startAt != null && e.startAt!.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt!.compareTo(b.startAt!));
  }

  List<Event> _getRecentlySaved(List<Event> all) {
    return all.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Event> _getPastEvents(List<Event> all) {
    final now = DateTime.now();
    return all
        .where((e) => e.startAt != null && e.startAt!.isBefore(now))
        .toList()
      ..sort((a, b) => b.startAt!.compareTo(a.startAt!));
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const NavDrawer(),
      appBar: CustomAppBar(
        title: '',
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        actions: [_buildMoreActionsMenu(context)],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer<EventProvider>(
              builder: (context, provider, _) {
                _groupEvents(provider.userEvents);
                final allEvents = provider.userEvents;

                if (provider.isLoading && allEvents.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            HapticFeedback.mediumImpact();
                            await provider.loadUserEvents(forceRefresh: true);
                            if (mounted) {
                              SnackBarHelper.showSuccess(context, 'Refreshed');
                            }
                          },
                          child: CustomScrollView(
                            slivers: [
                              // 1. Header
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.responsive(context),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'My Calendar',
                                        style: theme.textTheme.displaySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage your schedule',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),

                              // 2. Smart Collections (New Feature)
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 100,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.responsive(
                                        context,
                                      ),
                                    ),
                                    children: [
                                      _buildSmartCollectionCard(
                                        context,
                                        'Upcoming',
                                        Icons.calendar_today_rounded,
                                        _getUpcomingEvents(allEvents),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildSmartCollectionCard(
                                        context,
                                        'Recently Saved',
                                        Icons.bookmark_rounded,
                                        _getRecentlySaved(
                                          allEvents,
                                        ).take(10).toList(),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildSmartCollectionCard(
                                        context,
                                        'Past Events',
                                        Icons.history_rounded,
                                        _getPastEvents(allEvents),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildNavigationCard(
                                        context,
                                        'My Lists',
                                        Icons.folder_special_rounded,
                                        () => Navigator.pushNamed(
                                          context,
                                          '/collections',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 3. Calendar Wrapper
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.responsive(context),
                                    vertical: 24,
                                  ),
                                  child: _buildCalendarWidget(context, isDark),
                                ),
                              ),

                              // 4. Category Filter
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildCategorySelector(
                                    context,
                                    _getEventsForDay(_selectedDay.value),
                                  ),
                                ),
                              ),

                              // 5. Sticky Date Header & Event List
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  left: AppSpacing.responsive(context),
                                  right: AppSpacing.responsive(context),
                                  bottom: 140,
                                ),
                                sliver: SliverStickyHeader(
                                  header: _buildDayHeaderResults(context),
                                  sliver: _buildEventListSliver(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const FloatingBottomBar(),
        ],
      ),
    );
  }

  // --- Widgets ---

  /// A stat tile: the count is the loudest thing in the card, set as a
  /// numeral rather than hidden in a coloured pill. Label beneath as an
  /// eyebrow, the way a dashboard figure is captioned in print.
  Widget _buildSmartCollectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Event> events,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showEventsBottomSheet(context, title, events);
      },
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 17, color: scheme.onSurfaceVariant),
            const Spacer(),
            Text('${events.length}', style: theme.textTheme.stamp),
            const SizedBox(height: 3),
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.eyebrow?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: scheme.onSurfaceVariant),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showEventsBottomSheet(
    BuildContext context,
    String title,
    List<Event> events,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return GlassSurface(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.xl),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventPosterCard(
                            event: events[index],
                            compact: true,
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  '/eventDetail',
                                  arguments: events[index],
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoreActionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_rounded, size: 22),
      color:
          isDark
              ? AppPalette.darkSurfaceElevated.withValues(alpha: 0.98)
              : AppPalette.lightSurface.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'today':
            setState(() {
              _selectedDay.value = DateTime.now();
              _focusedDay.value = DateTime.now();
            });
            break;
          case 'import':
            Navigator.pushNamed(context, '/importEvent');
            break;
          case 'planner':
            Navigator.pushNamed(context, '/planner');
            break;
          case 'create':
            Navigator.pushNamed(context, '/createEvent');
            break;
          case 'collections':
            Navigator.pushNamed(context, '/collections');
            break;
        }
      },
      itemBuilder:
          (context) => [
            _buildMenuItem('today', Icons.today_rounded, 'Jump to Today'),
            const PopupMenuDivider(),
            _buildMenuItem('create', Icons.add_rounded, 'Create event'),
            _buildMenuItem('import', Icons.link_rounded, 'Import event'),
            _buildMenuItem('planner', Icons.auto_awesome_rounded, 'AI Planner'),
            _buildMenuItem(
              'collections',
              Icons.collections_bookmark_rounded,
              'Collections',
            ),
          ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.hairline),
      ),
      child: ValueListenableBuilder<DateTime>(
        valueListenable: _selectedDay,
        builder: (context, selected, _) {
          return TableCalendar<Event>(
            availableGestures: AvailableGestures.horizontalSwipe,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay.value,
            selectedDayPredicate: (day) => isSameDay(selected, day),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: scheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
              defaultTextStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 1.0),
              ),
              // Today is outlined; only the selected day is filled, so the
              // accent appears exactly once on the calendar.
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.accent, width: 1),
              ),
              todayTextStyle: TextStyle(
                color: scheme.accent,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: scheme.accent,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: BoxDecoration(
                color: scheme.accent,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay.value, selectedDay)) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDay.value = selectedDay;
                  _focusedDay.value = focusedDay;
                  _selectedCategory = 'All';
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay.value = focusedDay;
            },
            eventLoader: _getEventsForDay,
          );
        },
      ),
    );
  }

  Widget _buildDayHeaderResults(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateStr = DateFormat('EEEE, MMMM d').format(_selectedDay.value);
    final isToday = _isSameDay(_selectedDay.value, DateTime.now());

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.responsive(context),
        vertical: 8,
      ),
      // A dateline, the way a column is dated: eyebrow, then a rule.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateStr.toUpperCase(),
                style: theme.textTheme.eyebrow?.copyWith(
                  color: isToday ? scheme.accent : scheme.onSurfaceVariant,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text(
                  '· TODAY',
                  style: theme.textTheme.eyebrow?.copyWith(
                    color: scheme.accent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: scheme.hairline),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, List<Event> dayEvents) {
    if (dayEvents.isEmpty) return const SizedBox.shrink();

    final Set<String> categories = {'All'};
    for (var e in dayEvents) {
      for (var c in e.categories) {
        if (c.trim().isNotEmpty) categories.add(c.trim());
      }
    }

    if (categories.length <= 1 && categories.first == 'All') {
      return const SizedBox.shrink();
    }

    final list = categories.toList()..sort();
    if (list.contains('All')) {
      list.remove('All');
      list.insert(0, 'All');
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.responsive(context),
        ),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = list[index];
          final isSelected = _selectedCategory == cat;
          return _buildCategoryChip(context, cat, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    bool isSelected,
  ) {
    return PillChip(
      label: label,
      selected: isSelected,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = label);
      },
    );
  }

  Widget _buildEventListSliver(BuildContext context) {
    final filteredEvents = _getFilteredEventsForUi();

    filteredEvents.sort((a, b) {
      if (a.startAt == null) return 1;
      if (b.startAt == null) return -1;
      return a.startAt!.compareTo(b.startAt!);
    });

    if (filteredEvents.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = filteredEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEventTimelineItem(context, event),
        );
      }, childCount: filteredEvents.length),
    );
  }

  Widget _buildEventTimelineItem(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final timeStr =
        event.startAt != null
            ? DateFormat('h:mm a').format(event.startAt!)
            : 'All Day';

    final scheme = theme.colorScheme;

    // A running order: time in the left gutter against a vertical rule, the
    // event as a dense row. Reads down the page like a printed schedule.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, right: 10),
              child: Text(
                timeStr.toUpperCase(),
                textAlign: TextAlign.right,
                style: theme.textTheme.eyebrow?.copyWith(color: scheme.accent),
              ),
            ),
          ),
          Container(width: 1, color: scheme.hairline),
          const SizedBox(width: 12),
          Expanded(
            child: EventPosterCard(
              event: event,
              horizontal: true,
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    '/eventDetail',
                    arguments: event,
                  ),
              trailing: EventContextMenu(
                event: event,
                showAddToCollection: true,
                showDelete: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.hairline),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 30,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('Nothing on', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'You have no events scheduled for this day.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/createEvent'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add event'),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverStickyHeader extends StatelessWidget {
  final Widget header;
  final Widget sliver;

  const SliverStickyHeader({
    super.key,
    required this.header,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(header),
        ),
        sliver,
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
