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

  // Initialize Supabase (with error handling for web preview)
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized');
  } catch (e) {
    print('⚠️ Supabase initialization failed (running in offline mode): $e');
  }

  // Initialize MobileAds (with error handling for web)
  try {
    await MobileAds.instance.initialize();
    print('✅ MobileAds initialized');
  } catch (e) {
    print('⚠️ MobileAds not available on web: $e');
  }

  // Initialize Notification Service (with error handling for web)
  try {
    final NotificationService notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
    print('✅ Notifications initialized');
  } catch (e) {
    print('⚠️ Notifications not available on web: $e');
  }

  // Handle Flutter framework errors gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log the error but don't crash the app for framework issues
    if (details.exception.toString().contains('_debugDuringDeviceUpdate')) {
      // Ignore mouse tracker assertion errors
      return;
    }
    FlutterError.presentError(details);
  };

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Only enable in debug/profile mode, not in release
      builder: (context) => StreaklyApp(),
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
  void initState() {
    super.initState();
    // Ad loading is now handled by AuthProvider based on premium status
  }

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
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF4B0082), // Exact #4B0082 (Indigo/Purple)
            // Keep dark theme colors but use exact primary color
            secondary: const Color(0xFF4B0082),
            surface: const Color(0xFF121212),
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
