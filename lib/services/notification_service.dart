import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 📌 Initialize notifications
  static Future<void> init() async {
    tz.initializeTimeZones(); // ✅ Required for timezone handling

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification Clicked: ${response.payload}");
      },
    );
  }

  // 📌 Check & Request Exact Alarm Permission (Android 12+)
  static Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      
      if (granted == false) {
        print("🔴 Exact alarms permission DENIED by the user.");
      } else {
        print("✅ Exact alarms permission GRANTED.");
      }
    }
  }

  // 📌 Schedule a daily notification
  static Future<void> scheduleDailyReminder(
      int id, String title, String body, int hour, int minute) async {
    await requestExactAlarmPermission(); // ✅ Ask for permission before scheduling

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_reminder',
          'Daily Challenge Reminder',
          channelDescription: 'Reminder for daily challenge completion.',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 📌 Cancel a notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // 📌 Helper to get the next scheduled time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  // 📌 Load Reminder State (Fix for challenge screen)
  static Future<bool> loadReminderState(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  // 📌 Save Reminder State (Fix for challenge screen)
  static Future<void> saveReminderState(String key, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, state);
  }
}
