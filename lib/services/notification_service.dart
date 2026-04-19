import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool get _skip => Platform.isLinux || Platform.isWindows;

  static Future<void> init() async {
    if (_initialized || _skip) { _initialized = true; return; }
    tz_data.initializeTimeZones();
    _setTimezone();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true),
    ));
    if (Platform.isAndroid) {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  static void _setTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset.inMinutes;
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        if (entry.value.currentTimeZone.offset ~/ 1000 ~/ 60 == offset) {
          tz.setLocalLocation(entry.value);
          return;
        }
      }
    } catch (_) { tz.setLocalLocation(tz.UTC); }
  }

  static Future<void> scheduleEventReminder({required int eventId, required String eventTitle, required String eventLocation, required String eventDate}) async {
    await init();
    if (_skip) return;
    final day = _parseDate(eventDate);
    if (day == null) return;
    final t = DateTime(day.year, day.month, day.day, 8);
    if (t.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(eventId.hashCode,
      '🎉 Jour J — $eventTitle',
      eventLocation.isNotEmpty ? 'Aujourd\'hui à $eventLocation !' : 'Votre événement se déroule aujourd\'hui !',
      tz.TZDateTime.from(t, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails('groupevent_reminders', 'Rappels GroupEvent',
            channelDescription: 'Rappels jour J', importance: Importance.high, priority: Priority.high,
            color: const Color(0xFF7C3AED)),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleEarlyReminder({required int eventId, required String eventTitle, required String eventDate}) async {
    await init();
    if (_skip) return;
    final day = _parseDate(eventDate);
    if (day == null) return;
    final t = day.subtract(const Duration(hours: 24));
    if (t.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(eventId.hashCode + 10000,
      '⏰ Demain — $eventTitle', 'Votre événement a lieu demain. Tout est prêt ?',
      tz.TZDateTime.from(t, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('groupevent_early', 'Rappels anticipés GroupEvent', channelDescription: 'Rappels 24h avant'),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelEventReminder(int eventId) async {
    if (_skip) return;
    await _plugin.cancel(eventId.hashCode);
    await _plugin.cancel(eventId.hashCode + 10000);
  }

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    for (final fmt in ['EEE d MMM yyyy HH:mm', 'EEE d MMM yyyy', 'd MMMM yyyy', 'd MMM yyyy']) {
      try { return DateFormat(fmt, 'fr_FR').parse(s.replaceAll('·', '').replaceAll('  ', ' ').trim()); } catch (_) {}
    }
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  static bool isToday(String date) {
    final d = _parseDate(date);
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static int daysUntil(String date) {
    final d = _parseDate(date);
    if (d == null) return -999;
    final n = DateTime.now();
    return DateTime(d.year, d.month, d.day).difference(DateTime(n.year, n.month, n.day)).inDays;
  }

  static bool isFuture(String date) => daysUntil(date) >= 0;
}
