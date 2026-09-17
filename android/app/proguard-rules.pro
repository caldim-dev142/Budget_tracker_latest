# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# SQLite and native libraries
-keep class org.sqlite.** { *; }
-keep class com.tekartik.** { *; }

# Firebase Auth and Google Sign In
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Local Auth (Biometric)
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Google Play Core (Deferred Components / SplitCompat)
-dontwarn com.google.android.play.core.**
