# ProGuard / R8 rules for AudiFi

# Preserve AudioService background service and callbacks
-keep class com.ryanheise.audioservice.** { *; }

# Preserve just_audio engine and ExoPlayer platform channels
-keep class com.ryanheise.just_audio.** { *; }

# Preserve AndroidX Media notification and MediaSession classes
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
