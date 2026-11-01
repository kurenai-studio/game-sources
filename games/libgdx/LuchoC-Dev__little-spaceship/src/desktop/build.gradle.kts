// LWJGL3 launcher.
val gdxVersion: String by rootProject.extra

dependencies {
    implementation(project(":game"))
    implementation("com.badlogicgames.gdx:gdx:$gdxVersion")
    implementation("com.badlogicgames.gdx:gdx-backend-lwjgl3:$gdxVersion")
    implementation("com.badlogicgames.gdx:gdx-platform:$gdxVersion:natives-desktop")
}

tasks.register<JavaExec>("run") {
    group = "application"
    description = "Runs the game on desktop"
    mainClass.set("dev.luchoc.littlespaceship.desktop.DesktopLauncher")
    classpath = sourceSets["main"].runtimeClasspath
    // Assets are resolved relative to the working directory at runtime, not bundled into the
    // classpath, the same way spikes/web-viability does it.
    workingDir = rootProject.file("assets")
}
