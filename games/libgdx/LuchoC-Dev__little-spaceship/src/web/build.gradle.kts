// TeaVM launcher. Owned by phase 09 (docs/plan/09-web-ci-release/plan.md), which brings the web
// target back deliberately. Phase 03 built and verified this block once, then reverted it on
// explicit direction: its own task list says "Desktop only," and this comment previously claiming
// otherwise is what led phase 03 to build WebLauncher anyway — do not repeat that mistake by
// trusting a comment over the plan it sits next to.
import org.teavm.gradle.api.OptimizationLevel
import org.teavm.gradle.api.SourceFilePolicy

val gdxVersion: String by rootProject.extra

plugins {
    id("com.github.xpenatan.gdx-teavm") version "1.6.1"
}

dependencies {
    implementation(project(":game"))
    implementation("com.badlogicgames.gdx:gdx:$gdxVersion")
}

// The plugin adds backend-web on its own once a js {} or wasm {} target is
// declared, so it is never listed as a dependency by hand.
//
// The 1.6.1 plugin has no named targets, so release mode is selected with -Prelease.
val release = providers.gradleProperty("release").isPresent

gdxTeaVM {
    assets.from(rootProject.file("assets"))

    // JavaScript ships: it is smaller and it is the only target with source maps and IntelliJ
    // debugging, per docs/planning/11-technical-prototype-results.md. Decided, not re-decided here.
    js {
        mainClass.set("dev.luchoc.littlespaceship.web.WebLauncher")
        htmlTitle.set("little-spaceship")
        optimization.set(if (release) OptimizationLevel.AGGRESSIVE else OptimizationLevel.NONE)
        obfuscated.set(release)
        debugInformation.set(!release)
        sourceMap.set(!release)
        if (!release) {
            sourceFilePolicy.set(SourceFilePolicy.COPY)
        }
    }

    // Wasm stays available at no cost — the same project generates both targets — even though it
    // is not the one that ships.
    wasm {
        mainClass.set("dev.luchoc.littlespaceship.web.WebLauncher")
        htmlTitle.set("little-spaceship")
        optimization.set(if (release) OptimizationLevel.AGGRESSIVE else OptimizationLevel.NONE)
        obfuscated.set(release)
        debugInformation.set(!release)
    }
}
