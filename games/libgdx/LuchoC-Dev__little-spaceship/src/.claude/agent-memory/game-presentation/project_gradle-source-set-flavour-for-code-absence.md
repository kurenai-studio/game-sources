---
name: gradle-source-set-flavour-for-code-absence
description: how #244's -Ptests flavour keeps test-mode screens genuinely absent from the shipped jar, not just unreachable at runtime, and why sourceSets.exclude doesn't work for the swap
metadata:
  type: project
---

Phase 11h, issue #244: a `-Ptests` Gradle property needed to make a class's compiled bytecode
literally not exist in the ordinary build, not merely unreached at runtime — because `:web`'s
TeaVM compile walks everything reachable from `main`, so a runtime `if` still ships the dead code
into `app.js`.

**Pattern that worked:** two mutually exclusive source directories defining the *same* class
(`TestMode`, package-private, one static method). `game/build.gradle.kts` adds exactly one of them
to the `main` source set depending on `providers.gradleProperty("tests").isPresent`:
`src/teststub/java` (no-op body) when absent, `src/tests/java` (the real implementation, plus
whatever else the flavour needs — here `TestMenuScreen`, `TestScenarios`) when present. The
always-compiled caller (`MenuScreen`) calls the method unconditionally and needs zero flavour-aware
code of its own.

**Why not `sourceSets.main.java.exclude("**/screen/TestMode.java")` toggled by the property, with
one real `TestMode.java` sitting under ordinary `src/main/java`:** `SourceDirectorySet.exclude`
patterns apply to the *whole merged tree* across every srcDir in the set, not per-directory. Adding
the real `TestMode.java` from another srcDir at the same relative path
(`dev/luchoc/littlespaceship/game/screen/TestMode.java`) and then excluding that same pattern to
hide the *other* copy excludes both. Two independent directories, only one of which is ever added,
sidesteps this — no `exclude()` call needed at all.

**Verifying absence, not asserting it:** `find game/build/classes/java/main -iname "TestMenu*"`
after a `clean` compile without the property (empty output) and with it (three `.class` files)
proved the source-set toggle actually changes what's compiled — a diff-reading claim would not
have caught a mistake here. `unzip -l game/build/libs/game.jar | grep -i test` on the *jar* (not
just the classes dir) is the check that actually matches what `:desktop` and `:web` depend on —
only the stub `TestMode.class` showed up, confirming the real classes never enter the artifact
consumed downstream.

**Project properties from `-Pname` are build-wide, not task-scoped.** `./gradlew :desktop:run
-Ptests` still makes `providers.gradleProperty("tests")` visible inside `game/build.gradle.kts`'s
own script body, because Gradle evaluates every project's build script before executing any task,
and an unscoped `-P` flag applies to the whole build session — same mechanism `web/build.gradle.kts`
already relies on for `-Prelease`. Confirmed by observing the source-set change take effect when
invoking a `:game`-only task with the property (`./gradlew :game:compileJava -Ptests`).
