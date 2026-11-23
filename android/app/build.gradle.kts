import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jklabs.audifi"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.jklabs.audifi"
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

        signingConfigs {
        create("release") {
            require(keystorePropertiesFile.exists()) {
                "Release signing configuration missing: android/key.properties"
            }

            val keyFile = keystoreProperties.getProperty("storeFile")
                ?: error("storeFile missing in android/key.properties")

            storeFile = file(keyFile)

            storePassword = keystoreProperties.getProperty("storePassword")
                ?: error("storePassword missing in android/key.properties")

            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: error("keyAlias missing in android/key.properties")

            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: error("keyPassword missing in android/key.properties")

            require(storeFile!!.exists()) {
                "Release keystore does not exist: $storeFile"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
