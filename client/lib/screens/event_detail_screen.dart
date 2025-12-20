import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/services/notification_scheduler.dart';
import 'package:eventease/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  String _fmt(DateTime? dt) {
    if (dt == null) return 'TBD';
    return dt.toLocal().toString();
  }

  String _formatGCal(DateTime dt) {
    // Google Calendar expects UTC times like 20250101T130000Z
    final u = dt.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  Uri _googleCalendarUrl(Event e) {
    final start = e.startAt;
    final end = e.endAt ?? start?.add(const Duration(hours: 2));
    final dates =
        (start != null && end != null) ? '${_formatGCal(start)}/${_formatGCal(end)}' : null;

    final location = [
      if ((e.venueName ?? '').trim().isNotEmpty) e.venueName,
      if ((e.address ?? '').trim().isNotEmpty) e.address,
      if ((e.city ?? '').trim().isNotEmpty) e.city,
    ].whereType<String>().join(', ');

    return Uri.https('www.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': e.title,
      if (dates != null) 'dates': dates,
      if (location.trim().isNotEmpty) 'location': location,
      if (e.description.trim().isNotEmpty) 'details': e.description,
    });
  }

  Future<void> _addToCalendar(BuildContext context, Event e) async {
    if (e.startAt == null) {
      SnackBarHelper.showInfo(context, 'Add a date/time first.');
      return;
    }
    final uri = _googleCalendarUrl(e);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      SnackBarHelper.showError(context, 'Could not open calendar');
    }
  }

  Future<void> _openTicketLink(BuildContext context, Event e) async {
    final url = e.ticketUrl;
    if (url == null || url.trim().isEmpty) {
      SnackBarHelper.showInfo(context, 'No ticket link available.');
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      SnackBarHelper.showError(context, 'Invalid ticket URL');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      SnackBarHelper.showError(context, 'Could not open ticket link');
    }
  }

  Future<void> _scheduleReminder(BuildContext context, Event e) async {
    final start = e.startAt;
    if (start == null) {
      SnackBarHelper.showInfo(context, 'Add a date/time first.');
      return;
    }

    final choice = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remind me'),
          content: const Text('Choose when you want a reminder.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, -1),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('1 hour before'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('1 day before'),
            ),
          ],
        );
      },
    );
    if (choice == null || choice < 0) return;

    final remindAt =
        choice == 1 ? start.subtract(const Duration(days: 1)) : start.subtract(const Duration(hours: 1));

    await NotificationScheduler.scheduleEventReminder(
      eventId: e.id,
      title: 'Upcoming event',
      body: e.title,
      remindAt: remindAt,
      slot: choice,
    );

    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, 'Reminder scheduled');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Event',
        fullTitle: 'Event Details',
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete event?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              final success =
                  await context.read<EventProvider>().deleteEvent(event.id, context);
              if (!context.mounted) return;
              if (success) {
                SnackBarHelper.showSuccess(context, 'Event deleted');
                Navigator.pop(context);
              } else {
                SnackBarHelper.showError(context, 'Failed to delete event');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.responsive(context)),
          child: ListView(
            children: [
              Text(
                event.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '${_fmt(event.startAt)}${event.venueName != null ? ' • ${event.venueName}' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _addToCalendar(context, event),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Add to calendar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _scheduleReminder(context, event),
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('Remind me'),
                  ),
                  if ((event.ticketUrl ?? '').trim().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openTicketLink(context, event),
                      icon: const Icon(Icons.confirmation_number_rounded),
                      label: const Text('Tickets'),
                    ),
                ],
              ),
              if (event.address != null && event.address!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  event.address!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (event.description.isNotEmpty) ...[
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(event.description),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


