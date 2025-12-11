import 'package:flutter/services.dart';

class WidgetService {
  static const platform = MethodChannel('com.streakly.app/widget');

  /// Update the home widget with current streak data
  static Future<void> updateWidget({
    required int streakCount,
    required bool todayCompleted,
    required String habitName,
    required String nextReminder,
    int? habitColor,
    int? habitIcon,
    required List<Map<String, dynamic>> calendar,
    String? mode,
    String? habitId,
  }) async {
    try {
      final payload = {
        'streakCount': streakCount,
        'todayCompleted': todayCompleted,
        'habitName': habitName,
        'nextReminder': nextReminder,
        'habitColor': habitColor,
        'habitIcon': habitIcon,
        'calendar': calendar,
      };
      if (mode != null) payload['mode'] = mode;
      if (habitId != null) payload['habitId'] = habitId;

      await platform.invokeMethod('updateWidget', payload);
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Refresh the widget display
  static Future<void> refreshWidget() async {
    try {
      await platform.invokeMethod('refreshWidget');
    } catch (e) {
      print('Error refreshing widget: $e');
    }
  }

  /// Clear widget data
  static Future<void> clearWidgetData() async {
    try {
      await platform.invokeMethod('clearWidgetData');
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }

  /// Get current widget data
  static Future<Map<dynamic, dynamic>> getWidgetData() async {
    try {
      final result = await platform.invokeMethod('getWidgetData');
      return result as Map<dynamic, dynamic>;
    } catch (e) {
      print('Error getting widget data: $e');
      return {};
    }
  }
}
