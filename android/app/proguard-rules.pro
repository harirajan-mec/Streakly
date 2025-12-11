# Keep generic type signatures so Gson TypeToken works (fixes "Missing type parameter").
-keepattributes Signature

# Keep flutter_local_notifications classes and their members.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson core types used by the plugin.
-keep class com.google.gson.** { *; }
-keep class com.google.gson.internal.bind.** { *; }

# Keep Flutter embedding/plugin classes referenced via reflection.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.ads.** { *; }
