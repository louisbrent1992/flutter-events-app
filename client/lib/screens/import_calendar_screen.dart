import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/custom_app_bar.dart';
import '../components/glass_surface.dart';
import '../providers/event_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/calendar_import_service.dart';
import '../services/credits_service.dart';
import '../theme/theme.dart';
import '../utils/snackbar_helper.dart';
import '../utils/loading_dialog_helper.dart';

/// Screen for importing events from device calendars.
///
/// Features:
/// - Display available calendars (iOS Calendar, Google Calendar, etc.)
/// - Date range picker for selecting import period
/// - Event preview and selection before import
/// - Batch import support
class ImportCalendarScreen extends StatefulWidget {
  const ImportCalendarScreen({super.key});

  @override
  State<ImportCalendarScreen> createState() => _ImportCalendarScreenState();
}

class _ImportCalendarScreenState extends State<ImportCalendarScreen>
    with SingleTickerProviderStateMixin {
  List<Calendar> _calendars = [];
  Map<String, bool> _selectedCalendars = {};
  List<Event> _previewEvents = [];
  Set<String> _selectedEventIds = {};

  bool _isLoadingCalendars = true;
  bool _isLoadingEvents = false;
  bool _hasPermission = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Date range for importing events (default: next 3 months)
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadCalendars();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoadingCalendars = true);

    final hasPermission =
        await CalendarImportService.requestCalendarPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoadingCalendars = false;
        });
      }
      return;
    }

    final calendars = await CalendarImportService.getDeviceCalendars();

    if (mounted) {
      setState(() {
        _hasPermission = true;
        _calendars = calendars;
        _selectedCalendars = {
          for (final cal in calendars)
            if (cal.id != null) cal.id!: false,
        };
        _isLoadingCalendars = false;
      });
    }
  }

  Future<void> _loadEventsFromSelectedCalendars() async {
    final selectedIds =
        _selectedCalendars.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    if (selectedIds.isEmpty) {
      SnackBarHelper.showWarning(
        context,
        'Please select at least one calendar',
      );
      return;
    }

    setState(() => _isLoadingEvents = true);

    try {
      List<Event> allEvents = [];

      for (final calendarId in selectedIds) {
        final events = await CalendarImportService.getCalendarEvents(
          calendarId: calendarId,
          startDate: _startDate,
          endDate: _endDate,
        );
        allEvents.addAll(events);
      }

      // Sort by start date
      allEvents.sort((a, b) {
        final aStart = a.start ?? DateTime.now();
        final bStart = b.start ?? DateTime.now();
        return aStart.compareTo(bStart);
      });

      if (mounted) {
        setState(() {
          _previewEvents = allEvents;
          // Select all by default
          _selectedEventIds =
              allEvents
                  .where((e) => e.eventId != null)
                  .map((e) => e.eventId!)
                  .toSet();
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
        SnackBarHelper.showError(context, 'Failed to load events: $e');
      }
    }
  }

  Future<void> _importSelectedEvents() async {
    if (_selectedEventIds.isEmpty) {
      SnackBarHelper.showWarning(
        context,
        'Please select at least one event to import',
      );
      return;
    }

    final selectedEvents =
        _previewEvents
            .where(
              (e) => e.eventId != null && _selectedEventIds.contains(e.eventId),
            )
            .toList();

    // Check credits
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    try {
      await subscriptionProvider.refreshData();
    } catch (_) {}

    final hasCredits = await subscriptionProvider.hasEnoughCredits(
      CreditType.eventImport,
    );

    if (!hasCredits && mounted) {
      _showInsufficientCreditsDialog();
      return;
    }

    if (!mounted) return;
    LoadingDialogHelper.show(
      context,
      message:
          'Importing ${selectedEvents.length} event${selectedEvents.length > 1 ? 's' : ''}',
    );

    final eventProvider = context.read<EventProvider>();
    int successCount = 0;
    int failCount = 0;

    for (final calEvent in selectedEvents) {
      if (!mounted) break;
      final appEvent = CalendarImportService.convertToAppEvent(calEvent);
      final created = await eventProvider.createEvent(
        appEvent.copyWith(id: '', userId: ''),
        context,
      );

      if (created != null) {
        successCount++;
        // Deduct credits (best-effort)
        try {
          await subscriptionProvider.useCredits(
            CreditType.eventImport,
            reason: 'Calendar import',
          );
        } catch (_) {}
      } else {
        failCount++;
      }
    }

    if (!mounted) return;
    LoadingDialogHelper.dismiss(context);

    if (successCount > 0) {
      SnackBarHelper.showSuccess(
        context,
        'Imported $successCount event${successCount > 1 ? 's' : ''}${failCount > 0 ? ' ($failCount failed)' : ''}',
      );
      Navigator.pop(context, true); // Return true to indicate successful import
    } else {
      SnackBarHelper.showError(context, 'Failed to import events');
    }
  }

  void _showInsufficientCreditsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insufficient Credits'),
            content: const Text(
              'You don\'t have enough credits to import events. Please purchase credits or subscribe to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/subscription');
                },
                child: const Text('Get Credits'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppPalette.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _previewEvents = [];
        _selectedEventIds = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: 'Import',
          fullTitle: 'Import from Calendar',
        ),
        body: SafeArea(
          bottom: false,
          child:
              _isLoadingCalendars
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasPermission
                  ? _buildPermissionDeniedState(context)
                  : _buildMainContent(context, theme, scheme),
        ),
        bottomNavigationBar:
            _hasPermission && _previewEvents.isNotEmpty
                ? _buildImportButton(context, scheme)
                : null,
      ),
    );
  }

  Widget _buildPermissionDeniedState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: scheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Calendar Access Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please grant calendar access to import events from your device calendar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadCalendars,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.responsive(context)),
      children: [
        // Date Range Picker
        _buildSectionHeader(context, 'Date Range'),
        const SizedBox(height: 8),
        _buildDateRangePicker(context, theme, scheme),
        const SizedBox(height: 24),

        // Calendar Selection
        _buildSectionHeader(context, 'Select Calendars'),
        const SizedBox(height: 8),
        _buildCalendarList(context, theme, scheme),
        const SizedBox(height: 16),

        // Load Events Button
        if (_previewEvents.isEmpty)
          FilledButton.icon(
            onPressed:
                _isLoadingEvents ? null : _loadEventsFromSelectedCalendars,
            icon:
                _isLoadingEvents
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                    : const Icon(Icons.search_rounded),
            label: Text(_isLoadingEvents ? 'Loading...' : 'Find Events'),
          ),

        // Event Preview
        if (_previewEvents.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            'Found ${_previewEvents.length} Events',
            trailing: TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedEventIds.length == _previewEvents.length) {
                    _selectedEventIds.clear();
                  } else {
                    _selectedEventIds =
                        _previewEvents
                            .where((e) => e.eventId != null)
                            .map((e) => e.eventId!)
                            .toSet();
                  }
                });
              },
              child: Text(
                _selectedEventIds.length == _previewEvents.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildEventPreviewList(context, theme, scheme),
          const SizedBox(height: 100), // Space for bottom button
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDateRangePicker(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final dateFormat =
        '${_startDate.month}/${_startDate.day}/${_startDate.year}';
    final endFormat = '${_endDate.month}/${_endDate.day}/${_endDate.year}';

    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: _pickDateRange,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dateFormat - $endFormat',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to change date range',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarList(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    if (_calendars.isEmpty) {
      return GlassSurface(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No calendars found on this device',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children:
            _calendars.map((calendar) {
              final calendarId = calendar.id;
              if (calendarId == null) return const SizedBox.shrink();

              final isSelected = _selectedCalendars[calendarId] ?? false;
              final calendarColor =
                  calendar.color != null
                      ? Color(calendar.color!)
                      : scheme.primary;

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedCalendars[calendarId] = value ?? false;
                    // Clear preview when calendar selection changes
                    _previewEvents = [];
                    _selectedEventIds = {};
                  });
                },
                title: Text(
                  calendar.name ?? 'Unknown Calendar',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle:
                    calendar.accountName != null
                        ? Text(
                          calendar.accountName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        )
                        : null,
                secondary: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: calendarColor,
                    shape: BoxShape.circle,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildEventPreviewList(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children:
            _previewEvents.map((event) {
              final eventId = event.eventId;
              if (eventId == null) return const SizedBox.shrink();

              final isSelected = _selectedEventIds.contains(eventId);
              final startTime = event.start;
              final timeStr =
                  startTime != null
                      ? '${startTime.month}/${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
                      : 'No date';

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedEventIds.add(eventId);
                    } else {
                      _selectedEventIds.remove(eventId);
                    }
                  });
                },
                title: Text(
                  event.title ?? 'Untitled Event',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.location != null && event.location!.isNotEmpty)
                      Text(
                        event.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                isThreeLine:
                    event.location != null && event.location!.isNotEmpty,
                controlAffinity: ListTileControlAffinity.trailing,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildImportButton(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.responsive(context)),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: _selectedEventIds.isEmpty ? null : _importSelectedEvents,
          icon: const Icon(Icons.download_rounded),
          label: Text(
            'Import ${_selectedEventIds.length} Event${_selectedEventIds.length != 1 ? 's' : ''}',
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
    );
  }
}
