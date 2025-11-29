import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = "daily_notification_channel";
  static const String _channelName = "Daily Notifications";
  static const String _channelDescription = "Daily Habit Reminders";

  // GENERATE A SAFE TIMEZONE FROM DEVICE OFFSET
  String _safeLocalTimezone() {
    final offset = DateTime.now().timeZoneOffset; // e.g. +5:30
    final hours = offset.inHours; // 5
    final minutes = offset.inMinutes.abs() % 60; // 30

    // Convert IST → Etc/GMT-5.5   (this is correct mapping)
    final sign = hours >= 0 ? '-' : '+';

    if (minutes == 0) {
      return "Etc/GMT$sign${hours.abs()}";
    } else {
      double decimal = hours.abs() + minutes / 60.0;
      return "Etc/GMT$sign$decimal";
    }
  }

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    final settings = const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);

    // Timezone fix
    tz.initializeTimeZones();
    String region = _safeLocalTimezone();
    tz.setLocalLocation(tz.getLocation(region));

    print("📍 Using SAFE timezone → $region");

    final channel = const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    final ios = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Android 13+ permissions are handled at app level in AndroidManifest.xml
    // No need to request programmatically
  }

  Future<void> cleanupOld() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleOneTimeNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime date,
  ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      date,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // DAILY notification
  Future<void> scheduleDailyNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
  ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> sendTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Clear old corrupted notifications
  Future<void> cleanupOldCorruptedNotifications() async {
    if (kDebugMode) print("🧹 Clearing old scheduled notifications...");
    await flutterLocalNotificationsPlugin.cancelAll();
    if (kDebugMode) print("✅ Cleanup done");
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
