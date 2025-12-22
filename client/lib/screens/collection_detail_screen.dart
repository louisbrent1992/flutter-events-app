import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../components/error_display.dart';
import '../components/event_context_menu.dart';
import '../models/event.dart';
import '../providers/collection_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().loadCollectionDetail(
        widget.collectionId,
      );
    });
  }

  Future<void> _confirmDeleteCollection() async {
    final provider = context.read<CollectionProvider>();
    final collection = provider.activeCollection;
    if (collection == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete collection?'),
            content: Text(
              'This will delete "${collection.name}" and its items list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (ok == true) {
      await provider.deleteCollection(collection.id);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Collection deleted.');
      Navigator.pop(context);
    }
  }

  Widget _eventTile(BuildContext context, Event e) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (e.startAt != null) '${e.startAt!.toLocal()}'.split('.').first,
            if ((e.venueName ?? '').isNotEmpty) e.venueName!,
            if ((e.city ?? '').isNotEmpty) e.city!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: EventContextMenu(
          event: e,
          showAddToCollection: false,
          showDelete: false,
          showSaveToMyEvents: false,
          showRemoveFromCollection: true,
        ),
        onTap: () => Navigator.pushNamed(context, '/eventDetail', arguments: e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Collection',
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
                case 'add':
                  Navigator.pushNamed(
                    context,
                    '/addEventsToCollection',
                    arguments: {'collectionId': widget.collectionId},
                  );
                  break;
                case 'delete':
                  await _confirmDeleteCollection();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(
                          Icons.playlist_add_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Add events'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete collection',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: Consumer<CollectionProvider>(
          builder: (context, provider, _) {
            final collection = provider.activeCollection;
            final events = provider.activeCollectionEvents;
            final error = provider.error;

            if (provider.isLoading && collection == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && collection == null) {
              return ErrorDisplay(
                message: error.userFriendlyMessage,
                onRetry:
                    () => provider.loadCollectionDetail(widget.collectionId),
              );
            }

            if (collection == null) {
              return const Center(child: Text('Collection not found.'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (collection.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(collection.description),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${events.length} events',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed:
                          () => provider.loadCollectionDetail(
                            widget.collectionId,
                          ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      events.isEmpty
                          ? Center(
                            child: Text(
                              'No events in this collection yet.\nTap "Add events" to get started.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 110),
                            itemCount: events.length,
                            itemBuilder:
                                (context, idx) =>
                                    _eventTile(context, events[idx]),
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
