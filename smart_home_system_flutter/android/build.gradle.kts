plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
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
    
    // Force plugins to use correct SDK version to avoid conflicts
    // Exclude 'app' because it is already evaluated (due to evaluationDependsOn above) and we updated it manually.
    if (project.name != "app") {
        afterEvaluate {
            if (project.extensions.findByName("android") != null) {
                project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                    compileSdkVersion(36)
                    defaultConfig {
                        targetSdkVersion(36)
                    }
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
