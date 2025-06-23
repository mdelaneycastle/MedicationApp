import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medication_reminder/notification_service.dart';

class ReminderLoop {
  static const int intervalMinutes = 5;
  static const int maxReminders = 12; // 1 hour worth (12 × 5min)

  static Future<void> startLoopUntilImageSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubmitted = prefs.getBool('imageSubmitted') ?? false;

    if (isSubmitted) {
      print("✅ Image already submitted, skipping loop.");
      return;
    }

    final now = DateTime.now();
    for (int i = 0; i < maxReminders; i++) {
      final time = now.add(Duration(minutes: intervalMinutes * i));
      await NotificationService.scheduleOneTimeNotification(
        9000 + i, // IDs in a safe range
        time,
        "📸 Please submit your medication photo.",
      );
    }

    print("🔁 Scheduled $maxReminders repeat notifications.");
  }

  static Future<void> stopLoop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('imageSubmitted', true);

    // Cancel only loop notifications (9000–9012)
    for (int i = 0; i < maxReminders; i++) {
      await NotificationService._notificationsPlugin.cancel(9000 + i);
    }

    print("🛑 Notification loop stopped.");
  }

  static Future<void> resetLoopFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('imageSubmitted', false);
    print("🔁 Loop flag reset for next reminder.");
  }
}