allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Fix: flutter_google_places_sdk_android 0.2.2 is written against the Places
    // SDK 3.x API (place.address, placeTypes, userRatingsTotal), all of which were
    // removed in Places 4/5. Pin the last 3.x until the plugin catches up.
    configurations.configureEach {
        resolutionStrategy {
            force("com.google.android.libraries.places:places:3.5.0")
        }
    }

    // Fix: Align Kotlin JVM target with Java target for plugins that still default to 1.8
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // Fix: Inject missing namespace for older plugins that don't declare one (AGP 8+ requirement)
    afterEvaluate {
        if (project.hasProperty("android")) {
            configure<com.android.build.gradle.BaseExtension> {
                if (namespace.isNullOrEmpty()) {
                    namespace = project.group.toString()
                }
                // Older plugins pin an old compileSdk, which blocks Java 17 source
                compileSdkVersion(36)
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                lintOptions {
                    isAbortOnError = false
                    isIgnoreWarnings = true
                    isCheckReleaseBuilds = false
                    disable("MissingClass")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
