// android/build.gradle.kts (project-level)

// Keep your repositories so Gradle can fetch AndroidX artifacts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect Gradle build output to a top-level build folder (your original setup)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Keep your existing evaluation dependency behavior
subprojects {
    project.evaluationDependsOn(":app")
}

// -------------------------
// Ensure camera plugin modules (and other plugin modules) have the needed androidx class
// Force-add androidx.concurrent:concurrent-futures to all subprojects' implementation configuration.
// This helps when a plugin (like camera_android_camerax) needs CallbackToFutureAdapter at compile time.
subprojects {
    // afterEvaluate ensures each project has been configured before we attempt to add dependencies
    afterEvaluate {
        try {
            // Kotlin DSL style to add dependency
            dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.1.0")
        } catch (e: Throwable) {
            // ignore modules that don't accept this dependency configuration
        }
    }
}
// -------------------------

// Keep your clean task pointing at the consolidated build folder
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
