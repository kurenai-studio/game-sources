# Scheduler fault cases entry: timer registration and cancellation throws

Read-only evidence record. No code, test, requirement or CI change. Prepared by the auditor. This record shows what the committed suites and two scratch experiments establish for the blueprint's "Scheduler fault cases" candidate entry. It classifies nothing, adopts no status word, establishes no requirement violation, and identifies no implementation defect.

## The entry

Blueprint section 14: "Phase 1 must explicitly record in the trust ledger whether scheduler registration and cancellation are inside or outside the trusted boundary before scheduler-fault results are certified." Where the scheduler is inside the trusted boundary, it names two injections:

- "Scheduling failure after callback registration. A scratch scheduler registers a callback/timer and then throws." To record: the returned handle; the stored timer state; whether the callback can still execute; whether the engine reaches safe failure; whether an orphan timer remains capable of mutating state.
- "Cancellation failure. Make `clearTimeout` throw during failure cleanup." To record: the remaining timers; the game state; the fault state; whether callbacks can still mutate authoritative state.

"If the scheduler is explicitly outside the trust boundary, these become trust-ledger assumptions rather than production defects. The assumption must be recorded and justified."

The appendix entry's status is "Candidate; classification depends on the O6 trust ledger." The Phase 5 certification record lists O6 as Partially Established.

## Governing texts (Obs)

- SAF-3 (REQUIREMENTS.md): "If anything in the engine throws, the game stops in a safe state (game over, no timers running), the fault is reported, and the last good save is kept."
- D22 T1, what "reported" means for a SAF-3 stop: "the fault counts as reported when the player is shown a plain message that the game stopped because of an internal error, so that no developer console is needed to see that something went wrong, and a separate signal that a test can observe is raised; the criterion is independent of any particular callback or interface the implementation uses."
- D22 T3: "a timer cancelled successfully is trusted not to run afterwards; if registering or cancelling a timer throws, the engine stops in the SAF-3 safe state and the fault is reported under T1; no defense against a scheduler that runs a timer after a successful cancellation is required."
- D22, Not decided: "what the safe state requires if cancelling a timer itself throws during a fault stop, which depends on the meaning of timer for SAF-4".
- D23, failed cancellation: "if cancelling a timer fails while the game is stopping after a fault, a timer may still fire but must not change the stopped game, which stays over with the last good save kept and the fault reported; successful cancellation stays trusted (D22 T3) and no mechanism is chosen."
- F19 (Settled) records the deliberate implementation choice: "Left outside a catch on purpose: clearing the timers, which the scheduler, a trusted control, never fails at, and telling the page to redraw, which is the page's and part of SAF-5."

## Engine structure (Obs, main `9db0855f`)

- Every engine entry point runs through `guard()` (`gameManager.js:392`): player actions (`handleAction`, `:465`), the soft-drop tick (`:534`), and every scheduled timer callback (`schedule` wraps each callback in `guard` at `:386`).
- `guard()` catches nothing itself. `runChecked()` (`:398`) runs the operation and the invariant check inside one `try`; its `catch` calls `failSafe('unexpected error', error)` (`:407`). `guard()` then calls `onChange()` only if `runChecked()` returned normally.
- `failSafe` (`:441`) sets the state to game over first (`:442`), then calls `stopGameLoop()` (`:443`) and `cancelLockDelay()` (`:444`) with no catch; each calls `scheduler.clearTimeout` (`:373`, `:316`) and only then clears its task field, so a throwing cancellation also leaves the task field set. Only after the cancels does `failSafe` record the fault and call the report callback, each behind its own empty catch (`:448-458`). A `clearTimeout` throw during `failSafe` therefore escapes before the fault is recorded or reported, and escapes `runChecked`'s `catch` and `guard()` to the engine's caller. This is the code path F19 describes as left outside a catch on purpose.

## Committed coverage (Obs)

This record identifies two committed tests that inject a scheduler registration throw, in different contexts:

- `test/audit/d74-N1.test.js` (the permanent Node suite): the fake scheduler's `setTimeout` throws without registering the callback, during a confirmed New Game (the D74/D75 N1 reading). The test asserts the game stops at game over, the fault is recorded once and reported once, the old save stays withdrawn with its stored text kept, no timer is left pending, and a fresh New Game recovers. The file executes in the permanent suite (runtime file discovery at the same source: `score-mutation-run-raw.txt`).
- `e2e/engine-fault-notice.spec.js` (the Playwright browser suite): the recovery loop (`:69`) includes "timer registration throws does not clear the engine fault notice [SAF-3]", which replaces `game.scheduler.setTimeout` with a throwing function (`:76`) after a fault and asserts only that the player-visible fault notice survives a New Game attempt; the loop discards the fault helper's return value. The game-over, no-timer and recorded-fault assertions live in a separate earlier loop over the initial fault injection, a different context from the registration-throw recovery case.

Both committed tests throw from the registration call without storing the callback. The blueprint's case 1 is a different injection: the scheduler registers the callback and then throws, leaving an orphan callback. The search behind this inventory is a pattern search of `test/` and `e2e/`, not a completeness proof; it previously missed the browser spec, which replaces the method by assignment inside `page.evaluate`.

## Case 1: registration stores the callback and then throws (Obs, one indicative scratch run)

The fake scheduler's `setTimeout` stores the callback in the real scheduler and then throws, as the blueprint elaboration describes; a New Game action triggers the first registration. The blueprint's record list, all asserted and passing:

- Returned handle: none. The call threw before returning, and the gameLoopTask field was never set.
- Stored timer state: the scheduler still holds the registered callback - one pending timer, an orphan the engine has no handle for.
- Whether the callback can still execute: yes. Advancing the scheduler fires it, observed through the page-change signal firing again.
- Whether the engine reaches safe failure: the observed parts are the game-over state, one recorded fault and one report-callback call (the T1 signal half; the player-visible half is untested here - Limits). Full safe failure is unestablished in this run: one orphan timer stayed pending after the stop, and whether a pending-but-inert timer meets SAF-3's "no timers running" is the same open question as in case 2; the orphan's firing is covered by the next item only for the named fields.
- Whether an orphan timer remains capable of mutating state: in this run the fired orphan changed no snapshotted field (state, score, boardVersion, gameBoard, currentTetromino, nextTetrominos, heldTetromino, canHoldTetromino, isConfirmingNewGame, lockDelayResetCount, lowestRowReached, gameLoopTask, lockDelayTask). It did invoke the page-change signal. Capability beyond the named fields is unestablished.

Stop and timers versus record and report: the fault was recorded once and the report callback fired once, while one orphan timer stayed pending after the stop and, when fired, changed no measured field.

## Case 2: clearTimeout throws during failSafe (Obs, one indicative scratch run)

The fake scheduler's `clearTimeout` throws while the engine stops after a fault. The blueprint's record list, all asserted and passing:

- Remaining timers: one. The gravity timer whose cancellation threw stays pending, and the gameLoopTask field is left set, because `stopGameLoop` clears the field only after `clearTimeout` returns. When the scheduler then advances, the pending timer fires; its callback clears the task field, and no timer remains pending.
- Game state: game over when the cancellation throws, and every snapshotted field except the task handle is unchanged by value after the pending timer fires (the same field list as case 1).
- Fault state: the original fault is not recorded (the faults list is empty) and the report callback never fires, because the cancellation throws before `failSafe` reaches its record and report steps.
- Whether callbacks can still mutate authoritative state: in this run the fired timer cleared the gameLoopTask field and changed no other snapshotted field. Stored bytes behind one sentinel key were untouched at every check (Limits).

Stop and timers versus record and report: the game reaches the game-over state; the fired timer clears its own task handle and changes no other measured field, while the original fault is neither recorded nor reported.

Mapping to the decided texts (Obs; the classification questions stay open). The observations are enumerated; this record does not count how many decided obligations they satisfy:

- D23's failed-cancellation decision: "a timer may still fire" - observed: one timer stayed pending and fired when the scheduler advanced. "Must not change the stopped game" - observed for the named snapshotted fields except the task handle, which changed (left set by the failed cancellation, cleared when the timer fired); anything outside those fields is unestablished. "Stays over" - observed: the state field stayed game over. "The last good save kept" - unestablished by this run: one stand-in key's bytes were untouched, and no other stored key was checked. "The fault reported" - not observed: the report callback was never called.
- D22 T3 says that if cancelling a timer throws, "the engine stops in the SAF-3 safe state and the fault is reported under T1". The stop to game over is observed; the reporting is not observed in this run.
- SAF-3's safe state reads "game over, no timers running". In this run's state after the fault, one timer stayed pending; firing it cleared the gameLoopTask field and changed no other snapshotted field. Whether a pending-but-inert timer meets "no timers running" is part of the open classification, which D22's Not-decided list ties to the meaning of timer for SAF-4.
- D22's Not-decided list names this exact case: "what the safe state requires if cancelling a timer itself throws during a fault stop". This record does not fill that gap.

## Limits

- Local Node 22.23.3 is indicative, not authoritative; CI runs Node 26 or newer.
- One local run per case. The scratch tests are outside the repository: the suite does not discover them and they change no repository file. Raw capture: `scheduler-cancel-throw-run-raw.txt`.
- Case 2 drives the path through a direct `guard()` call; the real entry-point callers, which call `guard()` without their own catch, are not exercised.
- The sentinel stored value is a stand-in written by the test, not a save the game wrote (F29 records what a game's own save does and does not prove).
- D22 T1's report criterion has two halves: a test-observable signal and a player-visible message. These runs measure the callback half only; no browser run was made, so the player-visible half is unestablished here.
- The snapshot comparison covers the named instance fields only; constructor configuration fields (rows, columns, intervals, reset maximums) and anything not enumerated are outside the comparison.

## What this record does not do

- The Scheduler fault cases entry keeps its Candidate state; classification depends on the O6 trust ledger, and this record classifies nothing.
- It establishes no requirement violation and no implementation defect.
- It proposes no fix, no test change, and no requirement change, and it moves no phase.
- It asks for no owner decision.
