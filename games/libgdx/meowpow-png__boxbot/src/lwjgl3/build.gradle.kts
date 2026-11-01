import org.gradle.internal.os.OperatingSystem
import org.gradle.jvm.toolchain.JavaLanguageVersion

plugins {
    application
    jacoco
    alias(libs.plugins.shadow)
}

application {
    mainClass.set("dev.meowpow.boxbot.lwjgl3.Lwjgl3Launcher")
}

sourceSets.main {
    resources.srcDir(rootProject.file("assets"))
    resources.exclude("sprites/**", "**/*.xcf", "*.tiled-project", "*.tiled-session", "fonts/OFL.txt")
}

dependencies {
    implementation(project(":core"))
    runtimeOnly(libs.logback.classic)
    compileOnly(libs.jspecify)
    implementation(libs.gdx.backend.lwjgl3)
    implementation(variantOf(libs.gdx.platform) { classifier("natives-desktop") })
    implementation(variantOf(libs.gdx.freetype.platform) { classifier("natives-desktop") })
}

tasks.named("processResources") {
    dependsOn(rootProject.tasks.named("packTextures"))
}

tasks.named<JavaExec>("run") {
    dependsOn(rootProject.tasks.named("packTextures"))
    classpath = files(rootProject.file("assets")) + classpath

    val devMode = System.getProperty("boxbot.dev") ?: System.getenv("BOXBOT_DEV")
    devMode?.let { systemProperty("boxbot.dev", it) }

    val trueFullscreen = System.getProperty("boxbot.trueFullscreen") ?: System.getenv("BOXBOT_TRUE_FULLSCREEN")
    trueFullscreen?.let { systemProperty("boxbot.trueFullscreen", it) }
}

tasks.register<JavaExec>("runRobotAnimationTest") {
    group = "verification"
    description = "Plays the robot's animation clips"

    dependsOn(rootProject.tasks.named("packTextures"))
    classpath = files(rootProject.file("assets")) + sourceSets.main.get().runtimeClasspath
    mainClass.set("dev.meowpow.boxbot.lwjgl3.RobotAnimationTest")
}

tasks.shadowJar {
    archiveBaseName.set("boxbot")
    archiveClassifier.set("")
    // Union ServiceLoader files across jars instead of keeping one copy. INCLUDE is required
    // here: without it duplicates are dropped before mergeServiceFiles() runs. Scoped to just
    // these files so unrelated duplicates (e.g. LWJGL's per-native .sha1 sidecars) still dedupe.
    filesMatching("META-INF/services/**") {
        duplicatesStrategy = DuplicatesStrategy.INCLUDE
    }
    mergeServiceFiles()

    // gdx-platform's natives-desktop bundles every OS's natives in one jar.
    // Each package only runs on OS it was built for, so drop other binaries to shrink it.
    if (!OperatingSystem.current().isWindows) {
        exclude("**/*.dll*")
    }
    if (!OperatingSystem.current().isLinux) {
        exclude("**/*.so*")
    }
    exclude("**/*.dylib*")
}

// jpackage bundles the host JRE, so it can't cross-target
// run this task on Windows for .msi and separately on Linux for the .deb
// jpackage requires a strictly numeric version, so drop any "-rc.N" suffix.
val jpackageAppVersion = provider { project.version.toString().substringBefore("-") }

val jpackageExecutable = javaToolchains.launcherFor {
    languageVersion.set(JavaLanguageVersion.of(21))
}.map { launcher ->
    val binName = if (OperatingSystem.current().isWindows) "jpackage.exe" else "jpackage"
    launcher.metadata.installationPath.file("bin/$binName").asFile.absolutePath
}

val jpackageImageDir = layout.buildDirectory.dir("jpackage/image")
val jpackageDistDir = layout.buildDirectory.dir("jpackage/dist")

// jpackage wants a platform-native icon format: .ico (multi-res) on Windows, .png on Linux.
// Falls back to jpackage's default icon if the file isn't there yet, rather than failing the build.
val jpackageIconFile = if (OperatingSystem.current().isWindows) {
    rootProject.file("packaging/windows/boxbot.ico")
} else {
    rootProject.file("packaging/linux/boxbot.png")
}
val jpackageIconArgs = if (jpackageIconFile.exists()) listOf("--icon", jpackageIconFile.path) else emptyList()

val jpackageAppImage = tasks.register<Exec>("jpackageAppImage") {
    group = "distribution"
    description = "Assembles an unpacked runnable app image for the current OS"

    dependsOn(tasks.shadowJar)
    inputs.file(tasks.shadowJar.flatMap { it.archiveFile })
    if (jpackageIconFile.exists()) inputs.file(jpackageIconFile)
    outputs.dir(jpackageImageDir)

    val imageDir = jpackageImageDir.get().asFile
    doFirst {
        imageDir.apply {
            deleteRecursively()
            mkdirs()
        }
    }
    commandLine(
        listOf(
            jpackageExecutable.get(),
            "--type", "app-image",
            "--input", tasks.shadowJar.flatMap { it.archiveFile }.get().asFile.parent,
            "--main-jar", tasks.shadowJar.flatMap { it.archiveFileName }.get(),
            "--main-class", "dev.meowpow.boxbot.lwjgl3.Lwjgl3Launcher",
            "--name", "Boxbot",
            "--app-version", jpackageAppVersion.get(),
            "--vendor", "meowpow",
            "--dest", imageDir.path,
        ) + jpackageIconArgs
    )
}

val jpackageInstaller = tasks.register<Exec>("jpackageInstaller") {
    group = "distribution"
    description = "Packages the app image into native installer for the current OS"

    dependsOn(jpackageAppImage)
    outputs.dir(jpackageDistDir)

    val distDir = jpackageDistDir.get().asFile
    doFirst {
        distDir.mkdirs()
    }
    val installerType = when {
        OperatingSystem.current().isWindows -> "msi"
        OperatingSystem.current().isLinux -> "deb"
        else -> throw GradleException(
            "No jpackage installer type configured for ${OperatingSystem.current()}"
        )
    }
    commandLine(
        listOf(
            jpackageExecutable.get(),
            "--type", installerType,
            "--app-image", jpackageImageDir.get().asFile.resolve("Boxbot").path,
            "--name", "Boxbot",
            "--app-version", jpackageAppVersion.get(),
            "--vendor", "meowpow",
            "--dest", distDir.path,
        ) + jpackageIconArgs
    )
}
