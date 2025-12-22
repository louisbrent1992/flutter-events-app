import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../components/custom_app_bar.dart';
import '../components/error_display.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/random_event_service.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';

class RandomEventScreen extends StatefulWidget {
  const RandomEventScreen({super.key});

  @override
  State<RandomEventScreen> createState() => _RandomEventScreenState();
}

class _RandomEventScreenState extends State<RandomEventScreen> {
  bool _loading = false;
  String? _error;
  Event? _event;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final resp = await RandomEventService.getRandomEvent();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (resp.success) {
        _event = resp.data;
      } else {
        _error = resp.userFriendlyMessage;
      }
    });
  }

  Future<void> _saveToMyEvents(Event e) async {
    final isAuthed = context.read<AuthService>().user != null;
    if (!isAuthed) {
      SnackBarHelper.showInfo(context, 'Sign in to save events.');
      Navigator.pushNamed(
        context,
        '/login',
        arguments: {'redirectRoute': '/random'},
      );
      return;
    }

    final toSave = Event(
      title: e.title,
      description: e.description,
      startAt: e.startAt,
      endAt: e.endAt,
      venueName: e.venueName,
      address: e.address,
      city: e.city,
      region: e.region,
      country: e.country,
      latitude: e.latitude,
      longitude: e.longitude,
      ticketUrl: e.ticketUrl,
      ticketPrice: e.ticketPrice,
      imageUrl: e.imageUrl,
      sourceUrl: e.sourceUrl,
      sourcePlatform: 'discover_random',
      categories: e.categories,
    );

    final saved = await context.read<EventProvider>().createEvent(
      toSave,
      context,
    );
    if (!mounted) return;
    if (saved != null) {
      SnackBarHelper.showSuccess(context, 'Saved to My Events.');
    } else {
      SnackBarHelper.showError(context, 'Could not save event.');
    }
  }

  Future<void> _shareEvent(Event e) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin =
        renderBox != null
            ? renderBox.localToGlobal(Offset.zero) & renderBox.size
            : const Rect.fromLTWH(0, 0, 1, 1);

    final date =
        e.startAt != null
            ? 'Starts: ${e.startAt!.toLocal()}'.split('.').first
            : 'Starts: TBD';
    final location = [
      if ((e.venueName ?? '').trim().isNotEmpty) e.venueName!.trim(),
      if ((e.city ?? '').trim().isNotEmpty) e.city!.trim(),
      if ((e.region ?? '').trim().isNotEmpty) e.region!.trim(),
    ].join(' • ');

    final ticketLine =
        (e.ticketUrl ?? '').trim().isNotEmpty
            ? '\nTickets: ${e.ticketUrl}'
            : '';

    final shareText = [
      e.title,
      '',
      date,
      if (location.isNotEmpty) 'Where: $location',
      if (e.description.trim().isNotEmpty) '',
      if (e.description.trim().isNotEmpty) e.description.trim(),
      ticketLine.isEmpty ? '' : ticketLine.trim(),
      '',
      'Shared from EventEase',
    ].where((s) => s.trim().isNotEmpty).join('\n');

    await Share.share(shareText, sharePositionOrigin: origin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Random',
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
                case 'surprise':
                  await _load();
                  break;
                case 'view':
                  if (_event == null) return;
                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/eventDetail',
                    arguments: _event!,
                  );
                  break;
                case 'save':
                  if (_event == null) return;
                  await _saveToMyEvents(_event!);
                  break;
                case 'share':
                  if (_event == null) return;
                  await _shareEvent(_event!);
                  break;
              }
            },
            itemBuilder: (context) {
              final hasEvent = _event != null;
              return [
                PopupMenuItem<String>(
                  value: 'surprise',
                  enabled: !_loading,
                  child: Row(
                    children: [
                      Icon(
                        Icons.casino_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Surprise me'),
                    ],
                  ),
                ),
                if (hasEvent)
                  PopupMenuItem<String>(
                    value: 'view',
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
                if (hasEvent)
                  PopupMenuItem<String>(
                    value: 'save',
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
                if (hasEvent)
                  PopupMenuItem<String>(
                    value: 'share',
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
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child:
              _loading
                  ? const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : _error != null
                  ? SizedBox(
                    height: 280,
                    child: ErrorDisplay(message: _error!, onRetry: _load),
                  )
                  : _event == null
                  ? SizedBox(
                    height: 280,
                    child: Center(
                      child: Text(
                        'No discover events available yet.\nAdd some docs to Firestore collection "discoverEvents".',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                  : _RandomEventCard(
                    event: _event!,
                    onSave: () => _saveToMyEvents(_event!),
                    onOpen:
                        () => Navigator.pushNamed(
                          context,
                          '/eventDetail',
                          arguments: _event!,
                        ),
                  ),
        ),
      ),
    );
  }
}

class _RandomEventCard extends StatelessWidget {
  const _RandomEventCard({
    required this.event,
    required this.onSave,
    required this.onOpen,
  });

  final Event event;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              event.description.isEmpty
                  ? 'No description provided.'
                  : event.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            if (event.startAt != null)
              Text('Starts: ${event.startAt!.toLocal()}'.split('.').first),
            if ((event.venueName ?? '').isNotEmpty)
              Text('Venue: ${event.venueName}'),
            if ((event.city ?? '').isNotEmpty) Text('City: ${event.city}'),
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton(
                  onPressed: onSave,
                  child: const Text('Save to My Events'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onOpen,
                  child: const Text('View details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
