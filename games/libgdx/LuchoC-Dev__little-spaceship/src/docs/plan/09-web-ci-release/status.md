# Phase 09 — Web, CI and release · status

**State:** done — the game is live at <https://luchoc-dev.github.io/little-spaceship/>
**Updated:** 26/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

Tasks 1-3 of the plan (issue #32):

- **Task 1, web launcher.** `web/build.gradle.kts`'s `gdxTeaVM {}` block is uncommented and finished:
  `js {}` (ships) and `wasm {}` (kept available, per the decision already made — not re-decided).
  `dev.luchoc.littlespaceship.web.WebLauncher` mirrors `DesktopLauncher`: same
  `LittleSpaceshipGame`, no platform branch.
- **Task 2, canvas size and resize policy.** `WebApplicationConfiguration.width/height` are set to
  `LOGICAL_WIDTH * 2` / `LOGICAL_HEIGHT * 2` (960x540), never 0. The resize policy is: the canvas
  itself stays fixed-size, and window/browser resizing is absorbed by `PixelPerfectViewport`
  (already implemented for desktop, `BaseUiScreen`/`PlayScreen#resize`), which does the
  integer-scale letterbox math the same way on both targets. No web-specific resize code was
  needed.
- **Task 3, `startup-logo.png`.** Confirmed present in the built webapp by reading the
  `generateJavaScript` task's own log, not by assumption:
  `Copied [Classpath resource] startup-logo.png (12214 bytes)` and
  `Copied [Internal] .../assets/startup-logo.png (12214 bytes)` — it lands twice, once as the
  backend's own classpath default and once as the project's real file from `assets/`, both present
  in `web/build/dist/js/webapp/assets/`.
- Two blockers `docs/STATUS.md` handed to this phase, both resolved:
  - `tools.audio` (`GenerateAudio`, `Synth`, `Wav`) moved out of `game`'s `main` source set into a
    new `tools` source set (`game/src/tools/java`). `web` depends on `:game`, which only exposes
    `main`, so TeaVM never compiles `java.nio.file` again. `generateAudio`'s classpath now points at
    `sourceSets["tools"].runtimeClasspath`. Verified: `game.jar` (the `main` jar `web` consumes)
    contains no `tools` classes, and `:game:compileToolsJava` / `:game:generateAudio` still work.
  - `GameSkin` was checked and does **not** use `Skin(FileHandle, TextureAtlas)` or `skin.load(...)`
    — the whole skin is built in code from `Pixmap`/`NinePatch`/style objects, with only
    `new BitmapFont(FileHandle)` reading a file, which is not reflective. So the reflective `Skin`
    concern the issue flagged does not apply to this codebase; nothing needed changing here.

Verified, measured:

- `./gradlew gdx_teavm_web_js_build` — **succeeds**. Dist at `web/build/dist/js/webapp`.
- `./gradlew gdx_teavm_web_js_build -Prelease` — **succeeds**. After a clean build:
  - `app.js`: 1,026,955 bytes uncompressed, ~298 KB gzip-compressed (measured with `gzip -c | wc -c`,
    not a browser network trace, so treat as an upper bound).
  - Full `webapp/` directory (JS + assets + `index.html`): 2.5 MB, of which `assets/` alone is
    1.3 MB — mostly the two music WAVs (`level.wav` 592 KB, `boss.wav` 395 KB) and the SFX. This is
    the number `11-technical-prototype-results.md` said would change once real assets replaced the
    spike's code-generated textures: 2.5 MB vs. the spike's 192 KB compressed.
  - No load-time or in-browser framerate measurement was taken — that needs a real GPU and is task 6
    of this phase, explicitly out of scope for issue #32 (tasks 1-3 only).
- `./gradlew gdx_teavm_web_wasm_build` — **succeeds** too (kept available at no cost, per the plan).
- `./gradlew build` — **green**, including `core:test` (re-run with `--rerun` to rule out a cached
  pass).
- Did **not** attempt headless-Chrome verification — the plan and `CLAUDE.md` both say it fails
  under SwiftShader even when the real thing works, so it would have produced nothing useful.

Task 7 of the plan (issue #34), CI on GitHub Actions:

- `.github/workflows/ci.yml`, a single job on `ubuntu-latest`, triggered on every push and on pull
  requests targeting `main`.
- **Runner JDK is 17 (Temurin)**, chosen deliberately rather than matching the local dev machine's
  JDK 25: `sourceCompatibility`/`targetCompatibility` in the root `build.gradle.kts` are pinned to
  17 because TeaVM cannot digest newer bytecode, so running the whole CI build on 17 produces
  17-shaped bytecode directly instead of relying on javac's downcompile path, which was never the
  thing measured in the spike.
- Gradle wrapper (already committed) via `gradle/actions/setup-gradle@v4`, which caches both the
  wrapper distribution and the dependency/build cache — no manual `actions/cache` wiring needed.
- Two run steps: `./gradlew build` (compiles `core`, `game`, `desktop`, `web`'s JVM sources,
  assembles jars, runs `core`'s — and every other module's — test suite) and
  `./gradlew gdx_teavm_web_js_build` (the web/TeaVM target, run separately because the plugin
  registers it outside the standard `build` lifecycle task).
- `permissions: contents: read` at the workflow level — the repo is about to go public and this
  workflow never needs to write anything.
- **No headless-browser step**, per the plan's decided limitation: CI proves the web build
  compiles, not that it runs. A comment in the workflow states this explicitly next to the web
  build step so it does not get "fixed" by someone unaware of the SwiftShader failure.

Task 9 of the plan (issue #36), repository README:

- `README.md` at the repository root: what the project is, the play link
  (`https://luchoc-dev.github.io/little-spaceship/`, written ahead of the deploy per the issue —
  task 8 lands right after this one and must confirm the link resolves), controls, how to run
  desktop and web, how to build and test, a short architecture section pointing at `CLAUDE.md` and
  `docs/planning/` rather than restating them, and a status section that names known rough edges
  instead of hiding them.
- Every command in the README was actually run on this machine, not copied from memory:
  - `./gradlew build` — succeeds (cached; most tasks `FROM-CACHE`/`UP-TO-DATE`).
  - `./gradlew core:test --rerun` — forces real execution rather than a cached pass. Counted the
    JUnit XML reports directly (`tests="..."` summed across `core/build/test-results/**/*.xml`):
    **289**, matching `docs/STATUS.md`.
  - `./gradlew web:gdx_teavm_web_js_run` — builds and serves; log line
    `Jetty Dev Server started at http://localhost:8080/`, and `curl -I http://localhost:8080/`
    returned `HTTP/1.1 200 OK`. A parallel check against port 8181 (the number
    `spikes/web-viability/README.md` gives) got no response — confirms the trap `docs/STATUS.md`
    and `CLAUDE.md` already record, rather than repeating it on faith.
  - Controls were read from the actual input code, not from the functional spec alone:
    `game/src/main/java/dev/luchoc/littlespaceship/game/adapter/input/InputAdapter.java` — arrows to
    move, Space or left click to fire, X or right click for the bomb, Shift for slow movement, mouse
    deltas summed additively with the keyboard exactly as `02-mvp-functional-spec.md` describes.
  - Did not run `desktop:run` interactively (it opens an LWJGL3 window; not something this session's
    shell can usefully drive) — its command and behaviour are documented from
    `desktop/build.gradle.kts`, which is a plain `JavaExec` with no platform-specific surprises.
- **The MIT licence landed while this issue was being worked** (commit `5c5d610`, chosen by the
  player). The README points at it and states plainly that the licence covers the whole repository,
  art and audio included — which is a consequence of MIT worth knowing before the repository goes
  public.
- Tasks 4-6 and 8 are still open; they are a precondition for the play link the README already
  states to actually resolve. See "Notes for whoever comes next" below, now with task 9 removed
  from that list.

Task 8 of the plan (issue #38), deploy to GitHub Pages:

- `.github/workflows/deploy-pages.yml`, a new workflow separate from `ci.yml` (which keeps its own
  `contents: read` and was not touched). Triggers on `push` to `main` only, plus `workflow_dispatch`
  for manual runs, with its own `permissions: { pages: write, id-token: write }`. Steps: checkout,
  JDK 17 Temurin (matching `ci.yml`), `gradle/actions/setup-gradle@v4`, then
  `./gradlew clean gdx_teavm_web_js_build -Prelease` — `clean` first is deliberate, per the release
  build caching trap already recorded in this file and in agent memory — then
  `actions/configure-pages@v5`, `actions/upload-pages-artifact@v3` on
  `web/build/dist/js/webapp`, and a second `deploy` job using `actions/deploy-pages@v4`. No
  `gh-pages` branch is used; Pages is configured with `build_type: workflow` (enabled ahead of this
  issue, confirmed via `gh api repos/.../pages` returning `"build_type":"workflow"`).
- **GitHub Pages was already enabled before this issue started** (`status: null`, `build_type:
  workflow`, `html_url` matching the README's link) — the first-time-enablement step the plan warned
  about did not need doing here.
- **Verified with a real run, not by trusting the workflow file.** `workflow_dispatch` cannot fire
  until a workflow file exists on the default branch, so a genuinely-new workflow can't be manually
  dispatched from a feature branch. Worked around this by temporarily widening the `push` trigger to
  include `ci/pages-deploy` (commit `04c3343`), pushing, and reverting immediately after
  (`f698b84`) — the workflow ran for real on that push:
  - Run `32901883149`: the `build` job **succeeded in 43s** (Gradle step: `BUILD SUCCESSFUL in
    25s`), confirming `clean gdx_teavm_web_js_build -Prelease` genuinely runs on a fresh Linux
    runner and the Pages artifact uploads (`Finished uploading artifact content to blob storage!`).
  - The `deploy` job **failed**, but for an expected reason, not a bug: `Branch "ci/pages-deploy" is
    not allowed to deploy to github-pages due to environment protection rules.` Checked via
    `gh api repos/.../environments/github-pages/deployment-branch-policies`: the `github-pages`
    environment (auto-created when Pages was enabled) has exactly one allowed branch, `main`. This
    is GitHub's own protection enforcing the same rule the workflow's trigger already states, so no
    further attempt was made to bypass it from a feature branch — the deploy job will run for real
    once this PR is merged to `main`, which this session was told not to do.
  - Downloaded the uploaded Pages artifact directly (`gh api .../actions/artifacts/9583395748/zip`)
    and inspected its real contents rather than trusting the log: `assets/startup-logo.png` is
    present at 12,214 bytes, matching the size task 3 recorded. Summed every file's actual byte size
    (not `du`, which overstates a TeaVM dist by block rounding and sourcemap noise): **2,470,942
    bytes (2.36 MB) across 34 files** for the whole `webapp/` dist. `app.js` alone is 1,027,585 bytes
    uncompressed, 298,689 bytes gzip-compressed (`gzip -c app.js | wc -c`) — both numbers match the
    ones already recorded from a local build in this file, so the CI-produced release build is not
    meaningfully different from what was measured locally.
  - `curl -I https://luchoc-dev.github.io/little-spaceship/` returns `404`, as expected — the real
    `deploy` job (main-branch-only) has not run yet, so the site has nothing published. This is not a
    failure; it is the state before merge.

## In progress

Nothing. **Closed out on 26/08/2026 by phase 10a**, which found this file still saying the phase was
in progress and the play link a 404 while `docs/STATUS.md` recorded the MVP as shipped. Everything
below this heading is left as the record of the session that wrote it; what changed after it is
here.

- **Task 8, the deploy: done.** PR #38 merged, the `deploy` job ran on `main`, and the site was
  confirmed serving `200` in a real browser on 25/08/2026 — `index.html`, `app.js`,
  `startup-logo.png`, the sprite atlas and every audio file.
- **Task 4, pointer capture: shipped, and defective.** It works, and losing the lock breaks mouse
  control until the page is refocused
  ([#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41)). This is the criterion the phase
  assumed rather than verified, and the defect it would have caught is the one the player hit.
- **Task 5, the browser matrix: partly done.** Chrome and Firefox verified by hand on the live site.
  Edge dropped by the project owner's decision. Safari never checked.
- **Task 6, load time and framerate: not done.** The sub-second `curl` figures in `docs/STATUS.md`
  are all there is; a real browser's network panel is the honest instrument and nobody has used one.
  Carried in the post-MVP backlog, not here.

## Blocked

Nothing.

## Decisions taken while implementing

- **Canvas stays fixed-size on web** (960x540, 2x logical resolution) instead of an auto-sizing
  canvas that tracks the browser window. `WebApplicationConfiguration.isAutoSizeApplication()`
  (`width == 0 && height == 0`) is exactly the documented pitfall's trigger, and the container it
  would auto-size to is not something this project controls without also writing responsive CSS for
  the generated `index.html` — not worth doing since `PixelPerfectViewport` already gives correct
  integer-scale letterboxing for whatever size the canvas actually is. This is a presentation
  choice, not a game rule, so it does not touch `docs/planning/08-decisions-and-open-items.md`.
- **`tools` source set**, not a separate Gradle module, for `tools.audio`. It has zero dependency on
  the rest of `game` (confirmed by reading its imports), so a source set inside the same module was
  enough to keep it out of `web`'s classpath without the overhead of a new subproject.

## Notes for whoever comes next

*The two entries that follow described the state before PR #38 merged. Both are resolved; see
"In progress" above for what actually happened. They are kept because the second one is a good
instruction and someone should follow it again the next time a deploy changes.*

- ~~Tasks 4-6 remain: pointer capture verification, the browser matrix
  (Chrome/Firefox/Edge/Safari), and real-asset load-time and framerate measurement.~~ Task 7 (CI) is
  done as of issue #34, task 9 (README) as of issue #36, task 8 (deploy) as of issue #38.
- ~~**The README's play link is written and the workflow that will make it live exists
  (`.github/workflows/deploy-pages.yml`, PR #38), but the link itself is still a 404 as of this
  writing**~~ — the `deploy` job is correctly gated to `main` only (both by its own trigger and by
  GitHub's `github-pages` environment protection, which only allows `main`), and this session did
  not merge. Whoever merges PR #38 should watch the workflow run on `main` and open the link in a
  real browser before telling anyone it works, not just trust that the job went green. **This was
  done on 25/08 and the link resolves.**
- `.github/workflows/ci.yml` proves the build compiles and the tests pass. It cannot prove the web
  build *runs*; a human does that, in a real browser, every time.
- **It has run on real GitHub Actions runners, and all three acceptance criteria were checked
  against real runs rather than reasoned about.** The workflow triggers on `push`, so it ran itself
  the moment the branch was pushed:
  - The first two runs **failed in ~15 s** with `./gradlew: Permission denied` (exit 126).
    `gradlew` had been committed from Windows, where the executable bit does not exist, so git
    recorded mode `100644` and the Linux runner could not execute it. Fixed with
    `git update-index --chmod=+x gradlew` (commit `8542034`). **This is the first time this
    repository ever touched a Linux runner, which is why it had never surfaced.**
  - After the fix, runs `32897588973` (push) and `32897594158` (pull_request) both **succeeded in
    ~1 m 25 s**, with `:core:test`, `:desktop:compileJava/:jar/:assemble/:build` and
    `:web:generateJavaScript` all genuinely executing.
  - **CI goes red on a failing test — demonstrated, not assumed.** A deliberate failing test was
    pushed on a throwaway branch: `290 tests completed, 1 failed`, `Task :core:test FAILED`,
    `BUILD FAILED`, run red. The branch was then deleted. Worth knowing that the criterion was
    proved by experiment, because a CI that passes unconditionally looks identical to a working one.
- Local verification, for the record: the same command sequence passes on the development machine
  under JDK 21, not the JDK 17 the workflow pins — that machine has no JDK 17. The runner has now
  covered JDK 17 for real.
- A human needs to open `web/build/dist/js/webapp/index.html` through a real local server (not
  `file://`, module loading needs HTTP) in a real browser to confirm the game actually runs, the
  pointer-lock relative mouse works, and audio unlocks on the first click. `./gradlew
  gdx_teavm_web_js_run` serves it on `http://localhost:8080`.
- The measured 2.5 MB / ~298 KB gzip `app.js` numbers are from this machine's build only; re-measure
  once task 6 is actually picked up, ideally with a real browser's network panel rather than
  `gzip -c | wc -c`, since HTTP compression and caching headers change what a visitor actually
  downloads.
