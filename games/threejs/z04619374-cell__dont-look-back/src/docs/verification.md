# Verification — 2026-10-15

## Source and rule tests

- `node --test tests/model.test.mjs`: 10 passed, 0 failed.
- `node --test tests/server.test.mjs`: 1 passed, 0 failed, with native permission for localhost. Confirms game HTML/modules return 200, missing files 404, directory escape 403.
- `node scripts/check.mjs`: syntax check of project JavaScript modules.
- Independent read-only review: no material gameplay issues reported.

Rules exercised: neglect decay and failure; tap recovery/cooldown and resistible turn; held A inevitability despite opposing look input; forced latch survives release; repeated keydown cannot refresh guard; rear-view dwell; paused time/input clearing; 3-point damage with forward-facing guard; contact/distance frame-rate invariance; 90-second win and fresh retry state.

## Browser

The flow under test was: actual app load → start → held A failure → retry → tap → pause/resume → settings → neglect B failure → narrow screen desktop requirement.

Playwright drove the installed Chrome in headless mode with software WebGL, at 1440×900 and 390×844. No game-state test hooks or synthetic direct state edits. Actual button clicks and keyboard down/up exercised the app. Browser console errors: none. Page title and nonzero WebGL canvas verified. Screenshots visually inspected for meaningful split views, avatar/hands, legible UI, and failure reason.

The built-in Browser/IAB localhost route failed with ERR_CONNECTION_TIMED_OUT and ERR_BLOCKED_BY_CLIENT. The documented frontend-builder fallback was used; no extra browser download was needed. Screenshots and one-off QA script live outside the repository.

## Scope and limits

- No art assets, external font loads, textures, model files or prerecorded audio. All scene geometry is whitebox.
- Desktop mouse and keyboard only. Narrow/coarse-pointer devices show a requirement message.
- Pointer lock fallback exists; normal pointer lock succeeded in tested Chrome. Embedded/private hosting permission may differ; fallback is explicitly explained on screen.
- Full 90-second win was exercised by deterministic simulation, not a complete human playthrough.
- Chromium tested; Firefox/Safari and physical audio output not separately tested. Balance and motion comfort still need user playtesting.
- Open-source ZIP omits local `.openai` Site identity and credentials. No public GitHub repository has been created; source is ready to upload to the user's chosen repository.

## Vendored dependency SHA-256

Three.js pinned to 0.180.0 (r180), MIT license retained.

| File | SHA-256 |
|---|---|
| three.module.min.js | e2b5ee6bccd38fd6d8a2428546b83c5f2426d84b152ef82be8055556e3b40eb6 |
| three.core.min.js | 61ba0df005b05991361d040d8ff670e1aadfd0ce7aeebd1fdb0725957a8957de |
| PointerLockControls.js | aad3f59b92727fc9741b8e4ccdc9d2290bb5ca05562baaa3eff78d1dd92b18b7 |

## English UI and shoulder-tap voice update

- All visible interface labels, dialogs, accessibility labels, and errors are English; long instructions removed.
- Bundled Microsoft Zira Desktop female synthesized “Hey!” (`dist/assets/hey.wav`), decoded duration 1.034 seconds. No runtime speech service required.
- Chrome real-input test verified a tap starts one non-silent voice buffer, immediate repeated click does not replay it, and mute prevents playback.
- Chrome visual/interaction checks passed: start, held-A failure, retry/tap, pause timer freeze, settings, neglected-B failure, and narrow-device message; no console errors.
- 11 automated model/server tests passed. Physical speaker output has not been separately auditioned.
