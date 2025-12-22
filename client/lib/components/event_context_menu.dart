import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/event_provider.dart';
import '../services/collection_service.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

enum EventMenuAction {
  view,
  share,
  addToCollection,
  removeFromCollection,
  delete,
  saveToMyEvents,
}

class EventContextMenu extends StatelessWidget {
  const EventContextMenu({
    super.key,
    required this.event,
    this.showView = true,
    this.showShare = true,
    this.showAddToCollection = false,
    this.showRemoveFromCollection = false,
    this.showDelete = false,
    this.showSaveToMyEvents = false,
    this.onRemoveFromCollection,
    this.onSavedToMyEvents,
    this.onView,
  });

  final Event event;

  final bool showView;
  final bool showShare;
  final bool showAddToCollection;
  final bool showRemoveFromCollection;
  final bool showDelete;
  final bool showSaveToMyEvents;

  /// Optional override (e.g. collection detail screen).
  final Future<void> Function()? onRemoveFromCollection;

  /// Optional callback after saving.
  final void Function(Event created)? onSavedToMyEvents;

  final VoidCallback? onView;

  Color _menuBg(BuildContext context) {
    return Theme.of(context).colorScheme.surface.withValues(
      alpha: Theme.of(context).colorScheme.alphaVeryHigh,
    );
  }

  ShapeBorder _menuShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(
          alpha: Theme.of(context).colorScheme.overlayLight,
        ),
        width: 1,
      ),
    );
  }

  Future<void> _shareEvent(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin =
        renderBox != null
            ? renderBox.localToGlobal(Offset.zero) & renderBox.size
            : const Rect.fromLTWH(0, 0, 1, 1);

    final date =
        event.startAt != null
            ? 'Starts: ${event.startAt!.toLocal()}'.split('.').first
            : 'Starts: TBD';

    final location = [
      if ((event.venueName ?? '').trim().isNotEmpty) event.venueName!.trim(),
      if ((event.city ?? '').trim().isNotEmpty) event.city!.trim(),
      if ((event.region ?? '').trim().isNotEmpty) event.region!.trim(),
    ].join(' • ');

    final ticketLine =
        (event.ticketUrl ?? '').trim().isNotEmpty
            ? '\nTickets: ${event.ticketUrl}'
            : '';

    final shareText = [
      event.title,
      '',
      date,
      if (location.isNotEmpty) 'Where: $location',
      if (event.description.trim().isNotEmpty) '',
      if (event.description.trim().isNotEmpty) event.description.trim(),
      ticketLine.isEmpty ? '' : ticketLine.trim(),
      '',
      'Shared from EventEase',
    ].where((s) => s.trim().isNotEmpty).join('\n');

    await Share.share(shareText, sharePositionOrigin: origin);
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete event'),
            content: Text(
              'Are you sure you want to delete "${event.title}"? This can’t be undone.',
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

    if (confirm == true && context.mounted) {
      final ok = await context.read<EventProvider>().deleteEvent(
        event.id,
        context,
      );
      if (!context.mounted) return;
      if (ok) {
        SnackBarHelper.showSuccess(context, 'Deleted.');
      } else {
        SnackBarHelper.showError(context, 'Failed to delete.');
      }
    }
  }

  Future<void> _addToCollection(BuildContext context) async {
    final auth = context.read<AuthService>();
    if (auth.user == null) {
      SnackBarHelper.showInfo(context, 'Sign in to use collections.');
      Navigator.pushNamed(
        context,
        '/login',
        arguments: {'redirectRoute': '/collections'},
      );
      return;
    }

    final resp = await CollectionService.listCollections();
    if (!resp.success || resp.data == null) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          resp.message ?? 'Failed to load collections',
        );
      }
      return;
    }
    final collections = resp.data!;
    if (collections.isEmpty) {
      if (context.mounted) {
        SnackBarHelper.showInfo(
          context,
          'No collections yet. Create one first.',
        );
        Navigator.pushNamed(context, '/collections');
      }
      return;
    }

    if (!context.mounted) return;
    final selected = await showDialog<String?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add to collection'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (ctx, i) {
                  final c = collections[i];
                  return ListTile(
                    leading: const Icon(Icons.collections_bookmark_rounded),
                    title: Text(c.name),
                    subtitle: Text('${c.itemCount} events'),
                    onTap: () => Navigator.pop(ctx, c.id),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );

    if (selected == null || !context.mounted) return;
    final addResp = await CollectionService.addEventToCollection(
      collectionId: selected,
      eventId: event.id,
    );
    if (!context.mounted) return;
    if (addResp.success) {
      SnackBarHelper.showSuccess(context, 'Added to collection.');
    } else {
      SnackBarHelper.showError(context, addResp.message ?? 'Failed to add.');
    }
  }

  Future<void> _removeFromCollection(BuildContext context) async {
    if (onRemoveFromCollection != null) {
      await onRemoveFromCollection!.call();
      return;
    }
    // Default: remove from currently active collection (if any).
    await context.read<CollectionProvider>().removeEventFromActiveCollection(
      event.id,
    );
  }

  Future<void> _saveToMyEvents(BuildContext context) async {
    final auth = context.read<AuthService>();
    if (auth.user == null) {
      SnackBarHelper.showInfo(context, 'Sign in to save events.');
      Navigator.pushNamed(
        context,
        '/login',
        arguments: {'redirectRoute': '/random'},
      );
      return;
    }

    final toSave = Event(
      title: event.title,
      description: event.description,
      startAt: event.startAt,
      endAt: event.endAt,
      venueName: event.venueName,
      address: event.address,
      city: event.city,
      region: event.region,
      country: event.country,
      latitude: event.latitude,
      longitude: event.longitude,
      ticketUrl: event.ticketUrl,
      ticketPrice: event.ticketPrice,
      imageUrl: event.imageUrl,
      sourceUrl: event.sourceUrl,
      sourcePlatform: event.sourcePlatform ?? 'discover',
      categories: event.categories,
    );

    final created = await context.read<EventProvider>().createEvent(
      toSave,
      context,
    );
    if (!context.mounted) return;
    if (created != null) {
      SnackBarHelper.showSuccess(context, 'Saved to My Events.');
      onSavedToMyEvents?.call(created);
    } else {
      SnackBarHelper.showError(context, 'Could not save event.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = AppSizing.responsiveIconSize(
      context,
      mobile: 22,
      tablet: 26,
      desktop: 28,
    );

    final items = <PopupMenuEntry<EventMenuAction>>[
      if (showView)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.view,
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('View'),
            ],
          ),
        ),
      if (showShare)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.share,
          child: Row(
            children: [
              Icon(
                Icons.share_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Share'),
            ],
          ),
        ),
      if (showSaveToMyEvents)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.saveToMyEvents,
          child: Row(
            children: [
              Icon(
                Icons.save_alt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Save to My Events'),
            ],
          ),
        ),
      if (showAddToCollection)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.addToCollection,
          child: Row(
            children: [
              Icon(
                Icons.collections_bookmark_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Add to collection'),
            ],
          ),
        ),
      if (showRemoveFromCollection)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.removeFromCollection,
          child: Row(
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Remove'),
            ],
          ),
        ),
      if (showDelete)
        PopupMenuItem<EventMenuAction>(
          value: EventMenuAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<EventMenuAction>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, size: iconSize),
      color: _menuBg(context),
      shape: _menuShape(context),
      onSelected: (action) async {
        switch (action) {
          case EventMenuAction.view:
            if (onView != null) {
              onView!.call();
            } else {
              Navigator.pushNamed(context, '/eventDetail', arguments: event);
            }
            break;
          case EventMenuAction.share:
            await _shareEvent(context);
            break;
          case EventMenuAction.addToCollection:
            await _addToCollection(context);
            break;
          case EventMenuAction.removeFromCollection:
            await _removeFromCollection(context);
            if (context.mounted) {
              SnackBarHelper.showInfo(context, 'Removed from collection.');
            }
            break;
          case EventMenuAction.delete:
            await _confirmAndDelete(context);
            break;
          case EventMenuAction.saveToMyEvents:
            await _saveToMyEvents(context);
            break;
        }
      },
      itemBuilder: (_) => items,
    );
  }
}
