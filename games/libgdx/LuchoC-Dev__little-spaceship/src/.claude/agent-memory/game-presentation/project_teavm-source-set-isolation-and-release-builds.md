---
name: teavm-source-set-isolation-and-release-builds
description: Isolating a JDK-only tool class from TeaVM via a Gradle source set, and a caching trap when switching gdxTeaVM's -Prelease on and off
metadata:
  type: project
---

Learned bringing the web target back in phase 09 (issue #32, PR #33), worked from a separate
worktree (`little-spaceship-web-launcher`, not the `navecita-v5` checkout this memory file lives
in — the agent-memory path is fixed regardless of which worktree the work happens in).

**Isolating `tools.audio` from TeaVM: a same-module source set was enough, no new subproject
needed.** `game`'s `main` source set is what `web` pulls in via `implementation(project(":game"))`,
and TeaVM compiles everything reachable from whatever classpath the plugin is given — so a
JDK-only helper class sitting in `main` gets compiled by TeaVM even if nothing in the actual game
ever calls it. Moving `GenerateAudio`/`Synth`/`Wav` to `game/src/tools/java` with a
`sourceSets { create("tools") { java.srcDir("src/tools/java") } }` block, and pointing the
`generateAudio` Gradle task's classpath at `sourceSets["tools"].runtimeClasspath`, kept them
compiling and runnable via `./gradlew :game:generateAudio` while being invisible to `:game:jar`
(verified with `unzip -l game/build/libs/game.jar | grep tools` returning nothing) and therefore
invisible to `web`. No new Gradle subproject was needed since the tool has zero dependency on the
rest of `game` — check for that dependency-freeness before assuming a source set is enough; a tool
that *does* need something from `main` can't be isolated this way without moving that shared code
too.

**`gdx_teavm_web_js_build -Prelease` after a prior non-release build can silently reuse a stale
`generateJavaScript` output.** Running the JS build once, then again with `-Prelease` added, showed
`> Task :web:generateJavaScript` as `UP-TO-DATE`/not re-executed in the task summary even though
release mode changes `obfuscated`/`debugInformation`/`optimization`. The `app.js` file's timestamp
did update but a stale `app.js.map` from the earlier non-release run was left sitting next to it
(release mode sets `sourceMap.set(false)`, so nothing should have regenerated or removed it).
**Always `./gradlew clean` before measuring a release build's real output** — don't trust an
incremental build's dist directory for size/content measurements after a mode switch.

**`WebApplicationConfiguration.width/height` has three meaningful states, not two:** `-1` means
"use the actual HTML canvas element's size" (whatever it is at construction), `0`/`0` together
means "auto-size to the container" (the documented 0x0-at-startup trap from
`11-technical-prototype-results.md`), and any other pair is a genuinely fixed canvas size. Picking
a fixed non-zero size sidesteps the trap entirely without needing to reason about container CSS at
all — `isFixedSizeApplication()`/`isAutoSizeApplication()` in the class itself are the two-line
proof of which mode a given config is in, worth reading directly from the `backend-web` sources
jar rather than guessing from the field's one-line doc comment.

The `js {}` and `wasm {}` blocks both worked on the first attempt with the same
`mainClass`/`htmlTitle` values — no platform divergence needed even at the Gradle level, matching
what `12-architecture.md` already claimed for the Java side.
