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

  static Future<void> scheduleOneTimeNotification(
    int id,
    DateTime scheduledTime,
    String body,
  ) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print('📅 Scheduling one-time notification for: $tzTime');

    await _notificationsPlugin.zonedSchedule(
      id,
      '💊 Medication Reminder',
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meds_channel',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleDailyNotification(
    int id,
    TimeOfDay timeOfDay,
    String body,
  ) async {
    final tzTime = _nextInstanceOfTime(timeOfDay);

    final formattedTime = "${tzTime.hour.toString().padLeft(2, '0')}:${tzTime.minute.toString().padLeft(2, '0')}";
    print('📅 Scheduling daily notification for: $tzTime');

    await _notificationsPlugin.zonedSchedule(
      id,
      '💊 Medication Reminder',
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Used for testing notifications',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time, // ✅ Makes it repeat daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: formattedTime,
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

    // Ensure it's in the future
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print('❌ All notifications cancelled');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
  try {
    final list = await _notificationsPlugin.pendingNotificationRequests();
    return list ?? [];
  } catch (e, stack) {
    print('⚠️ Error fetching pending notifications: $e');
    print(stack);
    return [];
  }
}
}