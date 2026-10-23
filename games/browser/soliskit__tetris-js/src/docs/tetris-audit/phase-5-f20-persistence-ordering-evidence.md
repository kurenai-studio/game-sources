# F20: persistence-ordering reproduction classes - evidence record (draft)

Blueprint F20 entry (`docs/tetris-audit/audit-blueprint.txt:1408`). One indicative local run, not a status. This record adopts no classification. Raw capture: `f20-persistence-ordering-run-raw.txt`.

## Governing texts

- Blueprint F20 (`:1408-1438`): the persistence effects listed as reproduction classes (pause save; line-clear save; game-over forgetting; high-score write; New Game forgetting; other persistence effects), which are "not presumed affected operations and not presumed to share one defect"; the four questions - Ordering, Applicability, Correspondence, Consequence; evaluation primarily under SAF-3 and O4; the high-score write is traced as an authoritative persistence side effect without presuming the saved-game last-known-good rule applies to it (R4 decides); R2 determines the forgetting semantics for New Game (STA-1) and game over (STA-3).
- STA-1 (`REQUIREMENTS.md:73`): New Game "resets the board, score, level, held piece, queue and bag, and forgets the saved game"; while paused it first asks in a dialog.
- STA-3 (`:75`): "The game ends when a new or held piece has no room to appear. All timers stop and the saved game is forgotten."
- STA-4 (`:76`): "Pausing saves the game, and so does clearing lines. Continue, from game over only, restores exactly what was saved, paused, including the pieces left in the bag."
- SAF-3 (`:86`): "If anything in the engine throws, the game stops in a safe state (game over, no timers running), the fault is reported, and the last good save is kept."
- O4 (blueprint `:284-292`): the persistence-ordering rule applies only where preservation is required, and O4 is subordinate to the applicable requirement semantics.
- R2 and R4, decided October 4, 2026, recorded in `DECISIONS.md` D21 and owned by `docs/tetris-audit/phase-1-r2-r5-decision.md`: forgetting a saved game means withdrawing it from Continue without requiring deletion, done when New Game is confirmed and at normal game over, and a later error does not undo it. On failure semantics the owning decision doc says (:15): "If the position writes but marking it available fails, the save failed. A failed save attempts withdrawal as described below" - and the described limits: a failed withdrawal write keeps the previous saved game out of Continue in the running session, with nothing promised after reload; a valid saved game written successfully is the last good save with no rollback.
- C1 (D33, `DECISIONS.md:106`): a save caused by clearing lines captures the completed turn including the next piece, and if that turn ends the game no save is written and the saved game is withdrawn. This scopes the line-clear class and the open same-step construction question named below.
- F29 and D72f (`DECISIONS.md:48` and `:177`, line numbers at commit fa2f061): F29 is folded into F20, its gap carried as a limit - a save the game wrote itself is not shown to be complete, because reset count and lowest-row history are not saved, and a test of "the last good save is kept" needs a game-written save shown good on independent grounds, which has not been built. This record implies no retention or reclassification of any existing F20 or F29 ledger entry.
- D16 Amendment 2 (D20, `DECISIONS.md:93`): the stored saved-game eligibility indicator (section 1.4, item 3), for which only the exact stored value "true" makes a saved game eligible, and the session-local withdrawn indicator (section 1.1, item 16).

How the observations classify against these texts is the audit's later-phase work, not this record's.

## Method

Scratch copy only: the repository tests and requirements are unchanged. `node --test`, Node.js v22.23.3 (measured `node --version`), local shell, against a scratch checkout of commit fa2f06117c3f3aa82a3ddfdc2a20dce502d9a2d2, with the fake scheduler from the repository's own test helpers. Four scratch test files (10 tests), each driving a real `GameManager` with an in-memory storage whose `setItem` is wrapped to log writes in order; `saveGameSession`, `findInvariantViolation` and `failSafe` are wrapped into a call-order log; the `onFault` report callback is a counting spy. All assertions are literal measurements (order indexes, write-log contents, spy counts, byte comparisons), not style-based judgments. Actions are driven through the public `handleAction` (`gameManager.js:464-465`), which routes through `guard` (`:392`) and `performAction` (`:469`). Source basis for the expected ordering: `saveGameSession` (`:222-229`); the pause branch (`:491-500`) saves at `:499` as its last statement, after `stopGameLoop` and `cancelLockDelay`; `lockAndSpawnNext` (`:320`) runs `clearFullRows` (`:322`) and saves at `:325`; `clearFullRows` (`:337`) updates the score and the high score (`:351-352`, the storage write inside the `highScore` setter at `:151`); the no-room game over assigns the game-over state at `:240` and writes the flag false at `:241`; `resetGameSession` (`:183-196`) writes the flag false at `:195` as its last statement; `loadGameSession` (`:200`) returns at `:201` when the flag is false and at `:204` when the save-text read returns null, and marks a refused (unparseable) save unavailable at `:207` while leaving the stored text alone (source comment `:198-199`); `get isSessionSaved` (`:159-162`) reads the flag through `readItem` and caches the boolean, and the set path (`:165-166`) invalidates through `storageChanged` (`:175`).

Every baseline ("previous") save in these tests is production-written by a real pause; the completeness limit is stated in Limits.

## Observations by reproduction class

### Pause save (three tests)

- Ordering trace: on pause, `saveGameSession` runs inside the operation, before the post-transition invariant check (both ran; the save's call-order index is lower). No `failSafe` call (spy count 0). Correspondence: the parsed score equals the in-memory score and the parsed board deep-equals the in-memory board (score and board only); the flag reads "true".
- Injection before the save (the lock-delay cancellation inside the pause branch throws once): the state is `gameOver`, `failSafe` ran, and the `onFault` callback ran once (spy counts; assertion bounds in Limits). The save never ran; the baseline payload survives byte-for-byte and the flag stays "true" (no save and no withdrawal).
- Injection after the save (the invariant check itself reports an injected violation): the state is `gameOver`, `failSafe` ran once and the `onFault` callback ran once (spy counts). The pause save was written before the check ran and persists, with the parsed score matching the in-memory score (score only) and the flag "true".

### Line-clear save (two tests) and the high-score write

- Ordering: a hard drop that locks and clears a row writes the high score before the save (write-log order), and the save runs before the post-transition invariant check (call-order log). Correspondence: the persisted save's parsed score is the post-clear score (100); the flag reads "true"; no `failSafe` call (spy count 0).
- Injection mid-step (next-piece generation throws after the clear): the state is `gameOver`, `failSafe` ran once and the `onFault` callback ran once (spy counts; bounds in Limits). The line-clear save never ran; the baseline payload survives byte-for-byte and stays discoverable (the flag stays "true"; `failSafe` does not withdraw); the high-score write from the faulting step persisted ("100").

### Game-over forgetting (one test)

- An ordinary no-room game over (stacking vertical I pieces until the next spawn has no room) withdraws the saved game: the flag reads "false"; the stored save text remains byte-for-byte - withdrawal, not deletion, matching the decided R2 semantics. No `failSafe` or `onFault` call (spy counts 0): an ordinary game over does not stop through the fault path.

### New Game forgetting (two tests, with the blueprint's special item)

- The first New Game press only asks: the state stays paused and the flag stays "true". The confirmed second press starts the new game; the flag is written "false" (invalidation, not deletion); the stored save text remains byte-for-byte; and no replacement persistent state is written by the transition (zero writes to the session key). No `failSafe` or `onFault` call (spy counts 0).
- Injection mid-reset (piece generation throws before the flag write, which is the reset's last statement at `:195`): the state is `gameOver`, `failSafe` ran once and the `onFault` callback ran once (spy counts; bounds in Limits). The flag was never written (stays "true") - no forget without a completed reset - and the baseline payload survives byte-for-byte and discoverable.

### Other persistence effects (two tests)

- Refused-save withdrawal: an externally corrupted save text with the flag left "true"; the game-over state is reached through `failSafe` (a pause-branch cancellation injection, which stops the game with the save unreplaced and the flag untouched - `failSafe` does not withdraw - with the `onFault` callback invoked once, spy count). The public Continue action then writes the flag "false" (the refused save is withdrawn), leaves the corrupt text stored byte-for-byte, invokes no `onFault` call (spy count 0), and leaves the state unchanged (game over). Construction note: game over is reached through `failSafe` rather than an ordinary game over because an ordinary game over withdraws at `:240-241` and would consume the withdrawal before the Continue under test, and because a queue-shortening injection would fire the post-operation invariant check a second time. The "line clear and game over in the same step" edge is not constructed in this run and stays an open construction question.
- High-score reachability: a game over without any line clear writes no high score; in this run the high-score write exists only on the clear path.

## Limits

- Assertion scope: the tests measure the `gameOver` state, call and write order, byte equality, and `failSafe`/`onFault` spy counts. The full SAF-3 criteria - no timers running and a player-visible fault notice (D22) - are not measured, and the internal faults list is not inspected.
- Baseline payloads: every previous save is production-written; its completeness is not independently established (the F29/D72f limit). Byte preservation and score/board equality are measured; complete meaning and last-good qualification are not.
- Storage is a JavaScript in-memory stub, not a browser `Storage` object; browser-specific failure modes (quota, corruption, private-mode behaviors) are out of scope. The scheduler is the repository's fake test scheduler; real timer behavior is not exercised.
- The ordering measurements are at the manager's method-call and storage-write level; no DOM or rendered page was involved.
- Node.js v22.23.3 is below the repository's required Node >=26 (package.json `engines`); behavior under the required major version is not measured. One indicative run on one commit.
- The injection points are chosen boundaries (timer cancellation, next-piece generation, the invariant check itself, piece generation during reset); other boundaries inside the same operations are not exercised.
- Classification of these observations against the governing texts - Ordering, Applicability, Correspondence and Consequence per effect, and whether the effects are one defect or several - is the audit's later-phase work; this record adopts nothing.
