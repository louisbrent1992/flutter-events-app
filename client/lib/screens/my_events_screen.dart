import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/theme/theme.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadUserEvents();
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
        title: Text(
          e.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDateTime(e.startAt)}${e.venueName != null && e.venueName!.isNotEmpty ? ' • ${e.venueName}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
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
        title: 'My Events',
        fullTitle: 'My Events',
        actions: [
          IconButton(
            tooltip: 'Import',
            icon: const Icon(Icons.link_rounded),
            onPressed: () => Navigator.pushNamed(context, '/importEvent'),
          ),
          IconButton(
            tooltip: 'Planner',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => Navigator.pushNamed(context, '/planner'),
          ),
          IconButton(
            tooltip: 'Create event',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.pushNamed(context, '/createEvent'),
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
                return Center(
                  child: Text(events.error!.userFriendlyMessage),
                );
              }

              if (events.userEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      const Text('No events yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/createEvent'),
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
                  itemBuilder: (context, idx) => _buildEventTile(events.userEvents[idx]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


