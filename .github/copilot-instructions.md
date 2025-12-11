## Purpose

This file gives AI coding agents immediate, actionable context for working on the Streakly Flutter app. It focuses on the actual repo patterns, integration points, and exact files to consult when making changes.

**Big Picture (what to know first)**
- Flutter app (mobile-first) with UI under `lib/screens/` and state under `lib/providers/`.
- Persistence is local-first: `HiveService` (`lib/services/hive_service.dart`) is the canonical storage layer. Supabase usage is deprecated/stubbed (`lib/services/supabase_service.dart`). See `pubspec.yaml` comment: "Supabase removed - using local Hive storage instead." 
- App wiring lives in `lib/main.dart`: services are created (AdMob, PurchaseService, Hive, Notifications) and injected into providers via `MultiProvider`.
- Key service entry points: `lib/services/*` (notably `hive_service.dart`, `notification_service.dart`, `purchase_service.dart`, `admob_service.dart`, `widget_service.dart`).

**Critical developer workflows**
- Install deps: `flutter pub get` from project root.
- Run app (device/emulator): `flutter run` or use the workspace VS Code task `Run Flutter Project`.
- Run tests: `flutter test` (there is a `test/widget_test.dart`).
- Android/iOS builds: `flutter build apk` / `flutter build ios` (iOS requires opening `ios/Runner.xcworkspace` in Xcode for signing).
- Logs: use `flutter run` output or `adb logcat` for Android-specific traces. The project prints helpful debug lines (see `SETUP_CHECKLIST.md` — look for lines like "Using: REAL SUPABASE" and other emoji-prefixed messages).

**Project-specific conventions & patterns**
- State management: `provider` package. New global state objects are added to `MultiProvider` in `lib/main.dart`. Example providers: `AuthProvider`, `HabitProvider`, `NoteProvider`, `ThemeProvider`.
- Service injection: services are created in `main.dart` and passed into providers (AdMob instance is passed via `Provider.value`). When adding a service, follow that pattern: create singleton service under `lib/services/`, initialize in `main()` and inject into `MultiProvider`.
- Persistence migration: the codebase previously used Supabase. If you need server-backed features, consult `SUPABASE_SETUP.md`, `supabase_schema.sql`, and `SETUP_CHECKLIST.md` — but prefer `HiveService` unless explicitly re-enabling Supabase. `lib/services/supabase_service.dart` is intentionally deprecated and kept as a stub to avoid breaking imports.
- Notifications: `notification_initializer.dart` runs timezone and channel setup. However push/local notification scheduling is intentionally limited — confirm `initializeNotificationService()` usage in `lib/main.dart` and `lib/services/notification_service.dart` before modifying scheduling behavior.

**Integration points & external dependencies**
- Firebase: `firebase_core`, `firebase_messaging` are included — messaging likely used for push notifications; check `notification_initializer.dart` and `lib/services/notification_service.dart`.
- Ads: `google_mobile_ads` via `lib/services/admob_service.dart`.
- In-app purchases: `purchase_service.dart` handles initialization and restore flows (calls in `main()` on startup).
- Home widget: `home_widget` and related `widget_service.dart` for iOS/Android home widgets.
- Local storage: `hive`, `hive_flutter`, and `hive_adapters.dart` (adapters live in `lib/services/`).

**Useful files to read for context**
- `lib/main.dart` — app bootstrap and provider wiring.
- `lib/services/hive_service.dart` — canonical persistence API (read/write patterns).
- `lib/services/supabase_service.dart` — deprecated; shows Supabase is intentionally removed.
- `lib/providers/*` — business logic for auth, habits, notes.
- `lib/screens/*` — UI patterns, routes, and how providers are consumed.
- `SETUP_CHECKLIST.md`, `SUPABASE_SETUP.md`, `supabase_schema.sql` — operational and migration notes.
- `HABIT_COMPLETION_LOCK.md`, `TIME_OF_DAY_UPDATE.md`, `FIX_DUPLICATE_USER_ERROR.md` — domain rules and historical fixes to respect when changing logic.

**Actionable examples for common edits**
- Add a provider: create `lib/providers/my_provider.dart`, expose ChangeNotifier, then register it inside `MultiProvider` in `lib/main.dart` like existing providers (follow constructor patterns for services that need `AdmobService`).
- Persist a new model: add Hive adapter in `lib/services/hive_adapters.dart`, register it in `HiveService.init()`, and use `HiveService.instance` methods for CRUD. Avoid adding Supabase calls unless you intentionally re-enable server sync.
- Add scheduled notification: prefer using `notification_service.dart` helpers and `notification_initializer.dart` flow. Confirm timezone setup (uses `timezone` package).

**Testing & debugging pointers**
- Use `flutter run --no-sound-null-safety` only if you hit null-safety issues (repo targets Dart SDK >=3.5 so avoid bypassing null safety unless necessary).
- To reproduce habit/completion behavior, follow steps in `SETUP_CHECKLIST.md` — create habits across the four time buckets (Morning/Afternoon/Evening/Night). Watch console for the emoji-prefixed logs (they help trace flows).

**When you see Supabase in code**
- Treat it as legacy: check `pubspec.yaml` notes and `lib/services/supabase_service.dart` before introducing or relying on remote DB behavior. If reintroducing Supabase, update `lib/config/supabase_config.dart` (per `SUPABASE_SETUP.md`) and re-run `supabase_schema.sql` in your Supabase project.

**If you change data models**
- Update Hive adapters and migration code in `hive_adapters.dart` and `HiveService`. If the change might affect DB schema previously migrated to Supabase, update the SQL in `supabase_schema.sql` and document the migration in the corresponding `FIX_*.md` file.

**Final notes & questions for maintainers**
- Confirm whether Supabase is permanently retired or only temporarily replaced by Hive. That determines whether server-sync PRs are acceptable.
- Do you want CI to run `flutter test`? If so, share preferred matrix (platforms/devices).

---
If anything here is unclear or you want me to expand any section (CI, deeper architecture, or add code snippets), tell me which area to iterate on next.
