# WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.startup.InitializationProvider
-keep class * extends androidx.startup.AppStartup

# Isar
-keep class * extends io.isar.IsarCollectionBase
-keep class * extends io.isar.IsarObject
-keep @io.isar.annotations.* class *
-keep class io.isar.** { *; }
-keep class io.isar.core.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Room/WorkDatabase
-keep class * extends androidx.room.RoomDatabase
-keep class * extends androidx.room.RoomDatabase$Callback
