# ProGuard rules for Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Dart code
-keep class dart.** { *; }
-keep class com.example.nieuws_app.** { *; }

# HTTP and networking
-keep class com.squareup.okhttp.** { *; }
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp.**
-dontwarn com.squareup.okhttp3.**

# JSON parsing
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent R8 from leaving data members accessible
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Shared preferences
-keep class android.content.SharedPreferences { *; }

# WebView
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}