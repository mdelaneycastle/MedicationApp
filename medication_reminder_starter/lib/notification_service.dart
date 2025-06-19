import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 Notification tapped: ${response.payload}');
      },
    );

    // ✅ Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meds_channel',
      'Medication Reminders',
      description: 'Reminders to take your medication',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ✅ Set timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(timeZoneName);
    tz.setLocalLocation(location);
    print('🕒 Timezone set to: $timeZoneName');

    // ✅ Request permissions
    if (Platform.isAndroid) {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final notifStatus = await Permission.notification.status;

      print('⏰ Exact alarm permission: $alarmStatus');
      print('🔔 Notification permission: $notifStatus');

      if (alarmStatus.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      if (notifStatus.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  static Future<void> scheduleDailyNotification(
    int id,
    TimeOfDay timeOfDay,
    String body,
  ) async {
    final tzTime = _nextInstanceOfTime(timeOfDay);

    print('🧭 Current time: ${tz.TZDateTime.now(tz.local)}');
    print('📅 Scheduling notification for: $tzTime');

    await _notificationsPlugin.zonedSchedule(
      id,
      '💊 Medication Reminder',
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel', // TEMP: use test_channel for now
          'Test Notifications',
          channelDescription: 'Used for testing notifications',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.time, // COMMENTED FOR DEBUG
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // DEBUG: force schedule 1 minute in the future
    if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
      scheduled = now.add(const Duration(minutes: 1));
    }

    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print('❌ All notifications cancelled');
  }

  static Future<void> showTestNotification() async {
    print('🧪 Showing test notification');

    await _notificationsPlugin.show(
      999,
      '🧪 Test Notification',
      'This is a test notification.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Used for testing notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}