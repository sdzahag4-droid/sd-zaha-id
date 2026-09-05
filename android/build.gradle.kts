allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("org.jetbrains.kotlin.android") apply false
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Blok pemaksaan SDK menggunakan Kotlin DSL yang kompatibel dengan AGP 9+
subprojects {
    afterEvaluate { p ->
        p.plugins.withId("com.android.application") {
            p.extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
                if (compileSdk < 36) {
                    compileSdk = 36
                }
            }
        }
        p.plugins.withId("com.android.library") {
            p.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                if (compileSdk < 36) {
                    compileSdk = 36
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}