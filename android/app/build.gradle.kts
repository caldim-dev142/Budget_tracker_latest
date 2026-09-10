import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.caldim.budgettracker"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.caldim.budgettracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val isReleaseSigningConfigured = keystorePropertiesFile.exists() || System.getenv("STORE_FILE") != null

    signingConfigs {
        if (isReleaseSigningConfigured) {
            create("release") {
                val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
                val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
                val storeFileProp = keystoreProperties.getProperty("storeFile") ?: System.getenv("STORE_FILE")
                val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD")

                if (storeFileProp != null) {
                    val resolvedStoreFile = rootProject.file(storeFileProp)
                    if (resolvedStoreFile.exists()) {
                        keyAlias = keyAliasProp
                        keyPassword = keyPasswordProp
                        storeFile = resolvedStoreFile
                        storePassword = storePasswordProp
                    } else {
                        throw GradleException("Production release keystore not found at: ${resolvedStoreFile.absolutePath}")
                    }
                }
            }
        }
    }

    buildTypes {
        release {
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
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

