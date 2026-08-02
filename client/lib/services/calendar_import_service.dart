import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/event.dart' as app_event;

/// Service for importing events from device calendars (iOS Calendar, Android Calendar).
/// Also supports Google Calendar for accounts already signed in via Google.
class CalendarImportService {
  static final DeviceCalendarPlugin _deviceCalendarPlugin =
      DeviceCalendarPlugin();

  /// Request calendar permission from the user.
  static Future<bool> requestCalendarPermission() async {
    // First check current status
    var status = await Permission.calendarFullAccess.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.calendarFullAccess.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Open app settings so user can manually enable
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check if calendar permission is granted.
  static Future<bool> hasCalendarPermission() async {
    final status = await Permission.calendarFullAccess.status;
    return status.isGranted;
  }

  /// Retrieve all calendars available on the device.
  /// Returns a list of calendars (iOS Calendar, Google Calendar, Exchange, etc.)
  static Future<List<Calendar>> getDeviceCalendars() async {
    final hasPermission = await requestCalendarPermission();
    if (!hasPermission) {
      debugPrint('CalendarImportService: Calendar permission denied');
      return [];
    }

    try {
      final result = await _deviceCalendarPlugin.retrieveCalendars();
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
      debugPrint(
        'CalendarImportService: Failed to retrieve calendars: ${result.errors}',
      );
      return [];
    } catch (e) {
      debugPrint('CalendarImportService: Error retrieving calendars: $e');
      return [];
    }
  }

  /// Retrieve events from a specific calendar within a date range.
  static Future<List<Event>> getCalendarEvents({
    required String calendarId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final hasPermission = await hasCalendarPermission();
    if (!hasPermission) {
      debugPrint('CalendarImportService: No calendar permission');
      return [];
    }

    try {
      final result = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
      debugPrint(
        'CalendarImportService: Failed to retrieve events: ${result.errors}',
      );
      return [];
    } catch (e) {
      debugPrint('CalendarImportService: Error retrieving events: $e');
      return [];
    }
  }

  /// Convert a device calendar Event to the app's Event model.
  static app_event.Event convertToAppEvent(Event calendarEvent) {
    return app_event.Event(
      id: '', // Will be assigned by server upon creation
      userId: '', // Will be assigned by server
      title: calendarEvent.title ?? 'Untitled Event',
      description: calendarEvent.description ?? '',
      startAt: calendarEvent.start,
      endAt: calendarEvent.end,
      venueName: calendarEvent.location,
      address: calendarEvent.location,
      sourcePlatform: 'calendar',
      categories: const ['Imported'],
      createdAt: DateTime.now(),
    );
  }

  /// Batch convert calendar events to app events.
  static List<app_event.Event> convertToAppEvents(List<Event> calendarEvents) {
    return calendarEvents.map(convertToAppEvent).toList();
  }

  /// Get events from all calendars within a date range.
  static Future<Map<Calendar, List<Event>>> getAllCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final calendars = await getDeviceCalendars();
    final Map<Calendar, List<Event>> result = {};

    for (final calendar in calendars) {
      if (calendar.id != null) {
        final events = await getCalendarEvents(
          calendarId: calendar.id!,
          startDate: startDate,
          endDate: endDate,
        );
        if (events.isNotEmpty) {
          result[calendar] = events;
        }
      }
    }

    return result;
  }
}
