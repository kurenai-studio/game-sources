import org.teavm.gradle.api.JSModuleType
import org.teavm.gradle.api.OptimizationLevel

// Verifies that the real dev.luchoc.littlespaceship.core.domain.rng.Rng — not a copy — reproduces
// the same pinned sequences on the JVM and on TeaVM/JavaScript. Handover from phase 10a, decision D1
// in docs/plan/10a-honest-documentation/decisions.md, resolved in phase 11a (#52).
//
// This subproject exists only because :core must never see a TeaVM toolchain (invariant 1,
// core/build.gradle.kts). Precedent: game/src/tools/java moved tools/audio into its own source set
// for the same reason. It applies the TeaVM plugin directly rather than the gdx-teavm wrapper :web
// uses, because there is no libGDX involved — the version below matches the one already verified in
// spikes/web-viability/rngcheck.
//
// On demand only, never per push — see RngTest's javadoc:
//   ./gradlew :rngparity:rngParityCheck
plugins {
    id("org.teavm") version "0.15.0"
}

dependencies {
    implementation(project(":core"))
}

teavm {
    js {
        mainClass.set("dev.luchoc.littlespaceship.rngparity.Main")
        obfuscated.set(false)
        optimization.set(OptimizationLevel.AGGRESSIVE)
        moduleType.set(JSModuleType.COMMON_JS)
        targetFileName.set("rngparity.js")
        // No web app to add this to — this module only ever runs on Node for the parity check.
        addedToWebApp.set(false)
    }
}

val runOnJvm = tasks.register<JavaExec>("runOnJvm") {
    group = "verification"
    description = "Runs the real Rng on the JVM and checks it against the pinned sequences."
    mainClass.set("dev.luchoc.littlespaceship.rngparity.Main")
    classpath = sourceSets["main"].runtimeClasspath
}

val runOnNode = tasks.register<Exec>("runOnNode") {
    group = "verification"
    description = "Runs the real Rng through TeaVM/JavaScript on Node and checks it against the pinned sequences."
    dependsOn("generateJavaScript")
    // run.cjs (committed, not generated) requires the TeaVM output by its build-relative path, so
    // it runs from the project directory rather than from build/generated/teavm/js.
    workingDir = projectDir
    commandLine("node", "run.cjs")
}

// Deliberately not wired into `check` or `build`: #52 point 3 keeps this out of the per-push CI
// job, since a TeaVM compile plus a Node run costs real minutes for something only the algorithm's
// author needs to run, and only when touching it.
tasks.register("rngParityCheck") {
    group = "verification"
    description = "Runs the real Rng on the JVM and on TeaVM/Node and checks both reproduce the pinned sequences RngTest asserts."
    dependsOn(runOnJvm, runOnNode)
}
