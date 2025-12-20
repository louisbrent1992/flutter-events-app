import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// EventEase notification scheduling utilities.
///
/// This is intentionally **event-only** (reminders that deep-link into an event).
class NotificationScheduler {
  static FlutterLocalNotificationsPlugin? _plugin;

  static void init(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'eventease_general',
        'General',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Deterministic base ID from eventId so we can cancel/replace without storing state.
  static int _eventReminderBaseId(String eventId) {
    final h = eventId.hashCode & 0x3fffffff;
    return 900000 + (h % 90000);
  }

  static Future<void> cancelEventReminders(String eventId) async {
    final base = _eventReminderBaseId(eventId);
    for (var i = 0; i < 3; i++) {
      await _plugin?.cancel(base + i);
    }
  }

  /// Schedule a single reminder for an event.
  ///
  /// - **slot**: 0..2 (allows multiple presets per event: e.g. 1h before, 1d before).
  static Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required String body,
    required DateTime remindAt,
    int slot = 0,
  }) async {
    if (_plugin == null) return;
    if (slot < 0 || slot > 2) slot = 0;

    final when = tz.TZDateTime.from(remindAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (when.isBefore(now.add(const Duration(seconds: 5)))) {
      return; // don't schedule in the past (or basically-now)
    }

    final id = _eventReminderBaseId(eventId) + slot;
    await _plugin?.cancel(id);

    final payload = jsonEncode({
      'route': '/eventDetail',
      'args': {'eventId': eventId},
    });

    await _plugin?.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}


