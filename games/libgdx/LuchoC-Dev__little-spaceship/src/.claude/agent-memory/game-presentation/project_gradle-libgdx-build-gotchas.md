---
name: gradle-libgdx-build-gotchas
description: Gradle/libGDX/TeaVM build quirks found wiring desktop and web launchers in phase 03, not covered by CLAUDE.md or the planning docs
metadata:
  type: project
---

Found assembling `desktop` and `web` from the still-empty module skeletons phase 01 left behind. None of this is in `docs/`; it is Gradle/libGDX mechanics, not project decisions.

**`desktop`/`web` need their own `JavaExec`-style `run` task; libGDX's `application` plugin is not applied by the project skeleton.** `./gradlew :desktop:run` does nothing useful without one. The spike (`spikes/web-viability/desktop/build.gradle.kts`) already has the working pattern: register a `run` task with `mainClass`, `classpath = sourceSets["main"].runtimeClasspath`, and — this is the part easy to skip — `workingDir = rootProject.file("assets")`, so `Gdx.files.internal(...)` resolves paths the same way it will once real content exists. Copied verbatim into `desktop/build.gradle.kts`.

**The `gdxTeaVM {}` block and its `OptimizationLevel`/`SourceFilePolicy` imports must sit above the `plugins {}` block in `web/build.gradle.kts`, not below it as originally commented.** Kotlin script rules require `plugins {}` near the very top, but the imports these types need also have to resolve before that block in practice; moving them above (comments only allowed before `plugins {}` otherwise) is what let `./gradlew :web:gdx_teavm_web_js_build` succeed. Worth re-checking if a future gdx-teavm plugin upgrade changes this.

**A `TextureRegion` sub-area cannot use `Texture.TextureWrap.Repeat` for tiling without bleeding into neighbouring regions of the same atlas.** `Repeat` wraps the whole underlying `Texture`, not the region's sub-rectangle — so a checkerboard/background tile that needs to repeat has to live on its own dedicated `Texture`, separate from any atlas holding discrete sprites like the ship. Found this before it became a bug: `CheckerboardBackground` is deliberately its own class/texture, not part of `PlaceholderAtlas`.

**`./gradlew :desktop:run` in this sandboxed shell opens a real LWJGL3 window with no visible display attached.** It doesn't crash — stdout shows the usual LWJGL/JNI warnings and then nothing else — but there is no way to confirm what actually rendered without a human watching the window. Killing it with `timeout` (exit code 124) after 10-15s and checking for the absence of a stack trace is the best signal available from this kind of session; it is not equivalent to visual confirmation and should not be reported as one.

**Phase 03 built and verified this whole web setup once, then reverted the `web` module's sources on explicit direction** (the plan's task list said "Desktop only," a stale comment had claimed otherwise). The `gdxTeaVM` block in `web/build.gradle.kts` is commented out again, but the notes above are still current: `./gradlew :web:gdx_teavm_web_js_build` succeeded against this project's actual module layout (not just the spike's) and confirmed `assets/startup-logo.png` gets copied into `web/build/dist/js/webapp/assets`. Phase 09 does not need to rediscover any of this — uncommenting the block and re-adding a `WebLauncher` mirroring `game/LittleSpaceshipGame.java`'s constructor is the whole job.

See [[core-boundary-check]] for the companion check on the `game` side of this same phase.
