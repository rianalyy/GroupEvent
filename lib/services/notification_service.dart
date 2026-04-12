import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Les notifications ne sont pas supportées sur Linux desktop
    if (Platform.isLinux || Platform.isWindows) {
      _initialized = true;
      return;
    }

    // Initialiser les fuseaux horaires
    tz_data.initializeTimeZones();
    // Détecter le fuseau horaire local à partir du décalage UTC
    _setLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Demander la permission sur Android 13+
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // Détecte la timezone locale depuis le décalage UTC de DateTime.now()
  static void _setLocalTimezone() {
    try {
      final offsetInHours = DateTime.now().timeZoneOffset.inHours;
      final offsetInMinutes = DateTime.now().timeZoneOffset.inMinutes;

      // Trouver une timezone qui correspond à l'offset
      final locations = tz.timeZoneDatabase.locations;
      tz.Location? bestMatch;

      for (final entry in locations.entries) {
        final loc = entry.value;
        final locOffset = loc.currentTimeZone.offset ~/ 1000 ~/ 60;
        if (locOffset == offsetInMinutes) {
          bestMatch = loc;
          // Préférer les grandes villes connues
          if (entry.key.contains('Indian/Antananarivo') ||
              entry.key.contains('Africa/Nairobi') ||
              entry.key.contains('Europe/Paris') ||
              entry.key.contains('America/New_York')) {
            break;
          }
        }
      }

      if (bestMatch != null) {
        tz.setLocalLocation(bestMatch);
      } else {
        // Fallback : créer un offset fixe
        tz.setLocalLocation(tz.UTC);
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  // Planifie une notification pour le jour J à 8h00 du matin
  static Future<void> scheduleEventReminder({
    required int eventId,
    required String eventTitle,
    required String eventLocation,
    required String eventDate,
  }) async {
    await init();
    if (Platform.isLinux || Platform.isWindows) return;

    final eventDay = _parseEventDate(eventDate);
    if (eventDay == null) return;

    final reminderTime = DateTime(
      eventDay.year,
      eventDay.month,
      eventDay.day,
      8, 0, 0,
    );

    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'groupevent_reminders',
      'Rappels GroupEvent',
      channelDescription: "Rappels pour le jour J de vos événements",
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF7C3AED),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        eventLocation.isNotEmpty
            ? 'Votre événement "$eventTitle" se déroule aujourd\'hui à $eventLocation. Bonne fête ! 🎉'
            : 'Votre événement "$eventTitle" se déroule aujourd\'hui. Bonne fête ! 🎉',
        htmlFormatBigText: false,
        contentTitle: '🎉 Jour J — $eventTitle',
        htmlFormatContentTitle: false,
        summaryText: "Rappel d'événement GroupEvent",
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: "C'est aujourd'hui !",
    );

    await _plugin.zonedSchedule(
      eventId.hashCode,
      '🎉 Jour J — $eventTitle',
      eventLocation.isNotEmpty
          ? 'Aujourd\'hui à $eventLocation !'
          : "Votre événement se déroule aujourd'hui !",
      tzTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$eventId',
    );
  }

  static Future<void> scheduleEarlyReminder({
    required int eventId,
    required String eventTitle,
    required String eventDate,
  }) async {
    await init();
    if (Platform.isLinux || Platform.isWindows) return;

    final eventDay = _parseEventDate(eventDate);
    if (eventDay == null) return;

    final reminderTime = eventDay.subtract(const Duration(hours: 24));
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'groupevent_early',
      'Rappels anticipés GroupEvent',
      channelDescription: "Rappels 24h avant vos événements",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF7C3AED),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      (eventId.hashCode + 10000),
      '⏰ Demain — $eventTitle',
      "Votre événement a lieu demain. Tout est prêt ?",
      tzTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$eventId',
    );
  }

  static Future<void> cancelEventReminder(int eventId) async {
    if (Platform.isLinux || Platform.isWindows) return;
    await _plugin.cancel(eventId.hashCode);
    await _plugin.cancel(eventId.hashCode + 10000);
  }

  static Future<void> cancelAll() async {
    if (Platform.isLinux || Platform.isWindows) return;
    await _plugin.cancelAll();
  }

  static DateTime? _parseEventDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    try {
      final cleaned = dateStr.replaceAll('·', '').replaceAll('  ', ' ').trim();
      return DateFormat('EEE d MMM yyyy HH:mm', 'fr_FR').parse(cleaned);
    } catch (_) {}

    try {
      final cleaned = dateStr.replaceAll('·', '').trim().split(' ').take(4).join(' ');
      return DateFormat('EEE d MMM yyyy', 'fr_FR').parse(cleaned);
    } catch (_) {}

    try { return DateTime.parse(dateStr); } catch (_) {}

    try { return DateFormat('d MMMM yyyy', 'fr_FR').parse(dateStr); } catch (_) {}

    try { return DateFormat('d MMM yyyy', 'fr_FR').parse(dateStr); } catch (_) {}

    return null;
  }

  static bool isToday(String dateStr) {
    final eventDay = _parseEventDate(dateStr);
    if (eventDay == null) return false;
    final now = DateTime.now();
    return eventDay.year == now.year &&
        eventDay.month == now.month &&
        eventDay.day == now.day;
  }

  static bool isFuture(String dateStr) {
    final eventDay = _parseEventDate(dateStr);
    if (eventDay == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return eventDay.isAfter(todayStart);
  }

  static int daysUntil(String dateStr) {
    final eventDay = _parseEventDate(dateStr);
    if (eventDay == null) return -999;
    final now = DateTime.now();
    final nowDate  = DateTime(now.year, now.month, now.day);
    final evtDate  = DateTime(eventDay.year, eventDay.month, eventDay.day);
    return evtDate.difference(nowDate).inDays;
  }
}
