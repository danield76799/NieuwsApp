# ProGuard rules for Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.widget.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepattributes *Annotation*

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class org.greenrobot.eventbus.** { *; }

# Dynamic Color
-keep class com.google.android.material.color.** { *; }

# Firebase (if used)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Retrofit (if used)
-keep class retrofit2.** { *; }
-keepattributes Signature

# OkHttp (if used)
-keep class okhttp3.** { *; }

# GSON (if used)
-keep class com.google.gson.** { *; }

# SharedPreferences
-keep class android.support.v4.app.** { *; }
-keep class android.preference.** { *; }

# HttpClient
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.pathprovider.PathProviderPlugin { *; }

# NieuwsApp-specific
-keep class nl.danield.nieuwsapp.** { *; }
-keep class nl.danield.nieuwsapp.models.** { *; }
-keep class nl.danield.nieuwsapp.services.** { *; }
-keep class nl.danield.nieuwsapp.widgets.** { *; }

# Keep Dart code
-keep class dart.** { *; }

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

# Play Core (fixes R8 missing class errors)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManager { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallSessionState { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }
-dontwarn com.google.android.play.core.**

# Deferred Components (Flutter)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# General dontwarn for missing classes
-dontwarn com.google.android.gms.**
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
-dontwarn org.conscrypt.**
-dontwarn com.android.org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn com.sun.net.ssl.**
-dontwarn javax.naming.**
-dontwarn javax.servlet.**
-dontwarn org.ietf.jgss.**
-dontwarn org.w3c.dom.**
-dontwarn org.xml.sax.**
-dontwarn sun.security.**
-dontwarn java.awt.**
-dontwarn javax.swing.**
-dontwarn java.beans.**
-dontwarn javax.imageio.**
-dontwarn javax.security.**
-dontwarn java.rmi.**
-dontwarn javax.transaction.**
-dontwarn javax.activation.**
-dontwarn com.sun.activation.**
-dontwarn org.joda.time.**
-dontwarn com.facebook.**
-dontwarn com.twitter.**
-dontwarn com.google.api.**
-dontwarn com.google.cloud.**
-dontwarn com.google.protobuf.**
-dontwarn com.google.zxing.**
-dontwarn com.google.firebase.crashlytics.**
-dontwarn com.google.firebase.messaging.**
-dontwarn com.google.firebase.analytics.**
-dontwarn com.google.firebase.perf.**
-dontwarn com.google.firebase.inappmessaging.**
-dontwarn com.google.firebase.ml.**
-dontwarn com.google.firebase.database.**
-dontwarn com.google.firebase.storage.**
-dontwarn com.google.firebase.auth.**
-dontwarn com.google.firebase.firestore.**
-dontwarn com.google.firebase.functions.**
-dontwarn com.google.firebase.remoteconfig.**
-dontwarn com.google.firebase.appindexing.**
-dontwarn com.google.firebase.dynamiclinks.**
-dontwarn com.google.firebase.appinvite.**
-dontwarn com.google.firebase.perf.**
-dontwarn com.google.firebase.ml.**
-dontwarn com.google.firebase.vision.**
-dontwarn com.google.firebase.ml.vision.**
-dontwarn com.google.firebase.ml.custom.**
-dontwarn com.google.firebase.ml.naturallanguage.**
-dontwarn com.google.firebase.ml.modeldownloader.**
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.gms.maps.**
-dontwarn com.google.android.gms.location.**
-dontwarn com.google.android.gms.places.**
-dontwarn com.google.android.gms.fitness.**
-dontwarn com.google.android.gms.games.**
-dontwarn com.google.android.gms.wallet.**
-dontwarn com.google.android.gms.drive.**
-dontwarn com.google.android.gms.auth.**
-dontwarn com.google.android.gms.identity.**
-dontwarn com.google.android.gms.measurement.**
-dontwarn com.google.android.gms.tagmanager.**
-dontwarn com.google.android.gms.awareness.**
-dontwarn com.google.android.gms.cast.**
-dontwarn com.google.android.gms.nearby.**
-dontwarn com.google.android.gms.panorama.**
-dontwarn com.google.android.gms.plus.**
-dontwarn com.google.android.gms.safetynet.**
-dontwarn com.google.android.gms.security.**
-dontwarn com.google.android.gms.analytics.**
-dontwarn com.google.android.gms.appstate.**
-dontwarn com.google.android.gms.base.**
-dontwarn com.google.android.gms.common.**
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.android.gms.instantapps.**
-dontwarn com.google.android.gms.iid.**
-dontwarn com.google.android.gms.gcm.**
-dontwarn com.google.android.gms.tasks.**
-dontwarn com.google.android.gms.vision.**
-dontwarn com.google.android.gms.wearable.**
-dontwarn com.google.android.gms.ads.identifier.**
-dontwarn com.google.android.gms.ads.impl.**
-dontwarn com.google.android.gms.ads.mediation.**
-dontwarn com.google.android.gms.ads.reward.**
-dontwarn com.google.android.gms.ads.search.**
-dontwarn com.google.android.gms.ads.formats.**
-dontwarn com.google.android.gms.ads.doubleclick.**
-dontwarn com.google.android.gms.ads.purchase.**
-dontwarn com.google.android.gms.ads.rewarded.**
-dontwarn com.google.android.gms.ads.instream.**
-dontwarn com.google.android.gms.ads.reward.mediation.**
-dontwarn com.google.android.gms.ads.appopen.**
-dontwarn com.google.android.gms.ads.nativead.**
-dontwarn com.google.android.gms.ads.interstitial.**
-dontwarn com.google.android.gms.ads.rewardedinterstitial.**
-dontwarn com.google.android.gms.ads.identifier.**
-dontwarn com.google.android.gms.ads.impl.**
-dontwarn com.google.android.gms.ads.mediation.**
-dontwarn com.google.android.gms.ads.reward.**
-dontwarn com.google.android.gms.ads.search.**
-dontwarn com.google.android.gms.ads.formats.**
-dontwarn com.google.android.gms.ads.doubleclick.**
-dontwarn com.google.android.gms.ads.purchase.**
-dontwarn com.google.android.gms.ads.rewarded.**
-dontwarn com.google.android.gms.ads.instream.**
-dontwarn com.google.android.gms.ads.reward.mediation.**
-dontwarn com.google.android.gms.ads.appopen.**
-dontwarn com.google.android.gms.ads.nativead.**
-dontwarn com.google.android.gms.ads.interstitial.**
-dontwarn com.google.android.gms.ads.rewardedinterstitial.**
-dontwarn com.google.android.gms.ads.identifier.**
-dontwarn com.google.android.gms.ads.impl.**
-dontwarn com.google.android.gms.ads.mediation.**
-dontwarn com.google.android.gms.ads.reward.**
-dontwarn com.google.android.gms.ads.search.**
-dontwarn com.google.android.gms.ads.formats.**
-dontwarn com.google.android.gms.ads.doubleclick.**
-dontwarn com.google.android.gms.ads.purchase.**
-dontwarn com.google.android.gms.ads.rewarded.**
-dontwarn com.google.android.gms.ads.instream.**
-dontwarn com.google.android.gms.ads.reward.mediation.**
-dontwarn com.google.android.gms.ads.appopen.**
-dontwarn com.google.android.gms.ads.nativead.**
-dontwarn com.google.android.gms.ads.interstitial.**
-dontwarn com.google.android.gms.ads.rewardedinterstitial.**