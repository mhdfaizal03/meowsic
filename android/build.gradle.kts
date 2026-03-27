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
    val project = this
    
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Robust Namespace & Compatibility enforcement
    afterEvaluate {
        try {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                if (namespace == null) {
                    // Try to extract from manifest to avoid AGP 8+ conflicts
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestXml = manifestFile.readText()
                        val packageMatch = Regex("package\\s*=\\s*[\"']([^\"']+)[\"']").find(manifestXml)
                        if (packageMatch != null) {
                            namespace = packageMatch.groupValues[1]
                        }
                    }
                    
                    if (namespace == null) {
                        namespace = "com.meowsic.${project.name.replace("-", ".")}"
                    }
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        } catch (e: Exception) {
            // Finalization safe
        }
    }
}

// Global JVM Target Enforcement (The Hammer)
allprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // Avoid options.release as it conflicts with AGP bootclasspath
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
