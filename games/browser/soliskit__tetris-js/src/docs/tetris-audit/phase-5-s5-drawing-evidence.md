# S5 entry: a drawing error during play

Read-only evidence record. No code, test, requirement or CI change. Prepared by the auditor. This record shows what a source inspection, the committed browser spec, and one live-page probe establish for the blueprint's S5 entry. It classifies nothing, adopts no status word, changes no ledger row, establishes no requirement violation, and identifies no implementation defect.

## The entry

Appendix S5: "Status: Candidate pending reproduction. A page redraw callback can throw after a checked engine step. The audit must establish whether `drawSafely` contains the required containment and loop continuation behavior under SAF-5."

## Governing texts

- SAF-5 (REQUIREMENTS.md:88): "An error while drawing or reading a gamepad is reported and the drawing and polling loops keep running." This record covers the drawing half; the gamepad half has its own records.
- Blueprint section 13 ("S5: drawing failure"): inject an exception from the drawing path after an engine action has completed, and record whether the error is caught; whether the fault is reported as required; whether render caches are cleared; whether another frame is requested; whether later drawing attempts continue; whether engine state remains safe.
- D23 (2026-10-04): for SAF-5, "a drawing or gamepad-read error leaves the loops running and counts as reported when the player sees a small non-blocking notice and a separate test-observable signal is raised, with no stored fault record."
- D68 (2026-10-17): S5 is Reproduced for what rows 5, 10, and 61 show (runs on October 16 in Chrome 154, error injected): the first drawing error was reported and retried on every frame (row 61); a second, different error was not reported (row 5); a cell with no color failed on every frame and the pause menu never appeared (row 10). Recorded limit: "The auditor's runs did not show whether the game clears its drawing caches."

## Page structure (Obs, main `0f1e3ab`)

- `script.js:14` wires the engine's `onChange` to `engineChanged` and `onFault` to `reportEngineFault`.
- `engineChanged` (`:19`) only clears the engine-fault notice flag when the game is not over and calls `requestDraw`. Drawing is deferred to the animation frame callback, so a drawing error never runs inside the engine's guard. The synchronous callback boundary itself is covered by the Entry-wrapper cases record.
- `requestDraw` (`:385`) allows one pending frame; the frame callback clears the pending flag and runs `drawSafely(drawIfChanged)`. A refused frame registration resets the flag and rethrows.
- `drawSafely` (`:367`) runs the draw in a try/catch. The catch clears `drawnBoard`, `drawnPreviews` and `lastSnapshot`, logs "Tetris drawing error, retrying next frame:" only on the first error (`renderErrorReported`, `:364`), and calls `requestDraw`.
- `drawIfChanged` (`:327`) redraws the board only when `boardChanged()` (`:318`) finds a difference against `drawnBoard`, redraws a preview only when `drawnPreviews` has no matching entry, and runs `syncControls` only when the snapshot string differs from `lastSnapshot` (`:350-352`). With caches intact and nothing changed, a frame makes no canvas fill calls.
- The caches start empty at page load (`lastSnapshot = ''` at `:306`, `drawnBoard = {}` at `:314`, `drawnPreviews = new Map()` at `:316`). Two other paths clear them: the ResizeObserver listener (`:400-406`) and the pixel-density listener (`:411-414`), each rebuilding canvases through `sizeCanvas` and running `drawSafely(redrawAll)`; `redrawAll` (`:356`) clears `drawnBoard` and `drawnPreviews`.
- The draw-error path sets no player-visible notice: `engineFaultNotice` is set only in `reportEngineFault` (`:25-29`) and shown through the game-over message area (`:242-245`); `drawSafely`'s catch touches no notice element and writes no storage (source path read).

## Committed coverage (Obs)

- `e2e/safety.spec.js:39`, "an error while drawing does not stop the game from drawing [SAF-5]", wraps `CanvasRenderingContext2D.prototype.fill` with a one-shot throw (the same injection class as the probe below), starts a game, presses Space (hard drop), and asserts the filled-cell count rises from 4 to 8 (the drop took effect and drawing recovered) and that exactly one console error includes "Tetris drawing error". The spec injects one error; it does not test whether a second error would be reported.
- `.github/workflows/pages.yml` runs on pull requests and on pushes to main; its test job runs `npm test` and `npm run test:e2e` (`playwright test && node scripts/browser-coverage.js`, `package.json:14`), which includes the spec above. This record claims nothing about any particular workflow run's result.

## Live-page probe (Obs, one deployment, one browser, two injected errors)

Method: the deployed page on October 23, 2026, whose `script.js` fetched at probe time is byte-identical to main `0f1e3ab`'s `public/script.js` (SHA-256 match over the fetched bytes). Hosted Chrome 155. The probe wrapped the canvas fill method to record every attempted fill call (timestamp, canvas) before forwarding it and, when armed, to record the call and throw a one-shot error instead of forwarding it; it counted draw-error console reports, recorded every storage write by key, and watched for resize-path cache invalidation (window resize listener plus a MutationObserver on every canvas's width and height attributes, which both resize-clearing paths in the source write through `sizeCanvas`). The browser's own console log was read afterward as an independent cross-check. No keys, clicks or other input were sent during the trial windows; the game ran on its gravity timer only. A "frame group" below means a group of attempted fill calls sharing a timestamp (or timestamps 1 ms apart); the recorded throw and the later calls are distinct timestamped records, and actual animation-frame boundaries are unmeasured. The raw capture (`s5-drawing-probe-run-raw.txt`) carries the instrumentation source and the recorded event objects for each window; an earlier same-day run (run 1) is retained there as clustered frame summaries, labeled as such.

Baseline: ordinary gravity-tick frame groups recorded board-only calls, with zero preview calls, consistent with the preview cache hitting. Run 1 captured the first frame after New Game drawing the board and all three next previews (the caches start empty at page load).

Trial A (Error): two pre-error frames in the window drew the board only (9 fills, then 8; this trace does not explain that change, and the controls below do not rely on it). The armed call was recorded throwing at the next tick's frame (t=18613); one console report at the same timestamp. 11 ms later (t=18624), a recovery frame group recorded attempted fill calls across the board (8 calls) and all three next previews. The next tick's frame group (t=19613) recorded board-only calls (8).

Trial B (a second, different error: a TypeError with a different message): two pre-error frames drew the board only (12 fills each). The armed call was recorded throwing (t=31613); 4 ms later (t=31617) a recovery frame group recorded attempted fill calls across the board (12 calls) and all three next previews. No second console report was observed across the two injections, and the browser's own console log held no entry for the TypeError. Trial B's window ends at its recovery frame group; no later group was recorded for it.

Observed with named limits: in both injections, the recovery frame group recorded attempted fill calls across all three next previews alongside the board. The probe did not measure queue identity, engine state, frame boundaries, or successful paints: module state is unreachable from the page console, frame groups are timestamped call groups, not instrumented animation-frame callbacks, and the fill wrapper records each call before forwarding it to the native method, so counts are attempted calls, not verified paints. Trial A's first in-window frame group also recorded 9 board fills, which the source painting model (`drawBoard` `:167-202`, filling once per occupied locked cell and once per active-piece cell through `drawBlock` `:140-143`; the ghost piece stroked only, `:153-163`) cannot account for; because the trace itself breaks that model, no count-based lock exclusion is claimed, and a lock on an errored tick would shift the next queue and paint the previews for the ordinary reason. What the trace does establish independently of the counts: no resize event and no canvas attribute mutation was recorded during either trial, so the two resize-path cache-clearing routes did not fire, and no input was sent during the windows, so no hold action occurred. Within these limits, the recovery frame groups' preview calls are consistent with the catch's clearing of `drawnPreviews`; the lock path is not excluded by measurement.

Storage: the write listener recorded zero storage writes during both trial windows, so no fault record was persisted on the draw-error path during the probe; the source path read agrees.

Continuation: in run 2, trial A's next tick frame group followed its recovery group; trial B recorded no later group. Run 1's raw records a later frame group at t=41392 (tetris x16 plus next0/next1/next2 x4, read as a lock shifting the next queue under the same model limits) after run 1's first injection (t=39916) and before its second. After run 1's second injection, the continuation evidence is the pixel captures: run 1's captures (before its first injection and after its second) show normal play at two moments - continuation evidence only, not per-frame or cache proof.

Cleanup: the page was reloaded after each run; the fill and storage prototypes are native again and the instrumentation is gone. The probe changed no site, code or stored audit state; ordinary gameplay writes to the browser's own storage are the game's normal behavior.

## The blueprint's record list, item by item

- Whether the error is caught: caught. Obs: both probe injections (play continued), the committed spec, and the source (`drawSafely`'s try/catch).
- Whether the fault is reported as required: under D23, "reported" means a small non-blocking player notice plus a separate test-observable signal, with no stored fault record. Obs: one report was observed across the probe's two injections (the first error reported, the second, different error not); the separate single-error spec expects one report. The source latch (`renderErrorReported`, `:364`) explains the suppression mechanism. This is the same shape D68's row 5 records for its runs, observed fresh here, not a rerun of those runs. No player-visible notice was set on the draw-error path (source reading; none appeared during the probe). No storage write occurred during the probe's trial windows (write listener) and the source path writes none. This record reports the observations without evaluating them against D23.
- Whether render caches are cleared: each recovery frame group recorded attempted fill calls across all three next previews. The source says a preview redraws when `drawnPreviews` has no matching entry, and the catch clears `drawnPreviews`; the clearing assignments themselves are source-read (`:367-384`). With the limits above, the preview call groups are recorded as consistent with the catch's clearing. (The caches also start empty at page load, which is why the first frame draws everything.) The board redraw is expected from the tick alone and is not evidence about `drawnBoard`. The prior runs recorded in D68 did not show cache clearing; this probe records the preview-call consequence on this deployment.
- Whether another frame is requested: the source catch calls `requestDraw` (`:376`); in both injections a later group of attempted fill calls followed the recorded throw (11 ms and 4 ms by timestamp).
- Whether later drawing attempts continue: trial A recorded a later tick group of attempted fill calls (t=19613) after its recovery group; trial B's window ends at its recovery group, so no later group was recorded for it. The spec's filled-cell count rises 4 to 8 after its injected error. Run 1 recorded continued play after its injections (cluster summaries and pixel captures).
- Whether engine state remains safe: engine-state correctness is unmeasured by this probe. The engine-step evidence is the spec's: its hard drop took effect after the injected error (filled cells 4 to 8). The source reads show the drawing path writes only page-side caches (`drawIfChanged` reads engine fields and writes `drawnBoard`, `drawnPreviews`, `lastSnapshot`).

## Limits

- One deployment (other deployed files not re-verified), one browser engine (Chrome 155; D68's runs used Chrome 154), two injected errors in run 2.
- The injected error is synthetic: a throw from the canvas fill method on a frame's first fill call. A throw partway through a board draw was not separately injected. This is the same injection class as the committed spec and as D68's injected state.
- Fill counting records attempted calls before forwarding to the native method (the armed call is recorded and thrown without forwarding); counts are attempted calls, not verified paints. The raw carries the instrumentation source and the recorded event objects for run 2; run 1 is retained as clustered summaries.
- The cache-clearing observation is a call-group consequence (attempted fill calls across all three previews in each recovery frame group) with the limits named above: queue identity, engine state, frame boundaries and successful paints unmeasured; one pre-error count unexplained; the clearing assignments themselves source-read.
- The probe's gravity-tick setting differs from the spec's hard drop; both are engine steps whose drawing runs in the frame callback.
- The row 10 condition from D68 (a cell with no color failing on every frame) was not re-injected; this record does not re-run the prior rows.

## What this record does not do

- S5 keeps its existing status word and its recorded limit; changing either is a ledger change outside this record.
- It evaluates nothing against D23's reporting definition and classifies nothing.
- It establishes no requirement violation and no implementation defect.
- It proposes no fix, no test change, and no requirement change, and it moves no phase.
- It asks for no owner decision.
