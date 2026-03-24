import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val storeFilePath = keystoreProperties.getProperty("storeFile")
val resolvedStoreFile = if (!storeFilePath.isNullOrBlank()) rootProject.file(storeFilePath) else null

val hasCompleteReleaseSigning =
    keystorePropertiesFile.exists() &&
    resolvedStoreFile != null &&
    resolvedStoreFile.exists() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank()

android {
    namespace = "com.zenit.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.zenit.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = resolvedStoreFile
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = if (hasCompleteReleaseSigning)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}