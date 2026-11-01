// Presentation layer: libGDX lives here, never in core.
// Sources arrive in phase 03, owned by the game-presentation agent.
val gdxVersion: String by rootProject.extra

dependencies {
    implementation(project(":core"))
    implementation("com.badlogicgames.gdx:gdx:$gdxVersion")
}

// `tools.audio` (GenerateAudio, Synth, Wav) is a design-time generator: it uses java.nio.file,
// which does not exist on TeaVM. It used to sit under `main` and was harmless only while `web`'s
// gdxTeaVM {} block stayed commented out — TeaVM compiles every class reachable from `main`, so
// it would have broken the moment the web build ran, even though nothing in the game ever calls
// it at runtime. It lives in its own source set so `web`'s dependency on `:game` (which pulls in
// only the `main` sourceSet) never sees it.
sourceSets {
    create("tools") {
        java.srcDir("src/tools/java")
    }
}

// The `-Ptests` build flavour (phase 11h, issue #244): a fourth main-menu entry, TESTS, that
// starts the game straight into a named scenario instead of level-01. `-Prelease` in
// `web/build.gradle.kts` is a flavour switch that only changes *how* the same code is compiled;
// this one changes *which source files exist in the build at all*, because the acceptance
// criterion is that the ordinary build never contains the test-mode screens, not merely that it
// hides them behind a runtime check. A boolean read at runtime would still ship TestMenuScreen
// into the web bundle every time `:game`'s `main` sourceSet is compiled.
//
// `dev.luchoc.littlespaceship.game.screen.TestMode` therefore exists as two mutually exclusive
// files that are never both compiled: `src/teststub/java`'s no-op (added when `-Ptests` is
// absent) and `src/tests/java`'s real implementation, which also holds `TestMenuScreen` and
// `TestScenarios` (added only when `-Ptests` is present). `MenuScreen` calls
// `TestMode.addMenuEntry(...)` unconditionally either way, so it needs no flavour-aware code of
// its own.
val testsFlavour = providers.gradleProperty("tests").isPresent

sourceSets {
    main {
        if (testsFlavour) {
            java.srcDir("src/tests/java")
        } else {
            java.srcDir("src/teststub/java")
        }
    }
    // TestScenariosTest (issue #311) exercises TestScenarios directly, so it can only compile
    // once TestScenarios itself is on the main sourceSet above — added only under the same
    // property, in its own directory rather than ordinary `src/test/java`, so `./gradlew :game:test`
    // without `-Ptests` never even tries to compile a reference to a class that does not exist yet.
    if (testsFlavour) {
        test {
            java.srcDir("src/testsTest/java")
        }
    }
}

// Design-time only: regenerates the procedural WAV assets under assets/audio. Never part of
// `build` or `test` — see GenerateAudio's own javadoc for why the output is committed instead.
tasks.register<JavaExec>("generateAudio") {
    group = "content"
    description = "Regenerates the procedural sound effects and music loops under assets/audio."
    mainClass.set("dev.luchoc.littlespaceship.game.tools.audio.GenerateAudio")
    classpath = sourceSets["tools"].runtimeClasspath
    args = listOf(rootProject.file("assets/audio").absolutePath)
}
