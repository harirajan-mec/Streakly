import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/habit.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  // Check if Supabase is properly configured
  bool get _isSupabaseConfigured {
    final isConfigured = SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL' &&
        SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
        SupabaseConfig.supabaseUrl.isNotEmpty &&
        SupabaseConfig.supabaseAnonKey.isNotEmpty &&
        SupabaseConfig.supabaseUrl.contains('supabase.co');
    print('🔧 Supabase Configuration Check:');
    print('   ✓ Configured: $isConfigured');
    print('   ✓ URL: ${SupabaseConfig.supabaseUrl}');
    print('   ✓ Using: ${isConfigured ? "REAL SUPABASE" : "MOCK/DEMO MODE"}');
    return isConfigured;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      final isConfigured = SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL' &&
          SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
          SupabaseConfig.supabaseUrl.contains('supabase.co');

      if (isConfigured) {
        print('🚀 Initializing REAL Supabase connection...');
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
        print('✅ Supabase initialized successfully!');
      } else {
        print('⚠️  Supabase not configured - Please provide valid credentials');
        throw Exception('Supabase not configured');
      }
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  // Auth Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    print('📝 SignUp Request for: $email');

    print('   ✅ Using REAL Supabase for signup');
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    // Note: User profile is automatically created by database trigger (handle_new_user)
    // No need to manually create it here
    print('   ✅ User profile will be auto-created by database trigger');

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 SignIn Request for: $email');

    print('   ✅ Using REAL Supabase for signin');

    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // User Profile Methods
  Future<AppUser?> getUserProfile([String? userId]) async {
    print('🔍 Fetching user profile...');

    final id = userId ?? currentUserId;
    if (id == null) return null;

    try {
      final response = await client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', id)
          .single();

      print('   ✅ User profile data: ${response['avatar_url']}');
      final user = AppUser.fromJson(response);
      print('   ✅ Parsed avatar: ${user.avatarUrl}');
      return user;
    } catch (e) {
      print('   ❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await client.from(SupabaseConfig.usersTable).update(data).eq('id', userId);
  }

  // Habit Methods
  Future<List<Habit>> getUserHabits() async {
    print('📋 Fetching user habits...');

    print('   ✅ Fetching from REAL Supabase');

    if (currentUserId == null) return [];

    final response = await client
        .from(SupabaseConfig.habitsTable)
        .select('*, habit_completions(*)')
        .eq('user_id', currentUserId!)
        .order('created_at');

    return response.map<Habit>((json) => _habitFromSupabaseJson(json)).toList();
  }

  Future<Habit> createHabit(Habit habit) async {
    print('➕ Creating habit: ${habit.name}');

    print('   ✅ Creating in REAL Supabase');

    final habitData = _habitToSupabaseJson(habit);
    habitData['user_id'] = currentUserId;

    final response = await client
        .from(SupabaseConfig.habitsTable)
        .insert(habitData)
        .select()
        .single();

    return _habitFromSupabaseJson(response);
  }

  Future<void> updateHabit(Habit habit) async {
    print('✏️  Updating habit: ${habit.name}');

    print('   ✅ Updating in REAL Supabase');

    final habitData = _habitToSupabaseJson(habit);
    habitData['updated_at'] = DateTime.now().toIso8601String();

    await client
        .from(SupabaseConfig.habitsTable)
        .update(habitData)
        .eq('id', habit.id);
  }

  Future<void> deleteHabit(String habitId) async {
    print('🗑️  Deleting habit: $habitId');

    print('   ✅ Deleting from REAL Supabase');

    // Delete completions first
    await client
        .from(SupabaseConfig.habitCompletionsTable)
        .delete()
        .eq('habit_id', habitId);

    // Delete habit
    await client.from(SupabaseConfig.habitsTable).delete().eq('id', habitId);
  }

  Future<void> recordHabitCompletion({
    required String habitId,
    required DateTime completionDate,
    int count = 1,
  }) async {
    final dateKey = _getDateKey(completionDate);

    // Check if completion already exists for this date
    final existing = await client
        .from(SupabaseConfig.habitCompletionsTable)
        .select()
        .eq('habit_id', habitId)
        .eq('completion_date', dateKey)
        .maybeSingle();

    if (existing != null) {
      // Update existing completion
      await client.from(SupabaseConfig.habitCompletionsTable).update({
        'completion_count': count,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    } else {
      // Create new completion
      await client.from(SupabaseConfig.habitCompletionsTable).insert({
        'habit_id': habitId,
        'user_id': currentUserId,
        'completion_date': dateKey,
        'completion_count': count,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeHabitCompletion({
    required String habitId,
    required DateTime completionDate,
  }) async {
    final dateKey = _getDateKey(completionDate);

    await client
        .from(SupabaseConfig.habitCompletionsTable)
        .delete()
        .eq('habit_id', habitId)
        .eq('completion_date', dateKey);
  }

  // Helper Methods
  Map<String, dynamic> _habitToSupabaseJson(Habit habit) {
    return {
      'id': habit.id,
      'name': habit.name,
      'description': habit.description,
      'icon_code_point':
          habit.icon.codePoint, // Store actual codepoint (BIGINT in DB)
      'color_value':
          habit.color.value, // Store actual color value (BIGINT in DB)
      'frequency': habit.frequency.name,
      'time_of_day': habit.timeOfDay.name,
      'habit_type': habit.habitType.name,
      'is_active': habit.isActive,
      'reminder_hour': habit.reminderTime?.hour,
      'reminder_minute': habit.reminderTime?.minute,
      'reminders_per_day': habit.remindersPerDay,
      'created_at': habit.createdAt.toIso8601String(),
    };
  }

  // Helper function to safely create IconData
  IconData _safeIconData(dynamic codePoint) {
    if (codePoint is int) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    // Fallback to a default icon if codePoint is invalid
    return Icons.star; // Default fallback icon
  }

  Habit _habitFromSupabaseJson(Map<String, dynamic> json) {
    // Process completions from join
    final completions = <DateTime>[];
    final dailyCompletions = <String, int>{};

    if (json['habit_completions'] != null) {
      for (final completion in json['habit_completions']) {
        final date = DateTime.parse(completion['completion_date']);
        completions.add(date);
        dailyCompletions[_getDateKey(date)] =
            completion['completion_count'] ?? 1;
      }
    }

    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _safeIconData(json['icon_code_point']),
      color: Color(json['color_value']),
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      timeOfDay: HabitTimeOfDay.values.firstWhere(
        (e) => e.name == json['time_of_day'],
        orElse: () => HabitTimeOfDay.night,
      ),
      habitType: HabitType.values.firstWhere(
        (e) => e.name == json['habit_type'],
        orElse: () => HabitType.build,
      ),
      createdAt: DateTime.parse(json['created_at']),
      completedDates: completions,
      isActive: json['is_active'] ?? true,
      reminderTime:
          json['reminder_hour'] != null && json['reminder_minute'] != null
              ? TimeOfDay(
                  hour: json['reminder_hour'], minute: json['reminder_minute'])
              : null,
      remindersPerDay: json['reminders_per_day'] ?? 1,
      dailyCompletions: dailyCompletions,
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> subscribeToUserHabits() {
    return client
        .from(SupabaseConfig.habitsTable)
        .stream(primaryKey: ['id']).eq('user_id', currentUserId!);
  }

  Future<List<LeaderboardEntry>> getLeaderboardEntries({int limit = 20}) async {
    final sanitizedLimit = limit.clamp(1, 100).toInt();
    print('📊 Fetching leaderboard data (limit: $sanitizedLimit)...');

    // Prefer the security-definer RPC so RLS does not hide other users
    try {
      final response = await client.rpc(
        'get_public_leaderboard',
        params: {'limit_count': sanitizedLimit},
      );

      if (response is List) {
        return response
            .map((row) => LeaderboardEntry.fromJson(
                Map<String, dynamic>.from(row as Map<dynamic, dynamic>)))
            .toList();
      }
    } catch (rpcError) {
      print('   ⚠️ RPC get_public_leaderboard failed: $rpcError');
    }

    // Fallback to direct select (may be limited by RLS to the current user)
    final selectResponse = await client
        .from(SupabaseConfig.userStatsTable)
        .select(
            'user_id,total_habits,total_completions,current_streak,longest_streak,users:users!inner(id,name,email,avatar_url)')
        .order('current_streak', ascending: false)
        .order('total_completions', ascending: false)
        .order('longest_streak', ascending: false)
        .limit(sanitizedLimit);

    return selectResponse
        .map<LeaderboardEntry>((json) => LeaderboardEntry.fromJson(json))
        .toList();
  }

  // Note Methods
  Future<List<Map<String, dynamic>>> getUserNotes() async {
    print('📋 Fetching user notes...');

    print('   ✅ Fetching from REAL Supabase');

    if (currentUserId == null) return [];

    final response = await client
        .from(SupabaseConfig.notesTable)
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createNote(Map<String, dynamic> noteData) async {
    print('➕ Creating note: ${noteData['title']}');

    print('   ✅ Creating in REAL Supabase');

    noteData['user_id'] = currentUserId;

    final response = await client
        .from(SupabaseConfig.notesTable)
        .insert(noteData)
        .select()
        .single();

    return response;
  }

  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    print('✏️  Updating note: $noteId');

    print('   ✅ Updating in REAL Supabase');

    noteData['updated_at'] = DateTime.now().toIso8601String();

    await client
        .from(SupabaseConfig.notesTable)
        .update(noteData)
        .eq('id', noteId);
  }

  Future<void> deleteNote(String noteId) async {
    print('🗑️  Deleting note: $noteId');

    print('   ✅ Deleting from REAL Supabase');

    await client.from(SupabaseConfig.notesTable).delete().eq('id', noteId);
  }

  Future<List<Map<String, dynamic>>> getNotesForHabit(String habitId) async {
    print('📋 Fetching notes for habit: $habitId');

    print('   ✅ Fetching from REAL Supabase');

    if (currentUserId == null) return [];

    final response = await client
        .from(SupabaseConfig.notesTable)
        .select()
        .eq('user_id', currentUserId!)
        .eq('habit_id', habitId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
