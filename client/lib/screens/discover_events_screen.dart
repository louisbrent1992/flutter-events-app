import 'package:flutter/material.dart';
import 'dart:async';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/error_display.dart';
import 'package:eventease/components/cache_status_indicator.dart';
import 'package:eventease/components/event_context_menu.dart';
import 'package:eventease/providers/discover_provider.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/theme/theme.dart';

/// Discover (Events) — MVP inspired by Recipease's Discover.
class DiscoverEventsScreen extends StatefulWidget {
  const DiscoverEventsScreen({super.key});

  @override
  State<DiscoverEventsScreen> createState() => _DiscoverEventsScreenState();
}

class _DiscoverEventsScreenState extends State<DiscoverEventsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  static const int _itemsPerPage = 20;

  final List<String> _categories = const [
    'All',
    'Music',
    'Nightlife',
    'Art',
    'Tech',
    'Sports',
    'Food',
  ];
  String _selectedCategory = 'All';

  final List<String> _timeWindows = const [
    'Any time',
    'Today',
    'This week',
    'This month',
  ];
  String _selectedTimeWindow = 'Any time';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoverProvider>().load(page: 1, limit: _itemsPerPage);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _fromForWindow(String w) {
    final now = DateTime.now();
    switch (w) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This week':
        return now.subtract(const Duration(days: 7));
      case 'This month':
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
  }

  void _applyFilters({bool forceRefresh = false}) {
    final provider = context.read<DiscoverProvider>();

    provider.setFilters(
      query: _searchController.text.trim(),
      category: _selectedCategory,
      from: _fromForWindow(_selectedTimeWindow),
      to: null,
    );

    provider.load(page: 1, limit: _itemsPerPage, forceRefresh: forceRefresh);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  Widget _buildEventCard(BuildContext context, Event e) {
    final theme = Theme.of(context);
    final subtitle = [
      if (e.startAt != null) '${e.startAt!.toLocal()}'.split('.').first,
      if ((e.venueName ?? '').isNotEmpty) e.venueName!,
      if ((e.city ?? '').isNotEmpty) e.city!,
    ].join(' • ');

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle.isEmpty ? 'Tap to view details' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EventContextMenu(
              event: e,
              showSaveToMyEvents: true,
              showAddToCollection: false,
              showDelete: false,
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () {
          // Reuse the existing detail route.
          // For discover events, the event may not belong to the user yet; we still show details.
          Navigator.pushNamed(context, '/eventDetail', arguments: e);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Discover',
        fullTitle: 'Discover',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(
              Icons.more_vert,
              size: AppSizing.responsiveIconSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 30,
              ),
            ),
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: Theme.of(context).colorScheme.alphaVeryHigh,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(
                  alpha: Theme.of(context).colorScheme.overlayLight,
                ),
                width: 1,
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'random':
                  Navigator.pushNamed(context, '/random');
                  break;
                case 'refresh':
                  _applyFilters(forceRefresh: true);
                  break;
                case 'reset':
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All';
                    _selectedTimeWindow = 'Any time';
                  });
                  _applyFilters(forceRefresh: true);
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'random',
                    child: Row(
                      children: [
                        Icon(
                          Icons.casino_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Random'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Refresh'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Reset filters'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.responsive(context)),
          child: Consumer<DiscoverProvider>(
            builder: (context, discover, _) {
              final error = discover.error;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CacheStatusIndicator(
                    dataType: 'discover',
                    compact: true,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search events, venues, cities...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                  setState(() {});
                                },
                              ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('category_$_selectedCategory'),
                          initialValue: _selectedCategory,
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedCategory = v);
                            _applyFilters();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('when_$_selectedTimeWindow'),
                          initialValue: _selectedTimeWindow,
                          items:
                              _timeWindows
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text(w),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedTimeWindow = v);
                            _applyFilters();
                          },
                          decoration: const InputDecoration(labelText: 'When'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed:
                            discover.isLoading
                                ? null
                                : () => _applyFilters(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  if (discover.isLoading && discover.events.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null && discover.events.isEmpty)
                    Expanded(
                      child: ErrorDisplay(
                        message: error.userFriendlyMessage,
                        isNetworkError: error.userFriendlyMessage
                            .toLowerCase()
                            .contains('network'),
                        onRetry: () => _applyFilters(forceRefresh: true),
                      ),
                    )
                  else if (discover.events.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No events found.\nTry a different search or filters.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _applyFilters(forceRefresh: true);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            // Keep content above the floating nav bar
                            bottom: 120,
                          ),
                          itemCount: discover.events.length + 1,
                          itemBuilder: (context, idx) {
                            if (idx == discover.events.length) {
                              // Pagination controls
                              if (discover.totalPages <= 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(top: AppSpacing.md),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          discover.hasPrevPage
                                              ? () => context
                                                  .read<DiscoverProvider>()
                                                  .load(
                                                    page:
                                                        discover.currentPage -
                                                        1,
                                                    limit: _itemsPerPage,
                                                  )
                                              : null,
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      label: const Text('Prev'),
                                    ),
                                    Text(
                                      '${discover.currentPage} / ${discover.totalPages}',
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          discover.hasNextPage
                                              ? () => context
                                                  .read<DiscoverProvider>()
                                                  .load(
                                                    page:
                                                        discover.currentPage +
                                                        1,
                                                    limit: _itemsPerPage,
                                                  )
                                              : null,
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      label: const Text('Next'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return _buildEventCard(
                              context,
                              discover.events[idx],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
