import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../widgets/congratulations_popup.dart';
import '../services/hive_service.dart';
// NotificationService and timezone usage removed
import '../services/admob_service.dart'; // Import AdmobService
import '../services/widget_service.dart';

class HabitProvider with ChangeNotifier {
  final List<Habit> _habits = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  final AdmobService _admobService; // Add AdmobService instance

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Habit> get activeHabits =>
      _habits.where((habit) => habit.isActive).toList();

  List<Habit> get temporaryHabits =>
      _habits.where((habit) => habit.isTemporary == true).toList();

  List<Habit> get permanentHabits =>
      _habits.where((habit) => habit.isTemporary != true).toList();

  List<Habit> getHabitsByTimeOfDay(HabitTimeOfDay timeOfDay) {
    return activeHabits.where((habit) => habit.timeOfDay == timeOfDay).toList();
  }

  int get totalStreaks {
    return activeHabits.fold(0, (sum, habit) => sum + habit.currentStreak);
  }

  int get completedTodayCount {
    return activeHabits.where((habit) => habit.isCompletedToday()).length;
  }

  double get todayProgress {
    if (activeHabits.isEmpty) return 0.0;
    return completedTodayCount / activeHabits.length;
  }

  HabitProvider(this._admobService) {
    // Update constructor
    loadHabits();
  }

  Future<void> loadHabits() async {
    if (_isLoading) return; // Prevent concurrent loads

    try {
      _isLoading = true;
      _errorMessage = null;

      final habits = HiveService.instance.getHabits();
      _habits.clear();
      _habits.addAll(habits);
      _isLoading = false;

      // Only notify if we have a widget tree
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load habits: $e';
      debugPrint('Error loading habits: $e');
      _isLoading = false;
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    }
  }

  Future<void> addHabit(Habit habit, {bool isPremium = false}) async {
    // Add isPremium parameter
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (isHabitNameTaken(habit.name, excludeId: habit.id)) {
        _errorMessage = 'Habit name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Adding habit: ${habit.name}');
      await HiveService.instance.addHabit(habit);
      _habits.add(habit);
      debugPrint('Habit added successfully: ${habit.id}');

      // Reminder scheduling removed. The `reminderTime` is stored on the habit
      // but OS-level notification scheduling is currently disabled.
      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad
      _requestReview();
    } catch (e) {
      _errorMessage = 'Failed to add habit: $e';
      debugPrint('Error adding habit: $e');
      _habits.add(habit);
    } finally {
      _isLoading = false;
      notifyListeners();

      // Update native home widget after adding habit
      try {
        if (_habits.isNotEmpty) {
          _updateNativeWidget(_habits.last);
        }
      } catch (e) {
        debugPrint('Widget update failed: $e');
      }
    }
  }

  void addTemporaryHabit(Habit habit) {
    debugPrint('Adding temporary habit: ${habit.name}');
    _habits.add(habit);
    notifyListeners();
    debugPrint('Temporary habit added successfully: ${habit.id}');
  }

  Future<void> updateHabit(String id, Habit updatedHabit) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (isHabitNameTaken(updatedHabit.name, excludeId: id)) {
        _errorMessage = 'Habit name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final index = _habits.indexWhere((habit) => habit.id == id);
      if (index != -1) {
        await HiveService.instance.updateHabit(updatedHabit);
        _habits[index] = updatedHabit;

        // Notification cancel/schedule removed for updated habit
      }
    } catch (e) {
      _errorMessage = 'Failed to update habit: $e';
      final index = _habits.indexWhere((habit) => habit.id == id);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
    } finally {
      _isLoading = false;
      notifyListeners();

      // Update native home widget with latest data (best-effort)
      try {
        final latest = getHabitById(id);
        if (latest != null) {
          _updateNativeWidget(latest);
        }
      } catch (e) {
        debugPrint('Widget update failed: $e');
      }
    }
  }

  void updateTemporaryHabit(String id, Habit updatedHabit) {
    debugPrint('Updating temporary habit: ${updatedHabit.name}');
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      notifyListeners();
      debugPrint('Temporary habit updated successfully: ${updatedHabit.id}');
    }
  }

  Future<void> deleteHabit(String id, {bool isPremium = false}) async {
    // Add isPremium parameter
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await HiveService.instance.deleteHabit(id);
      _habits.removeWhere((habit) => habit.id == id);

      // Notification cancel removed
      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad
    } catch (e) {
      _errorMessage = 'Failed to delete habit: $e';
      _habits.removeWhere((habit) => habit.id == id);
    } finally {
      _isLoading = false;
      notifyListeners();

      // Update native home widget after deleting habit
      try {
        if (_habits.isNotEmpty) {
          _updateNativeWidget(_habits.first);
        }
      } catch (e) {
        debugPrint('Widget update failed: $e');
      }
    }
  }

  Future<void> toggleHabitCompletion(String id,
      [BuildContext? context, bool isPremium = false]) async {
    // Add isPremium parameter
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      final currentCount = habit.getTodayCompletionCount();
      final newDailyCompletions = Map<String, int>.from(habit.dailyCompletions);
      final completedDates = List<DateTime>.from(habit.completedDates);

      final wasAllCompleted = _areAllHabitsCompleted();

      if (currentCount >= habit.remindersPerDay) {
        debugPrint(
            '⚠️  Habit "${habit.name}" is fully completed for today. Try again tomorrow!');
        _errorMessage =
            'Habit already completed for today. Come back tomorrow!';
        notifyListeners();
        return; // Exit without making changes
      }

      final newCount = currentCount + 1;
      newDailyCompletions[todayKey] = newCount;

      if (currentCount == 0) {
        completedDates.add(today);
      }

        debugPrint(
          '✅ Habit "${habit.name}" marked complete ($newCount/${habit.remindersPerDay})');

      try {
        await HiveService.instance.recordCompletion(id, today, count: newCount);
      } catch (e) {
        _errorMessage = 'Failed to record completion: $e';
      }

      _habits[index] = habit.copyWith(
        completedDates: completedDates,
        dailyCompletions: newDailyCompletions,
      );
      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad

      if (context != null && newCount >= habit.remindersPerDay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHabitCompletionPopup(context, habit);
        });
      }

      notifyListeners();

      // Update native home widget with latest data (best-effort)
      try {
        _updateNativeWidget(_habits[index]);
      } catch (e) {
        debugPrint('Widget update failed: $e');
      }
    }
  }

  bool _areAllHabitsCompleted() {
    final activeHabitsList = activeHabits;
    if (activeHabitsList.isEmpty) return false;

    return activeHabitsList.every((habit) => habit.isCompletedToday());
  }

  void _showHabitCompletionPopup(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => CongratulationsPopup(
        habitName: habit.name,
        customMessage: 'You completed it ${habit.remindersPerDay}x today! 🎉',
        habitIcon: habit.icon,
        habitColor: habit.color,
      ),
    );
  }

  void _showAllHabitsCompletedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CongratulationsPopup(
        habitName: 'All habits completed',
        customMessage: 'You completed all your habits for today! 🎉',
        habitIcon: Icons.workspace_premium,
        habitColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _requestReview() async {
    final prefs = await SharedPreferences.getInstance();
    int habitCreationCount = prefs.getInt('habit_creation_count') ?? 0;
    habitCreationCount++;
    await prefs.setInt('habit_creation_count', habitCreationCount);

    if (habitCreationCount == 2) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatNextReminder(Habit habit) {
    if (habit.reminderTime == null) return 'No reminders';
    final time = habit.reminderTime!;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _updateNativeWidget([Habit? changedHabit]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('widget_mode') ?? 'all'; // 'all' or 'per'
      final selectedHabitId = prefs.getString('widget_habit_id');

      List<Map<String, dynamic>> calendar;
      String? sentHabitId;

      if (mode == 'per') {
        // Determine target habit: prefer changedHabit, then selectedHabitId, then first active habit
        Habit? target = changedHabit;
        if (target == null && selectedHabitId != null) {
          target = getHabitById(selectedHabitId);
        }
        if (target == null && activeHabits.isNotEmpty) {
          target = activeHabits.first;
        }

        if (target != null) {
          calendar = _buildCalendarForHabit(target);
          sentHabitId = target.id;
        } else {
          // fallback to all-habits calendar if no target found
          calendar = _buildCalendarData();
          sentHabitId = null;
        }
      } else {
        calendar = _buildCalendarData();
        sentHabitId = null;
      }

      String habitNameToSend = '';
      String nextReminderToSend = '';
      int? habitColorToSend;
      int? habitIconToSend;
      if (sentHabitId != null) {
        final habit = getHabitById(sentHabitId);
        if (habit != null) {
          habitNameToSend = habit.name;
          nextReminderToSend = _formatNextReminder(habit);
          habitColorToSend = habit.color.value;
          habitIconToSend = habit.icon.codePoint;
        }
      }

      await WidgetService.updateWidget(
        streakCount: _allHabitsDayStreak(),
        todayCompleted: _areAllHabitsCompleted(),
        habitName: habitNameToSend,
        nextReminder: nextReminderToSend,
        habitColor: habitColorToSend,
        habitIcon: habitIconToSend,
        calendar: calendar,
        mode: mode,
        habitId: sentHabitId,
      );
      await WidgetService.refreshWidget();
    } catch (e) {
      debugPrint('Error updating native widget: $e');
    }
  }

  List<Map<String, dynamic>> _buildCalendarForHabit(Habit habit) {
    final List<Map<String, dynamic>> days = [];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      days.add({
        'day': day.toString(),
        'done': _didCompleteHabitOnDate(habit, date),
      });
    }
    return days;
  }

  List<Map<String, dynamic>> _buildCalendarData() {
    // All days of the current month, ordered 1..daysInMonth
    final List<Map<String, dynamic>> days = [];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      days.add({
        'day': day.toString(),
        'done': _areAllHabitsCompletedOn(date),
      });
    }
    return days;
  }

  bool _areAllHabitsCompletedOn(DateTime date) {
    final activeHabitsList = activeHabits;
    if (activeHabitsList.isEmpty) return false;
    return activeHabitsList.every((habit) => _didCompleteHabitOnDate(habit, date));
  }

  int _allHabitsDayStreak() {
    // Count consecutive days ending today where all habits were completed
    int streak = 0;
    DateTime cursor = DateTime.now();

    while (_areAllHabitsCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  bool _didCompleteHabitOnDate(Habit habit, DateTime date) {
    final key = _getDateKey(date);
    final count = habit.dailyCompletions[key] ?? 0;
    return count >= habit.remindersPerDay;
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((habit) => habit.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Habit> getHabitsCompletedOn(DateTime date) {
    return _habits.where((habit) {
      return habit.completedDates.any((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day);
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool isHabitNameTaken(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _habits.any((habit) {
      if (excludeId != null && habit.id == excludeId) {
        return false;
      }
      return habit.name.trim().toLowerCase() == normalized;
    });
  }

  /// Public method to force a widget refresh from outside the provider.
  Future<void> refreshWidget() async {
    try {
      await _updateNativeWidget();
    } catch (e) {
      debugPrint('Error refreshing widget: $e');
    }
  }
}
