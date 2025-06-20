# Flutter
-keep class io.flutter.embedding.engine.FlutterEngine { *; }

# Needed for SharedPreferences
-keep class androidx.security.** { *; }
-keep class android.security.** { *; }

# Needed for flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# FlutterLocalNotifications keep rules
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }