---
name: pointer-lock-loss-detection
description: how to detect the browser revoking Pointer Lock behind the game's back, and why pausing was chosen over a fallback or a resume prompt
metadata:
  type: project
---

`Gdx.input.setCursorCatched(true)` and a self-set boolean flag are not enough to know the pointer
is still captured. The browser (and the desktop backend on focus loss) can revoke the lock without
the game asking — alt-tab, a notification, clicking outside the canvas. `InputAdapter` used to
track only `pointerCaptureRequested`, a flag it set itself and had no way to know the platform had
overridden.

**Fix shape**: poll `Gdx.input.isCursorCatched()` — the platform's actual reported state — against
the flag each frame, inside the same method that already handles Escape's deliberate release
(`InputAdapter.managePointerCapture`). If the flag says captured but the platform says not, and
Escape wasn't the cause this frame, it's an unasked-for revocation. Escape's own release must be
checked as a separate condition in the same method, or the two get conflated and Escape trips the
"unexpected" path too.

**Design decision, not just implementation**: on an unexpected loss, `PlayScreen` pauses the game
using the overlay Escape already opens, rather than falling back to keyboard-only or drawing a new
click-to-resume prompt. Reasons: no new UI needed (`BaseUiScreen`/`GameSkin` already cover pause),
resuming already re-arms capture correctly through the existing click-to-capture path, and a
player who alt-tabs mid-fight is better off coming back to a frozen game than to a ship reading
garbage deltas from a freed cursor. See `docs/plan/11f-web-defects/status/41-pointer-lock-recovery.md`
(issue #41) for the full writeup.

**Still not checked**: real-browser confirmation that losing focus in Chrome/Firefox actually
triggers `isCursorCatched() == false` the way the desktop LWJGL3 backend does. Could not open a
real browser from this sandbox. This is exactly the kind of claim phase 09 got away with skipping —
don't repeat that; say "not checked" until someone with a real browser confirms it.

## Correction — `setCursorCatched(true)` is asynchronous on the web backend

Found in review (phase 11f, PR #221), from reading `backend-web-1.6.1-sources.jar`,
`com/github/xpenatan/gdx/teavm/backends/web/WebInput.java`, not from running anything: on the web
target, `Gdx.input.setCursorCatched(true)` calls the browser's `element.requestPointerLock()`,
which is **asynchronous** — the grant lands later via a `pointerlockchange` event, and
`isCursorCatched()` (`document.pointerLockElement === canvas`) still reads false the instant
`setCursorCatched(true)` returns, for an unknown number of subsequent frames too.

This means: never test `isCursorCatched()` for "did I just lose the lock" in the same call, or the
next few calls, that requested it — that reads a still-pending grant as a revocation. The desktop
LWJGL3 backend grants the catch synchronously, so this class of bug is invisible to any local
desktop run and can only be caught by reading the platform source or by testing in a real browser.

The fix that held up under review was not a fixed number of frames of grace (that just moves the
race rather than closing it) but a latch: only treat `isCursorCatched() == false` as a loss once
`isCursorCatched() == true` has been observed at least once since the request. A slow grant is then
waited out for as long as it actually takes.
