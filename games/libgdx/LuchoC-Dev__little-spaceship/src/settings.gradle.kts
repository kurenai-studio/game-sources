// Plugin resolution needs mavenCentral(): the gdx-teavm plugin is published
// there, not only on the Gradle Plugin Portal.
pluginManagement {
    repositories {
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

rootProject.name = "little-spaceship"

include("core")
include("game")
include("desktop")
include("web")
include("rngparity")
