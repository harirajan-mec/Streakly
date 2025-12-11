import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../services/hive_service.dart';
import '../models/habit.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const MethodChannel _platform = MethodChannel('streakly/permissions');

  static const String _channelId = 'streakly_daily_channel';
  static const String _channelName = 'Streakly Reminders';
  static const String _channelDescription = 'Daily habit reminders from Streakly';

  Future<void> initNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(initSettings);

      // Timezone setup using flutter_timezone
      try {
        tzdata.initializeTimeZones();
        String localTz = 'UTC';
        try {
          localTz = await FlutterTimezone.getLocalTimezone();
          debugPrint('📍 Device timezone: $localTz');
        } catch (e) {
          debugPrint('⚠️ Could not get device timezone, using UTC: $e');
        }

        try {
          tz.setLocalLocation(tz.getLocation(localTz));
          debugPrint('✅ Timezone set to $localTz');
        } catch (e) {
          // Fallback to UTC
          tz.setLocalLocation(tz.UTC);
          debugPrint('⚠️ Failed to set $localTz, using UTC: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Timezone initialization failed: $e');
      }

      // Create Android channel
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Call this from UI to let the user explicitly grant notification + exact alarm permissions.
  Future<void> requestPermissions() async {
    try {
      // iOS/visionOS prompt
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Android 13+ notification runtime prompt
        final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();

      // Android 12L+/14 "Alarms & reminders" exact alarm prompt
      if (Platform.isAndroid) {
        final canSchedule = await _canScheduleExactAlarms();
        if (!canSchedule) {
          debugPrint('⚠️ App cannot schedule exact alarms. Requesting user permission...');
          await _requestScheduleExactAlarm();
        } else {
          debugPrint('✅ Exact alarm permission already granted');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting notification permissions: $e');
    }
  }

  Future<bool> _canScheduleExactAlarms() async {
    try {
      final can = await _platform.invokeMethod<bool>('canScheduleExactAlarms');
      return can ?? false;
    } on PlatformException catch (e) {
      debugPrint('⚠️ PlatformException checking exact alarm capability: $e');
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking exact alarm capability: $e');
      return false;
    }
  }

  Future<void> _requestScheduleExactAlarm() async {
    try {
      await _platform.invokeMethod('requestScheduleExactAlarm');
    } on PlatformException catch (e) {
      debugPrint('⚠️ PlatformException requesting exact alarm permission: $e');
    } catch (e) {
      debugPrint('⚠️ Error requesting exact alarm permission: $e');
    }
  }

  int _normalizeId(int id) => id & 0x7fffffff;

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    try {
      await _plugin.show(id, title, body, _notificationDetails(), payload: payload);
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  Future<void> scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledDateTime,
    DateTimeComponents? matchComponents,
  }) async {
    try {
      var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

      if (Platform.isAndroid) {
        final canSchedule = await _canScheduleExactAlarms();
        if (!canSchedule) {
          debugPrint('⚠️ Exact alarm not granted; requesting then falling back to inexact for id=$id');
          await _requestScheduleExactAlarm();
          // Fall back so the reminder still fires even if the user declines exact alarms.
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        _notificationDetails(),
        payload: payload,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  Future<void> scheduleHabitReminder(int habitId, String title, String body, TimeOfDay time) async {
    try {
      final id = _normalizeId(habitId);
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDateTime: scheduled,
        matchComponents: DateTimeComponents.time,
      );

      debugPrint('🗓️ Scheduled reminder id=$id at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Failed to schedule reminder for habit $habitId: $e');
    }
  }

  Future<void> scheduleReminderForHabit(Habit habit) async {
    if (habit.reminderTime == null) return;
    final id = _normalizeId(habit.id.hashCode);
    final title = habit.name;
    final body = 'Time to complete your habit: ${habit.name}';
    await cancelReminder(id);
    await scheduleHabitReminder(id, title, body, habit.reminderTime!);
  }

  Future<void> cancelReminder(int habitId) async {
    try {
      final id = _normalizeId(habitId);
      await _plugin.cancel(id);
      debugPrint('🛑 Cancelled reminder id=$id');
    } catch (e) {
      debugPrint('❌ Failed to cancel reminder $habitId: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🧹 Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Schedule reminders for all saved habits that have reminderTime set.
  Future<void> scheduleAllSavedHabits() async {
    try {
      final habits = HiveService.instance.getHabits();
      for (final habit in habits) {
        if (habit.reminderTime != null) {
          await scheduleReminderForHabit(habit);
        }
      }
      debugPrint('✅ Scheduled reminders for saved habits');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule saved habit reminders: $e');
    }
  }

  /// Returns the list of pending scheduled notification requests from the plugin.
  /// Returns an empty list on error.
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch pending notifications: $e');
      return <PendingNotificationRequest>[];
    }
  }
}
