import groovy.json.JsonSlurper
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The church settings file (ADR 0007) reaches Gradle as Flutter's `dart-defines` property:
// each KEY=VALUE base64-encoded, joined with commas.
val dartDefines: Map<String, String> =
    (findProperty("dart-defines") as String?)
        .orEmpty()
        .split(",")
        .filter { it.isNotBlank() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .filter { "=" in it }
        .associate { it.substringBefore("=") to it.substringAfter("=") }

// The church's folder, churches/<slug>/, is the one whose church.json has this build's
// APP_ID. It keeps what must stay out of git: the launcher icons made by
// tool/android_branding.dart, and the church's release key.
val churchDir: File? =
    dartDefines["APP_ID"]?.let { appId ->
        rootProject.file("../../../churches").listFiles()?.firstOrNull { dir ->
            val settings = File(dir, "church.json")
            settings.isFile && (JsonSlurper().parse(settings) as Map<*, *>)["APP_ID"] == appId
        }
    }

android {
    namespace = "com.example.church_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The church's package ID and home-screen name. Builds without a church file keep
        // the development identity.
        applicationId = dartDefines["APP_ID"] ?: "com.example.church_app"
        manifestPlaceholders["appName"] = dartDefines["APP_NAME"] ?: "church_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The church's launcher icons override the template's in every build type.
    churchDir?.resolve("android/res")?.takeIf { it.isDirectory }?.let { churchRes ->
        sourceSets
            .matching { it.name in setOf("debug", "profile", "release") }
            .configureEach { res.srcDir(churchRes) }
    }

    // android/key.properties names the key file, beside it, and its passwords.
    churchDir?.resolve("android/key.properties")?.takeIf { it.isFile }?.let { file ->
        val key = Properties().apply { file.inputStream().use { load(it) } }
        signingConfigs.create("church") {
            storeFile = file.resolveSibling(key.getProperty("storeFile"))
            storePassword = key.getProperty("storePassword")
            keyAlias = key.getProperty("keyAlias")
            keyPassword = key.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            // The church's own key when its folder has one; otherwise the debug key, so
            // `flutter run --release` works for development.
            signingConfig =
                signingConfigs.findByName("church") ?: signingConfigs.getByName("debug")
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
