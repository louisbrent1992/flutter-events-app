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
    
    // Fix: Inject missing namespace for older plugins that don't declare one (AGP 8+ requirement)
    afterEvaluate {
        if (project.hasProperty("android")) {
            configure<com.android.build.gradle.BaseExtension> {
                if (namespace.isNullOrEmpty()) {
                    namespace = project.group.toString()
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
