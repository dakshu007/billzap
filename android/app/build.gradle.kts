import java.util.Properties

plugins {
    id("com.android.application")
    // Kotlin is applied by the Flutter Gradle Plugin (built-in Kotlin).
    // Declaring org.jetbrains.kotlin.android here as well is what Flutter
    // 3.47 warns "will cause build failures in future versions".
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties, which CI writes from
// repository secrets and a developer creates locally. When it is absent we
// fall back to debug keys so `flutter run --release` still works.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = keyPropertiesFile.exists()

android {
    // NOTE: namespace and applicationId must stay com.billzap.app — this is
    // the published identity. Changing it would orphan every existing
    // install and break Play Store updates.
    namespace = "com.billzap.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.billzap.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String?
                keyPassword = keyProperties["keyPassword"] as String?
                storeFile = (keyProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keyProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 shrinks and obfuscates the thin Java/Kotlin embedding layer
            // and emits mapping.txt, which Flutter bundles into the AAB. That
            // clears Play's "no deobfuscation file" warning and trims size.
            // Resource shrinking stays off — marginal win, more risk.
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            // Native debug symbols, for Play's crash symbolication — but
            // only when the build asks for them.
            //
            // An earlier comment here claimed this was "stripped from
            // user-facing APKs, so it costs no download size". It is not.
            // Setting it on the release buildType applies to every output,
            // and the unstripped .so files take the universal APK from
            // ~28 MB to 67.7 MB, and the arm64 one to 25.0 MB. The app is
            // for shopkeepers on slow connections; that is 40 MB of symbol
            // tables nobody installing the APK can use.
            //
            // So it is opt-in. The appbundle build sets
            // BILLZAP_PLAY_SYMBOLS=1 and Play still gets everything it
            // needs; APK builds leave it unset and ship stripped
            // libraries. release.yml also fails the run if the APK comes
            // out over 45 MB, because this is the kind of thing that comes
            // back silently.
            if (System.getenv("BILLZAP_PLAY_SYMBOLS") == "1") {
                ndk {
                    debugSymbolLevel = "SYMBOL_TABLE"
                }
            }

            // ── Sideloaded APK size ──────────────────────────────────
            //
            // Measured on build 260502274: the APK is 67.7 MB, and
            // 64.2 MB of that is lib/. Three copies of the engine and
            // the compiled app, stored uncompressed:
            //
            //   x86_64       libflutter 13.05 + libapp  9.90 = 22.95 MB
            //   arm64-v8a    libflutter 11.75 + libapp  9.63 = 21.38 MB
            //   armeabi-v7a  libflutter  8.62 + libapp 10.93 = 19.55 MB
            //
            // Those are stripped libraries; this is simply what a
            // three-architecture Flutter build weighs.
            //
            // Play never sees this. It gets the bundle and sends each
            // phone only its own slice. The problem is the APK on the
            // website, which is one file for everybody — so it is the
            // one that gets trimmed:
            //
            //   • x86_64 is emulators. No retail Android phone runs it,
            //     and 23 MB is a third of the download.
            //   • Uncompressed .so files let Android mmap them straight
            //     from the APK, which is the right default when Play
            //     does the delivering. For a file somebody downloads
            //     over mobile data it is the wrong trade: compressing
            //     them costs a little disk and startup time on the
            //     phone and saves more than half the download.
            //
            // Neither applies to the bundle, so both are gated on the
            // same flag the symbols use, inverted.
            val buildingForPlay = System.getenv("BILLZAP_PLAY_SYMBOLS") == "1"
            if (!buildingForPlay) {
                ndk {
                    abiFilters.clear()
                    abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
                }
            }
        }
    }

    packaging {
        jniLibs {
            // See the note in buildTypes.release: compressed for the
            // downloadable APK, left alone for the Play bundle.
            useLegacyPackaging = System.getenv("BILLZAP_PLAY_SYMBOLS") != "1"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
