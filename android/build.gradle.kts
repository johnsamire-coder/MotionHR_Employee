allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// إجبار كل الـ plugins تستخدم compileSdk 36 و NDK 28
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (e: Exception) {}
                try {
                    val setNdk = androidExt.javaClass.getMethod("setNdkVersion", String::class.java)
                    setNdk.invoke(androidExt, "28.2.13676358")
                } catch (e: Exception) {}
            }
        }
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}