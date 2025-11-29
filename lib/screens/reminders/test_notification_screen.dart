import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../services/notification_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final List<String> _logs = [];
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingNotifications();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  Future<void> _checkPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotificationRequests();
      setState(() {
        _pendingCount = pending.length;
      });
      _addLog('Found ${pending.length} pending notifications');
      
      for (var notification in pending) {
        _addLog('ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      _addLog('Error checking pending: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      _addLog('Requesting notification permissions...');
      await _notificationService.requestPermissions();
      
      _addLog('Sending test notification...');
      await _notificationService.sendTestNotification();
      _addLog('✅ Test notification sent successfully!');
    } catch (e) {
      _addLog('❌ Error sending test notification: $e');
    }
  }

  Future<void> _scheduleNotificationIn5Seconds() async {
    try {
      _addLog('Scheduling notification in 5 seconds...');
      
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(const Duration(seconds: 5));
      
      _addLog('Current time: ${now.toString().substring(11, 19)}');
      _addLog('Scheduled for: ${scheduledDate.toString().substring(11, 19)}');
      
      await _notificationService.scheduleOneTimeNotification(
        99999,
        'Test Scheduled Notification',
        'This notification was scheduled 5 seconds ago!',
        scheduledDate,
      );
      
      _addLog('✅ Notification scheduled for ${scheduledDate.toString().substring(11, 19)}');
      await _checkPendingNotifications();
    } catch (e) {
      _addLog('❌ Error scheduling notification: $e');
    }
  }

  Future<void> _scheduleDailyReminder() async {
    try {
      _addLog('Scheduling daily reminder for 9:00 AM...');
      
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9 AM
        0,
      );
      
      // If it's already past 9 AM, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notificationService.scheduleDailyNotification(
        12345,
        'Daily Habit Reminder',
        'Time to check your habits!',
        scheduledDate,
      );
      
      _addLog('✅ Daily reminder scheduled for ${scheduledDate.toString().substring(0, 16)}');
      await _checkPendingNotifications();
    } catch (e) {
      _addLog('❌ Error scheduling daily reminder: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      _addLog('Cancelling notification ID 99999...');
      await _notificationService.cancelNotification(99999);
      
      _addLog('Cancelling notification ID 12345...');
      await _notificationService.cancelNotification(12345);
      
      _addLog('✅ Notifications cancelled');
      await _checkPendingNotifications();
    } catch (e) {
      _addLog('❌ Error cancelling notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPendingNotifications,
            tooltip: 'Refresh pending count',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Notifications:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          '$_pendingCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _pendingCount > 0 ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the buttons below to test notification functionality',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.notification_important),
                  label: const Text('Send Instant Test Notification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _scheduleNotificationIn5Seconds,
                  icon: const Icon(Icons.timer),
                  label: const Text('Schedule in 5 Seconds'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _scheduleDailyReminder,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Schedule Daily 9:00 AM'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _cancelAllNotifications,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Test Notifications'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Logs Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _logs.isEmpty ? null : () {
                        final allLogs = _logs.join('\n');
                        Clipboard.setData(ClipboardData(text: allLogs));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All logs copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy All'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _logs.clear()),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No activity yet\nTap a button above to start testing',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('❌');
                      final isSuccess = log.contains('✅');
                      
                      return Card(
                        color: isError 
                            ? Colors.red.withOpacity(0.1)
                            : isSuccess
                                ? Colors.green.withOpacity(0.1)
                                : null,
                        child: InkWell(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: log));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Log copied to clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isError
                                          ? Colors.red
                                          : isSuccess
                                              ? Colors.green
                                              : Colors.white70,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
