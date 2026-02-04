import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/components/event_context_menu.dart';
import 'package:eventease/components/event_poster_card.dart';
import 'package:eventease/components/glass_surface.dart';
import 'package:eventease/components/floating_bottom_bar.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';
import 'package:table_calendar/table_calendar.dart';

/// Premium My Events screen with calendar integration.
///
/// Features:
/// - Clean tab-based navigation (Upcoming, Going, Past)
/// - Inline calendar with event indicators
/// - Category filter chips
/// - Event timeline view
/// - Quick actions (import, create, AI planner)
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  bool _hasLoaded = false;
  DateTime _selectedDay = DateTime.now();
  String _selectedCategory = 'All';
  _MyEventsTab _tab = _MyEventsTab.upcoming;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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
    _animController.dispose();
    super.dispose();
  }

  List<String> _availableCategories(List<Event> events) {
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

  IconData _categoryIcon(String c) {
    final v = c.toLowerCase();
    if (v.contains('music') || v.contains('concert'))
      return Icons.music_note_rounded;
    if (v.contains('night') || v.contains('party'))
      return Icons.nightlife_rounded;
    if (v.contains('art') || v.contains('gallery'))
      return Icons.palette_rounded;
    if (v.contains('tech') || v.contains('startup'))
      return Icons.computer_rounded;
    if (v.contains('sport') || v.contains('fitness'))
      return Icons.sports_basketball_rounded;
    if (v.contains('food') || v.contains('culinary'))
      return Icons.restaurant_rounded;
    if (v.contains('theater') || v.contains('comedy'))
      return Icons.theater_comedy_rounded;
    if (v.contains('family') || v.contains('kids'))
      return Icons.family_restroom_rounded;
    if (v == 'all') return Icons.grid_view_rounded;
    return Icons.local_activity_rounded;
  }

  Color _categoryColor(String c) {
    final v = c.toLowerCase();
    if (v.contains('music') || v.contains('concert'))
      return AppPalette.primaryBlue;
    if (v.contains('night') || v.contains('party')) return AppPalette.slate;
    if (v.contains('art') || v.contains('gallery')) return AppPalette.emerald;
    if (v.contains('tech') || v.contains('startup'))
      return AppPalette.accentBlue;
    if (v.contains('sport') || v.contains('fitness')) return AppPalette.amber;
    if (v.contains('food') || v.contains('culinary'))
      return AppPalette.warmGray;
    if (v == 'all') return AppPalette.accentBlue;
    return AppPalette.accentBlue;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Event> _filteredForUi(List<Event> events) {
    final now = DateTime.now();
    Iterable<Event> it = events;

    if (_selectedCategory != 'All') {
      it = it.where(
        (e) => e.categories.any((c) => c.trim() == _selectedCategory),
      );
    }

    switch (_tab) {
      case _MyEventsTab.upcoming:
        it = it.where((e) => e.startAt != null && e.startAt!.isAfter(now));
        break;
      case _MyEventsTab.going:
        final cut = now.add(const Duration(days: 30));
        it = it.where(
          (e) =>
              e.startAt != null &&
              e.startAt!.isAfter(now) &&
              e.startAt!.isBefore(cut),
        );
        break;
      case _MyEventsTab.past:
        it = it.where((e) => e.startAt != null && e.startAt!.isBefore(now));
        break;
    }

    // Day filter
    it = it.where(
      (e) =>
          e.startAt != null && _isSameDay(e.startAt!.toLocal(), _selectedDay),
    );

    final list = it.toList();
    list.sort((a, b) {
      final aa = a.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bb = b.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aa.compareTo(bb);
    });
    return list;
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Actions',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(Icons.more_horiz_rounded, size: 20),
            ),
            color:
                isDark
                    ? AppPalette.darkSurfaceElevated.withValues(alpha: 0.98)
                    : AppPalette.lightSurface.withValues(alpha: 0.98),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'import':
                  Navigator.pushNamed(context, '/importEvent');
                  break;
                case 'planner':
                  Navigator.pushNamed(context, '/planner');
                  break;
                case 'create':
                  Navigator.pushNamed(context, '/createEvent');
                  break;
                case 'refresh':
                  HapticFeedback.mediumImpact();
                  await context.read<EventProvider>().loadUserEvents(
                    forceRefresh: true,
                  );
                  if (!context.mounted) return;
                  SnackBarHelper.showSuccess(context, 'Events refreshed');
                  break;
                case 'collections':
                  Navigator.pushNamed(context, '/collections');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  _buildMenuItem('import', Icons.link_rounded, 'Import event'),
                  _buildMenuItem(
                    'planner',
                    Icons.auto_awesome_rounded,
                    'AI Planner',
                  ),
                  _buildMenuItem('create', Icons.add_rounded, 'Create event'),
                  _buildMenuItem('refresh', Icons.refresh_rounded, 'Refresh'),
                  _buildMenuItem(
                    'collections',
                    Icons.collections_bookmark_rounded,
                    'Collections',
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Consumer<EventProvider>(
                  builder: (context, events, _) {
                    if (events.isLoading && events.userEvents.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (events.error != null && events.userEvents.isEmpty) {
                      return Center(
                        child: Text(events.error!.userFriendlyMessage),
                      );
                    }

                    if (events.userEvents.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<EventProvider>().loadUserEvents(
                          forceRefresh: true,
                        );
                        if (!context.mounted) return;
                        SnackBarHelper.showSuccess(context, 'Events refreshed');
                      },
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: 140,
                        ),
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.responsive(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Calendar',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${events.userEvents.length} saved events',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tab switcher
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.responsive(context),
                            ),
                            child: _buildTabSwitcher(context),
                          ),
                          const SizedBox(height: 20),

                          // Category chips
                          _buildCategoryChips(context, events.userEvents),
                          const SizedBox(height: 20),

                          // Calendar
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.responsive(context),
                            ),
                            child: _buildCalendar(context, events.userEvents),
                          ),
                          const SizedBox(height: 24),

                          // Events for selected day
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.responsive(context),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Events',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.full,
                                    ),
                                  ),
                                  child: Text(
                                    _formatSelectedDate(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Event list
                          ..._buildEventList(context, events.userEvents),
                        ],
                      ),
                    );
                  },
                ),
              ), // FadeTransition
            ), // SafeArea
          ), // Positioned.fill
          const FloatingBottomBar(),
        ],
      ),
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

  Widget _buildTabSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      blurSigma: 16,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: const EdgeInsets.all(4),
      child: Row(
        children:
            _MyEventsTab.values.map((tab) {
              final isSelected = _tab == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = tab);
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            isSelected
                                ? (isDark ? AppPalette.darkBg : Colors.white)
                                : scheme.onSurface.withValues(alpha: 0.7),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, List<Event> events) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final categories = _availableCategories(events);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.responsive(context),
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          final color = _categoryColor(cat);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? color
                        : (isDark
                            ? AppPalette.darkSurfaceElevated
                            : AppPalette.lightSurfaceMuted),
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.transparent
                          : scheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(cat),
                    size: 16,
                    color:
                        isSelected
                            ? Colors.white
                            : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          isSelected
                              ? Colors.white
                              : scheme.onSurface.withValues(alpha: 0.8),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildCalendar(BuildContext context, List<Event> events) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: const EdgeInsets.only(bottom: 12),
      child: TableCalendar(
        focusedDay: _selectedDay,
        firstDay: DateTime(DateTime.now().year - 2, 1, 1),
        lastDay: DateTime(DateTime.now().year + 2, 12, 31),
        currentDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        startingDayOfWeek: StartingDayOfWeek.monday,

        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          setState(() => _selectedDay = selectedDay);
        },

        eventLoader: (day) {
          return events
              .where((e) => e.startAt != null && isSameDay(e.startAt!, day))
              .toList();
        },

        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: scheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.labelSmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: theme.textTheme.labelSmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),

        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          markerDecoration: BoxDecoration(
            color: isDark ? AppPalette.accentBlue : AppPalette.primaryBlue,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          defaultTextStyle: theme.textTheme.bodyMedium!,
          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  String _formatSelectedDate() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  List<Widget> _buildEventList(BuildContext context, List<Event> allEvents) {
    final filtered = _filteredForUi(allEvents);
    final theme = Theme.of(context);

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.responsive(context),
          ),
          child: GlassSurface(
            blurSigma: 18,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 40,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No events on this day',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try selecting another date or category.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered.map((e) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.responsive(context),
          right: AppSpacing.responsive(context),
          bottom: 12,
        ),
        child: EventPosterCard(
          event: e,
          compact: true,
          trailing: GlassSurface(
            blurSigma: 14,
            borderRadius: BorderRadius.circular(AppRadii.full),
            padding: EdgeInsets.zero,
            child: EventContextMenu(
              event: e,
              showAddToCollection: e.id.isNotEmpty,
              showDelete: e.id.isNotEmpty,
            ),
          ),
          onTap:
              () => Navigator.pushNamed(context, '/eventDetail', arguments: e),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.responsive(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Calendar',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save events you discover or create to see them here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Empty state card
          GradientGlassSurface(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            borderGradient: AppPalette.heroGradient,
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppPalette.accentBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 48,
                    color: AppPalette.accentBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No events yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import from social media, create manually, or discover events nearby.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        () => Navigator.pushNamed(context, '/importEvent'),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Import event'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(context, '/createEvent'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(context, '/discover'),
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Discover'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MyEventsTab {
  upcoming('Upcoming'),
  going('Going'),
  past('Past');

  const _MyEventsTab(this.label);
  final String label;
}
