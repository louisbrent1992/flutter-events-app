import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/components/event_context_menu.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load events once when screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded && mounted) {
        _hasLoaded = true;
        final provider = context.read<EventProvider>();
        // Only load if not already loading and events haven't been loaded yet
        if (!provider.isLoading && provider.userEvents.isEmpty) {
          provider.loadUserEvents();
        }
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Date TBD';
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _buildEventTile(Event e) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_formatDateTime(e.startAt)}${e.venueName != null && e.venueName!.isNotEmpty ? ' • ${e.venueName}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EventContextMenu(
              event: e,
              showAddToCollection: e.id.isNotEmpty,
              showDelete: e.id.isNotEmpty,
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () {
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
        title: 'Events',
        fullTitle: 'My Events',
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
                  PopupMenuItem<String>(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Import'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'planner',
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Planner'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'create',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Create event'),
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
                    value: 'collections',
                    child: Row(
                      children: [
                        Icon(
                          Icons.collections_bookmark_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Collections'),
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
          child: Consumer<EventProvider>(
            builder: (context, events, _) {
              if (events.isLoading && events.userEvents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (events.error != null && events.userEvents.isEmpty) {
                return Center(child: Text(events.error!.userFriendlyMessage));
              }

              if (events.userEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 56,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      const Text('No events yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/createEvent'),
                        child: const Text('Create your first event'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<EventProvider>().loadUserEvents();
                  if (!context.mounted) return;
                  SnackBarHelper.showSuccess(context, 'Events refreshed');
                },
                child: ListView.builder(
                  itemCount: events.userEvents.length,
                  itemBuilder:
                      (context, idx) => _buildEventTile(events.userEvents[idx]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
