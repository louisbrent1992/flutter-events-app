import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/theme/theme.dart';
import '../models/event.dart';
import '../utils/snackbar_helper.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

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
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _title.text = e.title;
      _venue.text = e.venueName ?? '';
      _address.text = e.address ?? '';
      _description.text = e.description;
      _startAt = e.startAt;
    }
  }

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

    final isEditing = widget.eventToEdit != null;

    final event =
        isEditing
            ? widget.eventToEdit!.copyWith(
              title: title,
              description: _description.text.trim(),
              venueName: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
              address:
                  _address.text.trim().isEmpty ? null : _address.text.trim(),
              startAt: _startAt,
            )
            : Event(
              title: title,
              description: _description.text.trim(),
              venueName: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
              address:
                  _address.text.trim().isEmpty ? null : _address.text.trim(),
              startAt: _startAt,
              categories: const [],
              sourcePlatform: 'manual',
            );

    final provider = context.read<EventProvider>();
    final result =
        isEditing
            ? await provider.updateEvent(event, context)
            : await provider.createEvent(event, context);

    if (!mounted) return;
    if (result != null) {
      SnackBarHelper.showSuccess(
        context,
        isEditing ? 'Event updated' : 'Event created',
      );
      Navigator.pop(context, result);
    } else {
      SnackBarHelper.showError(
        context,
        provider.error?.userFriendlyMessage ??
            (isEditing ? 'Failed to update event' : 'Failed to create event'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: widget.eventToEdit != null ? 'Edit' : 'Create',
        fullTitle: widget.eventToEdit != null ? 'Edit Event' : 'Create Event',
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
              FilledButton(
                onPressed: _create,
                child: Text(
                  widget.eventToEdit != null ? 'Save changes' : 'Save event',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
