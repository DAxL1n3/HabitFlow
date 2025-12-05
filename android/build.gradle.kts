// --- ESTO VA AL PRINCIPIO ---
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Aquí registramos las herramientas de construcción
        classpath("com.android.tools.build:gradle:8.2.1") // (O la versión que ya tuvieras, si no, deja esta)
        classpath("com.google.gms:google-services:4.4.2") // <--- ESTA ES LA QUE IMPORTA
    }
}

// --- EL RESTO DE TU CÓDIGO SE QUEDA IGUAL ---
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}