-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep annotations
-keepattributes *Annotation*

# Keep signatures for reflection
-keepattributes Signature
-keepattributes Exceptions

# WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.startup.InitializationProvider
-keep class * extends androidx.startup.AppStartup

# Room / WorkDatabase
-keep class * extends androidx.room.RoomDatabase
-keep class * extends androidx.room.RoomDatabase$Callback

# Isar
-keep class * extends io.isar.IsarCollectionBase
-keep class * extends io.isar.IsarObject
-keep @io.isar.annotations.* class *
-keep class io.isar.** { *; }
-keep class io.isar.core.** { *; }
-keep class io.isar.**$$serializer { *; }
-keepclassmembers class io.isar.** {
    <fields>;
    <methods>;
}

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.jakewharton.** { *; }

# Provider
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Fonts
-keep class com.google.** { *; }

# Keep data classes for Isar serialization
-keep class com.pocketpitapps.bill_pit.data.models.** { *; }
-keep class com.pocketpitapps.bill_pit.data.models.Expense { *; }

# General Android
-keep class android.support.** { *; }
-keep class androidx.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
