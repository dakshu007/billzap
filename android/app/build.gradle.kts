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

            // Ship native debug symbols in the AAB so Play can symbolicate
            // native crashes and ANRs. Stripped from user-facing APKs, so it
            // costs no download size.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
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
