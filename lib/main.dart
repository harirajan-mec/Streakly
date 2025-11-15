import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

import 'screens/auth/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/note_provider.dart';
import 'providers/theme_provider.dart';
import 'services/admob_service.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (safe mode)
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized');
  } catch (e) {
    print('⚠️ Supabase initialization failed (offline): $e');
  }

  // Initialize Google Mobile Ads (safe mode)
  try {
    await MobileAds.instance.initialize();
    print('✅ MobileAds initialized');
  } catch (e) {
    print('⚠️ Ads unavailable: $e');
  }

  // Initialize Notification Service
  final NotificationService notificationService = NotificationService();

  try {
    await notificationService.init();
    await notificationService.requestPermissions();

    // 🔥 One-time cleanup of corrupted old notifications
    await notificationService.cleanupOldCorruptedNotifications();
    print('🧹 Old notifications cleaned');

    print('✅ Notifications initialized');
  } catch (e) {
    print('⚠️ Notifications not available: $e');
  }

  // Prevent Flutter-specific non-fatal framework crashes (DevicePreview)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('_debugDuringDeviceUpdate')) {
      return; // Ignore mouse tracker errors in DevicePreview
    }
    FlutterError.presentError(details);
  };

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const StreaklyApp(),
    ),
  );
}

class StreaklyApp extends StatefulWidget {
  const StreaklyApp({super.key});

  @override
  State<StreaklyApp> createState() => _StreaklyAppState();
}

class _StreaklyAppState extends State<StreaklyApp> {
  final AdmobService _admobService = AdmobService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _admobService),
        ChangeNotifierProvider(create: (_) => AuthProvider(_admobService)),
        ChangeNotifierProvider(create: (_) => HabitProvider(_admobService)),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        title: 'Streakly - Habit Tracker',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4B0082),
            secondary: Color(0xFF4B0082),
            surface: Color(0xFF121212),
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: const CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
