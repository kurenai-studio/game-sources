# Held-Key Repeat Checks

Seven controlled cases for stopping repeats, Resume, and key aliases.

These seven engine-and-controller cases were independently reviewed as candidates. They do not dispose of findings, certify anything, or provide real-device evidence. Production, public-identical main. It changed no code, permanent tests, or CI and was not part of PR77.

## Rules and scope

D23 U4 (`phase-1-trust-and-timer-scope-decision.md`) covers stopping repeats and timer checkpoints. D18 B12/B13 (`phase-1-r1-decision.md`) defines physical control tokens, repeat phase, and outstanding firings. D33 C3/D34 E2/E3 define suppression of controls held across Resume.

D22 T1 defines a player-visible message plus a separate signal. D23 U3 governs failed cancellation, which these cases do not inject. INP-2/INP-4, STA-2, and SAF-3/SAF-4 are implicated. Writer-matrix references W08/W09/W19 and W25-W29 are mapping leads, not verified frame proof.

## Method and observations

The seven cases were declared before execution. They use the actual GameManager and InputController with fake window listeners, RAF, map-backed global timers, an injected engine scheduler, successful memory storage, and a fixed O factory. Actions enter through `handleKey` and public game actions. Only the factory is made to throw. The harness manually fires the callbacks actually registered; it claims no real elapsed duration.

| Case | Observation | Source relation |
| --- | --- | --- |
| Horizontal pause | One repeat remains outstanding after pause. Its first firing clears it without moving the piece. | U4/B13 say repeats stop while paused; bounded deferred-stop candidate |
| Soft-drop pause | One interval remains. Its first firing clears it without moving the piece. | Same bounded deferred-stop candidate |
| Both pause | Two repeats remain. The first horizontal firing clears its own repeat; soft drop remains until it fires. | Separate-resource projection, not handle-name inference |
| Horizontal factory fault | The game is over, with one repeat remaining and one fault signal. The next repeat clears itself. | U4/SAF-3 stop candidate; T1 visible message unassessed |
| Horizontal ordinary top-out | The game is over, with one repeat remaining until it fires. | U4/B13 ordinary-over stop candidate |
| Held direction across resume | Resume occurs before DAS fires. The registered callback then moves the piece from column 3 to 2 without release and re-press. | Bounded C3/E2/E3 suppression candidate |
| ArrowLeft plus A, release ArrowLeft | The aliases share a KeyA token. Releasing Left clears the still-physically-held A and stops repetition. | D18 B12 explicitly keeps separate tokens for keyboard A and Left, as D40 integrator section 3 records; the observed alias collapse is a grounded bounded candidate, not a classified finding |

The held-resume setup presses Left once while playing, pauses using Escape before any first-repeat callback, releases Escape, presses Escape once to resume, then fires the retained direction callback. The direction itself is never released or re-pressed.

## Independent review and limits

An independent Node22 review reran all seven cases with byte-identical outputs and checked the routes and resource mapping. Escape remains in the harness held-key set in some rows because it is not released; it does not cause the movement. Paused callback firings do not move the piece. No asynchronous grace period is added to U4/B13 merely because the implementation stops at the next firing.

The static page observation covers script.js line 12 (onChange: requestDraw), lines 355-362 (requestDraw schedules drawing), and line 526 (controller construction). A search of script.js for releaseAllInput/stopMoving/stopSoftDrop found no calls. That static observation does not replace full page integration. Real browser focus, trusted events, rendering/RAF coupling, elapsed DAS/ARR/soft-drop durations, gamepad, touch, device behavior, and the plain player-visible fault notice remain untested. No semantic model was run for this class. These implementation-exposed observations are not clean-author input.

## Preserved scratch identity

The v18 manifest records `input-repeat-resources.mjs` SHA-256 `b2a39b631a536899b7d84acfda8fe140b67259f6bedf02460c9cd8e7af8ab5b8` and `input-repeat-resources.json` SHA-256 `ef4745326455cded4a5f5e147ecae7be378751f9d8d24f7e71f6dc9e5473bf6a`. These hashes identify the coordinator-held exact bytes; fidelity review did not independently hash the raw artifacts. The state/input reviewer did rerun all seven output rows.
