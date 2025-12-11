import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

/// Initializes Hive and the NotificationService and schedules saved reminders.
Future<void> initializeNotificationService() async {
  try {
    // Ensure Hive boxes are opened before scheduling reminders
    await HiveService.instance.init();

    // Initialize notifications (creates channels, timezone, requests permissions)
    await NotificationService().initNotifications();

    // Prompt user at startup for notifications + exact alarms to avoid silent scheduling failures
    await NotificationService().requestPermissions();

    // Schedule reminders for all saved habits that have reminders configured
    await NotificationService().scheduleAllSavedHabits();

    // Debug: log pending scheduled notifications so we can verify scheduling persisted
    try {
      final pending = await NotificationService().getPendingNotificationRequests();
      debugPrint('🔔 Pending scheduled notifications after init: ${pending.length}');
    } catch (e) {
      debugPrint('⚠️ Failed to fetch pending scheduled notifications: $e');
    }
  } catch (e) {
    debugPrint('⚠️ initializeNotificationService failed: $e');
  }
}
