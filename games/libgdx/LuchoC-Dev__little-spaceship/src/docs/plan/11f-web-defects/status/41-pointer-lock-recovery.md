# #41 — Losing pointer lock breaks mouse control until the page is refocused

## What changed

`game/src/main/java/dev/luchoc/littlespaceship/game/adapter/input/InputAdapter.java`
`managePointerCapture` no longer trusts its own `pointerCaptureRequested` flag as the source of
truth. It now also observes `Gdx.input.isCursorCatched()` — the actual state libGDX reports back
from the platform (the browser's Pointer Lock API on web) — each frame. If the flag says the
pointer should be captured but the platform says it is not, and the player did not just press
Escape, the loss is unasked-for: a notification, alt-tab, or a click outside the canvas. That
frame, `InputAdapter.pointerCaptureLostUnexpectedly()` returns `true` once.

`game/src/main/java/dev/luchoc/littlespaceship/game/screen/PlayScreen.java`'s `render` checks this
flag right after sampling input and before advancing the simulation. When it is true, the sampled
frame (whose mouse deltas already came from the now-free cursor) is discarded and the existing
`pauseGameplay()` path runs instead of `loop.advance`.

Escape's deliberate release is untouched: it is checked first (`escapeJustPressed &&
pointerCaptureRequested`) and takes the branch that does not set
`pointerCaptureLostUnexpectedly`, so pressing Escape on purpose behaves exactly as before.

## Design decision: pause, not fallback-to-keyboard or click-to-resume

When the lock is lost unexpectedly, the game pauses using the same `PAUSED` / `RESUME` / `QUIT TO
MENU` overlay Escape already opens (`PlayScreen.pauseGameplay()`, built in
`PlayScreen.buildPauseStage()`).

Reasons, in order of weight:

1. **It reuses machinery that already exists and is already correct** — `BaseUiScreen`/`GameSkin`
   build the panel, `MenuNavigator` handles focus, and pausing is the one response that needs no
   new UI, which the task brief asked to flag if it were needed. It is not.
2. **A player who alt-tabs mid-fight and comes back to a paused game is in a better place than one
   who comes back to a ship that drifts** — quoting the task brief's own framing, because it is the
   right test: keyboard-only fallback would silently degrade the experience without telling the
   player anything changed, and a click-to-resume prompt drawn over live gameplay does not stop the
   ship from taking the one frame's worth of bad delta that triggered the loss in the first place
   (this fix discards exactly that frame instead).
3. **Resuming from pause already re-arms capture correctly.** `resumeGameplay()` clears
   `Gdx.input.setInputProcessor(null)` and returns control to `PlayScreen.render`;
   `InputAdapter.managePointerCapture` re-captures the pointer on the player's next click inside the
   canvas, the same path a fresh game start uses. No new re-engagement code was needed.

## What I verified and how

- `./gradlew :game:compileJava :desktop:compileJava` — `BUILD SUCCESSFUL in 5s`.
- `./gradlew :web:gdx_teavm_web_js_build` — `BUILD SUCCESSFUL in 16s`, and the log shows
  `Copied [Internal] .../assets/startup-logo.png (12214 bytes)` and
  `Copied [Classpath resource] startup-logo.png (12214 bytes)`, confirming the mandatory asset is
  still present and packaged.
- Read `InputAdapter.java` and `PlayScreen.java` fully before and after editing to confirm the
  Escape path and the new browser-revocation path set mutually exclusive outcomes for
  `pointerCaptureLostUnexpectedly`.

## What I did NOT verify — not checked

**Real-browser verification is not checked.** I have no way to open a real browser (Chrome or
Firefox, per this phase's scope — Safari is out of scope) from this environment, and
`CLAUDE.md`/the task brief are explicit that headless Chrome cannot substitute for this: it fails
under SwiftShader even when a real browser works. This is the project owner's to do.

### Exact steps to verify in a real browser

1. Deploy or serve the web build (`web/build/dist/js/webapp`) and open it in Chrome or Firefox.
2. Start a level, enable mouse control if not already on, and click inside the canvas to engage
   pointer lock (the cursor should disappear and the ship should track relative mouse movement).
3. **Reproduce the old bug's trigger**: press Alt+Tab to switch to another window (or open a new
   browser tab, or trigger any OS-level notification that steals focus), then switch back to the
   game tab/window.
   - **Before this fix**: the ship's movement would lose its centring — the first mouse move after
     refocusing would produce a large, wrong jump — and once the real cursor reached a screen edge,
     mouse movement would stop registering with the game at all, with no on-screen indication why.
   - **After this fix**: the moment focus returns and the browser reports the pointer lock as
     released, the game should show the `PAUSED` overlay (the same one Escape produces) instead of
     continuing to read broken mouse input. Pressing `RESUME` (or clicking it) should let the player
     click inside the canvas again to re-engage pointer lock and resume normal mouse control.
4. Separately, confirm Escape still works as before: while playing with the pointer locked, press
   Escape — the game should pause immediately (same overlay), and pressing `RESUME` should let a
   click re-engage the lock, exactly as pre-fix. This confirms the deliberate-release path was not
   changed by this fix.
5. As a negative check, confirm that briefly losing window focus a way that does **not** revoke
   pointer lock (if such a case exists in the target browsers) does not spuriously pause the game
   — not expected to occur based on the Pointer Lock API's documented behaviour, but worth an eye
   during manual testing since it was never checked here.

## Boundary check

No file under `core/` was touched. `game/src/main/java/dev/luchoc/littlespaceship/game/adapter/input/InputAdapter.java`
still imports only `core.port` (`BalanceValues`, `InputFrame`), unchanged from before this fix.

## Addendum — a false pause on the click that engages capture (found in review)

The reviewer flagged, and the coordinator confirmed from `backend-web-1.6.1-sources.jar`
(`com/github/xpenatan/gdx/teavm/backends/web/WebInput.java`), that the original fix could pause
the game the moment the player clicked to engage mouse control, on the web target specifically.

**Why.** `setCursorCatchedJSNI` on the web backend calls the browser's `element.requestPointerLock()`,
which is asynchronous: the grant arrives later via a `pointerlockchange` event, and
`isCursorCatchedJSNI` (`document.pointerLockElement === canvas`) still reads false the instant
`requestPointerLock()` returns. The original `managePointerCapture` ran the request and the loss
check in the same call with nothing separating them, so:

1. click → `pointerCaptureRequested = true`, `setCursorCatched(true)` called
2. same call → `isCursorCatched()` is still false (grant pending)
3. → read as an unasked-for revocation → `pointerCaptureLostUnexpectedly = true` → `PlayScreen`
   pauses on the very click meant to start mouse control.

**Why a desktop run could not have caught this.** LWJGL3's `setCursorCatched` grants the catch
synchronously, so `isCursorCatched()` is already true by the time the loss check runs on desktop.
The bug is invisible to any local desktop launch and only exists on the web backend's async path —
exactly the kind of thing this phase's evidence rule exists for: I could not have found this by
running the game, only by reading the platform source, which is what the coordinator did.

**The fix, and why a single-frame `return` was not enough.** A `return` right after setting
`pointerCaptureRequested = true` would suppress the false pause on the request frame itself, but
the coordinator's question stands: nothing guarantees a browser grants the lock within one frame.
If the grant takes longer, a bare one-frame guard just moves the false pause to the second frame.
So instead of counting frames, `managePointerCapture` now gates the loss check on a new
`pointerCaptureConfirmed` flag: the loss check is inert until `isCursorCatched()` has been observed
`true` at least once since the request. A pending grant — however many frames it takes — is
silently waited out; only a capture that was actually confirmed and then revoked counts as an
unexpected loss. Escape's deliberate-release branch clears both flags and is unaffected.

**Verification after the fix.**
- `./gradlew :game:compileJava :desktop:compileJava` — `BUILD SUCCESSFUL`.
- `./gradlew :web:gdx_teavm_web_js_build` — `BUILD SUCCESSFUL`.
- The async-grant race itself is still **not checked** against a real browser — the same
  real-browser verification gap the original report already named. The reproduction steps above
  now additionally ask the project owner to confirm that clicking to engage mouse control does
  **not** immediately show the `PAUSED` overlay, since that would mean the grace window is still
  insufficient in practice.
