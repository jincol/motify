# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Background Service
-keep class id.flutter.flutter_background_service.** { *; }

# Play Core (evitar errores de clases faltantes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
