pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        assert(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader")
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven {
            val flutterSdkPath = run {
                val properties = java.util.Properties()
                file("local.properties").inputStream().use { properties.load(it) }
                properties.getProperty("flutter.sdk")
            }
            url = uri("$flutterSdkPath/bin/cache/artifacts/engine-maven")
        }
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

include(":app")