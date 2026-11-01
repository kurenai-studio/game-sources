# Phase 09 — Web, CI and release

**Lane:** code · **Owner:** `game-presentation` · **Depends on:** 07 · **Target:** day 7

## Before you start

**Read, in this order:**

1. `docs/planning/11-technical-prototype-results.md` — the whole document. It is the record of what was measured and what broke.
2. `CLAUDE.md` — the web-target pitfalls, every one of which cost hours to find.
3. `spikes/web-viability/README.md` — the exact commands that produce a web build.

**Do not re-decide:** JavaScript ships and Wasm stays available at no cost. The reasons are size and the fact that source maps and IDE debugging only exist for the JS target.

**Known limitation:** CI cannot validate that the web build *runs*. Headless Chrome fails under SwiftShader even when a real browser works. CI proves it compiles; a human proves it runs.

## Goal

Turn the game into a link someone can open. This is the phase that makes the whole platform decision pay off.

## Preconditions

The game complete and playable on desktop.

## Tasks

1. **Web launcher** with the gdx-teavm plugin, JavaScript target. Wasm stays available at no cost but JavaScript ships: it is smaller and it is the only target with source maps and IntelliJ debugging.
2. **Explicit canvas size**, and a resize policy for the browser window.
3. **Verify `assets/startup-logo.png`** is in the build. Without it the app crashes when preloading ends.
4. **Verify pointer capture** for the relative mouse. Still unverified, and it affects a decided control rule.
5. **Browser matrix**: Chrome, Firefox and Edge, plus Safari as far as it can be checked from Windows.
6. **Measure the real build**: size, load time and framerate with the actual art, which the spike could not do because it generated its textures in code.
7. **CI** on GitHub Actions: compile, run `core` tests, build the desktop and web targets.
8. **Deploy** as a static site.
9. **Repository README** with what the project is, how to run it, and the link to play.

## Acceptance criteria

- A stranger opens the link and plays without installing anything.
- Level 1 is completable in the browser.
- Keyboard and mouse behave as they do on desktop.
- Audio plays after the first user gesture.
- Load time and download size are measured and recorded.
- CI runs on every push and fails when tests fail.
- The deployment is reproducible from a clean clone.

## Risks

**CI cannot validate the web runtime.** Headless Chrome fails under SwiftShader even when a real browser works. CI can only prove the build compiles; that it *runs* is verified by hand, every time.

**The real assets change the measurements.** The spike measured 192 KB compressed with code-generated textures. With actual art and audio the download will be substantially larger, and that number matters for a portfolio piece where the visitor waits or leaves.

**Leaving web for the last day is a bet.** It was validated in the spike, so the risk is smaller than it looks — but every pitfall in `CLAUDE.md` was found the hard way, and each one cost hours.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
