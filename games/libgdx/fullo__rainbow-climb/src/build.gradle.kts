buildscript {
    val kotlinVersion: String by project
    val androidPluginVersion: String by project

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:$androidPluginVersion")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://oss.sonatype.org/content/repositories/snapshots/")
    }
}
