import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../components/error_display.dart';
import '../providers/collection_provider.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

class EventCollectionsScreen extends StatefulWidget {
  const EventCollectionsScreen({super.key});

  @override
  State<EventCollectionsScreen> createState() => _EventCollectionsScreenState();
}

class _EventCollectionsScreenState extends State<EventCollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().loadCollections();
    });
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final provider = context.read<CollectionProvider>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  SnackBarHelper.showInfo(context, 'Please enter a name.');
                  return;
                }
                final c = await provider.createCollection(
                  name: name,
                  description: descController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, c != null);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      SnackBarHelper.showSuccess(context, 'Collection created.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Collections',
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
                case 'new':
                  await _showCreateDialog();
                  break;
                case 'refresh':
                  await context.read<CollectionProvider>().loadCollections(
                    forceRefresh: true,
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'new',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('New collection'),
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
                ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: Consumer<CollectionProvider>(
          builder: (context, collections, _) {
            final error = collections.error;

            if (collections.isLoading && collections.collections.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && collections.collections.isEmpty) {
              return ErrorDisplay(
                message: error.userFriendlyMessage,
                onRetry: () => collections.loadCollections(forceRefresh: true),
              );
            }

            if (collections.collections.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No collections yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a collection to group your events.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create collection'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => collections.loadCollections(forceRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: collections.collections.length,
                itemBuilder: (context, idx) {
                  final c = collections.collections[idx];
                  return Card(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: Text(
                        c.description.isEmpty
                            ? '${c.itemCount} events'
                            : '${c.itemCount} events • ${c.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'More',
                        icon: Icon(
                          Icons.more_vert,
                          size: AppSizing.responsiveIconSize(
                            context,
                            mobile: 22,
                            tablet: 26,
                            desktop: 28,
                          ),
                        ),
                        color: Theme.of(context).colorScheme.surface.withValues(
                          alpha: Theme.of(context).colorScheme.alphaVeryHigh,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(
                              alpha: Theme.of(context).colorScheme.overlayLight,
                            ),
                            width: 1,
                          ),
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'open':
                              Navigator.pushNamed(
                                context,
                                '/collectionDetail',
                                arguments: {'collectionId': c.id},
                              );
                              break;
                            case 'delete':
                              final ok = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete collection?'),
                                      content: Text('Delete "${c.name}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (ok == true && context.mounted) {
                                await context
                                    .read<CollectionProvider>()
                                    .deleteCollection(c.id);
                                if (!context.mounted) return;
                                SnackBarHelper.showSuccess(
                                  context,
                                  'Collection deleted.',
                                );
                              }
                              break;
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem<String>(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Open'),
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
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/collectionDetail',
                          arguments: {'collectionId': c.id},
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
