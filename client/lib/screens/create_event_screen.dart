import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/theme/theme.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  DateTime? _startAt;

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _startAt ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      SnackBarHelper.showWarning(context, 'Please enter an event title.');
      return;
    }

    final event = Event(
      title: title,
      description: _description.text.trim(),
      venueName: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      startAt: _startAt,
      categories: const [],
      sourcePlatform: 'manual',
    );

    final created = await context.read<EventProvider>().createEvent(
      event,
      context,
    );
    if (!mounted) return;
    if (created != null) {
      SnackBarHelper.showSuccess(context, 'Event created');
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        context.read<EventProvider>().error?.userFriendlyMessage ??
            'Failed to create event',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Create',
        fullTitle: 'Create Event',
        // actions: [
        //   TextButton(
        //     onPressed: _create,
        //     child: const Text('Save'),
        //   ),
        // ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.responsive(context)),
          child: ListView(
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Concert, meetup, festival…',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _venue,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'Venue name (optional)',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Address (optional)',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                subtitle: Text(
                  _startAt == null ? 'Not set' : _startAt!.toLocal().toString(),
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: _pickStartDateTime,
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _description,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Dress code, lineup, what to bring…',
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _create, child: const Text('Save event')),
            ],
          ),
        ),
      ),
    );
  }
}
