# ───────────────────────────────────────────────────────────────────────────
# BillZap — R8 / ProGuard keep rules
#
# R8 only touches the thin Java/Kotlin embedding layer (MainActivity + the
# Android side of plugins). All app logic is Dart compiled to libapp.so and is
# never seen by R8. Most plugins ship their own consumer rules; the rules below
# cover the Flutter embedding plus the few reflection / split-install paths
# that otherwise trip up a first minify build.
# ───────────────────────────────────────────────────────────────────────────

# ── Flutter engine / embedding ──────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── App entry point (referenced from AndroidManifest by name) ───────────────
-keep class com.billzap.app.** { *; }

# ── Google Play Core ────────────────────────────────────────────────────────
# Flutter's embedding references Play Core (deferred components / split install)
# classes that aren't on the classpath for a normal, non-dynamic-feature app.
# Without -dontwarn, R8 aborts the build with "Missing class" errors.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── local_auth (biometric prompt via AndroidX Biometric) ────────────────────
-keep class androidx.biometric.** { *; }

# ── Attributes some plugins read at runtime via reflection ──────────────────
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod, Exceptions
