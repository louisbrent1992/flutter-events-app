import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../models/event.dart';
import '../providers/collection_provider.dart';
import '../providers/event_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

class AddEventsToCollectionScreen extends StatefulWidget {
  const AddEventsToCollectionScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<AddEventsToCollectionScreen> createState() =>
      _AddEventsToCollectionScreenState();
}

class _AddEventsToCollectionScreenState
    extends State<AddEventsToCollectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final collections = context.read<CollectionProvider>();
      await collections.loadCollectionDetail(widget.collectionId);

      if (!mounted) return;
      final events = context.read<EventProvider>();
      if (!events.isLoading && events.userEvents.isEmpty) {
        await events.loadUserEvents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Event> _filtered(List<Event> events) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return events;
    return events
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              (e.venueName ?? '').toLowerCase().contains(q) ||
              (e.city ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: 'Add events'),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: Consumer2<CollectionProvider, EventProvider>(
          builder: (context, collections, events, _) {
            final inCollection = <String>{
              for (final e in collections.activeCollectionEvents) e.id,
            };

            final list = _filtered(events.userEvents);

            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search your events...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      events.isLoading && events.userEvents.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : list.isEmpty
                          ? Center(
                            child: Text(
                              'No events found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 110),
                            itemCount: list.length,
                            itemBuilder: (context, idx) {
                              final e = list[idx];
                              final already = inCollection.contains(e.id);
                              return Card(
                                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: ListTile(
                                  title: Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    [
                                      if (e.startAt != null)
                                        '${e.startAt!.toLocal()}'
                                            .split('.')
                                            .first,
                                      if ((e.city ?? '').isNotEmpty) e.city!,
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      already
                                          ? FilledButton.tonal(
                                            onPressed: () async {
                                              await collections
                                                  .removeEventFromActiveCollection(
                                                    e.id,
                                                  );
                                              if (!context.mounted) return;
                                              SnackBarHelper.showInfo(
                                                context,
                                                'Removed from collection.',
                                              );
                                            },
                                            child: const Text('Remove'),
                                          )
                                          : FilledButton(
                                            onPressed: () async {
                                              await collections
                                                  .addEventToActiveCollection(
                                                    e.id,
                                                  );
                                              if (!context.mounted) return;
                                              SnackBarHelper.showSuccess(
                                                context,
                                                'Added to collection.',
                                              );
                                            },
                                            child: const Text('Add'),
                                          ),
                                ),
                              );
                            },
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
