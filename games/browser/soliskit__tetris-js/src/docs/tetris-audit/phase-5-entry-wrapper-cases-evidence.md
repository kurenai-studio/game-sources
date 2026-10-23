# Entry-wrapper cases entry: statements outside the guarded boundary

Read-only evidence record. No code, test, requirement or CI change. Prepared by the auditor. This record shows what a source inspection and one scratch run establish for the blueprint's Entry-wrapper cases entry. It classifies nothing, adopts no status word, establishes no requirement violation, and identifies no implementation defect.

## The entry

Blueprint section 15 asks for an inspection of the exact wrappers: `handleAction`, `softDrop`, `cancelNewGame`, and "other public entry methods that merely invoke the guarded boundary". For each wrapper: identify every statement outside the guarded operation; identify independent state mutation; identify dependencies capable of throwing; determine whether an exception can occur before or after the guard while leaving authoritative state changed; and test any real dependency boundary that can be injected. "If a wrapper contains no independent mutation or post-guard behavior and no relevant exception boundary exists, record the result as evidence rather than inventing a hypothetical failure."

## Which methods the page can reach (Obs, main `a289770`)

The page layer's own type names the entry surface: `inputController.js:18` defines `Controllable` as `Pick<GameManager, 'state' | 'isConfirmingNewGame' | 'handleAction' | 'togglePause' | 'softDrop' | 'cancelNewGame'>`. `script.js` calls the same four methods plus `storageChanged` (`script.js:588`), and otherwise reads fields and getters (`state`, `isConfirmingNewGame`, `isSessionSaved`, `highScore`, `score`, `gameBoard`, `currentTetromino`, `nextTetrominos`, `heldTetromino`, `ghostTetromino`, `boardVersion`, `columns`). `hardDrop`, `moveTetromino`, `holdTetromino` and `rotateTetromino` are public on the class but are reached only from `performAction` (`:469`), inside the guard. The browser specs drive `handleAction` through `page.evaluate` and reach the other wrappers through the page's controls.

## Wrapper by wrapper (Obs, main `a289770`)

Under the entry's own rule, each result below is recorded as evidence rather than a hypothetical failure. Negatives are wrapper-local; the shared guard/onChange boundary is covered after the list.

- `handleAction` (`:464`): one statement, `this.guard(() => this.performAction(action))`. No wrapper-local statement outside the guarded operation, no independent mutation, and no wrapper-local dependency capable of throwing.
- `togglePause` (`:528`): one statement outside the guarded boundary - the argument read `this.state === GameState.playing ? PlayerAction.pause : PlayerAction.resume` - then it delegates to `handleAction`. The read is a plain field access: no mutation, no wrapper-local dependency capable of throwing.
- `softDrop` (`:532`): one statement outside the guarded operation - `this.isConfirmingNewGame = false` - an independent state mutation applied before `guard(() => this.dropTetromino())` runs. No other wrapper-local dependency capable of throwing sits outside the guard. See the scratch run below.
- `cancelNewGame` (`:538`): its only mutation sits inside the guarded operation.
- `storageChanged` (`:175-177`): public and called by the page when another tab changes storage. It invokes no guarded boundary: it clears the `storedIsSessionSaved` read cache, and the next `isSessionSaved` get re-reads storage (`:159-162`). A one-field cache invalidation, no dependency capable of throwing.

The input controller also runs `softDrop` from its own page-side repeat timer (`inputController.js:291-296`); that timer is outside the engine scheduler.

## Whether an exception before or after the guard can leave state changed (Obs)

- `handleAction`, `togglePause`, `cancelNewGame`: the wrappers mutate nothing outside the guard, so their wrapper-local statements hold no such path.
- `softDrop`: the flag clear lands before the guard. Reachability, from the source: the flag is set only at `performAction:480`, only while paused; while paused the guarded drop returns at once (`dropTetromino:249` does nothing unless playing); so in the only state where the clear has an effect, the drop cannot fault. While playing, the flag is already false and the clear is a no-op. An invariant fault could still stop a paused game during the call, but that path runs through the guard, not through the wrapper's outside statement.
- `storageChanged`: the clear cannot throw and leaves no game state changed; it invalidates a read cache.
- Shared post-operation boundary: each guarded entry ends in `guard()` (`:392`), which runs `runChecked(operation)` and then calls `this.onChange()` (`:393-394`) - the page-supplied callback (`script.js:14`) - with no catch. A page callback that throws therefore escapes to the wrapper's caller after the operation landed. This is one shared dependency, not a wrapper-local statement; F19 records the deliberate choice to leave telling the page to redraw outside a catch.

## Scratch run: the outside-guard statements and the shared onChange boundary (Obs, one indicative run)

Method: two scratch tests outside the repository (raw capture: `entry-wrapper-softdrop-run-raw.txt`), main `9db0855f` on a scratch copy - `public/` is byte-identical to `a289770` (verified by an empty `git diff` over `public/`, `test/`, `e2e/` and `package.json` between the two commits). All assertions pass:

- Paused with the New Game question open, `softDrop()` clears the flag, the game stays paused, the board is unchanged, the pending timer count is unchanged, and no fault is recorded.
- While playing, the flag is already false; `softDrop()` performs a real drop (asserted: the falling piece moved) and the clear has no observable effect.
- A page `onChange` callback that throws escapes `guard()` to the caller of a New Game action, after the operation landed: the state was `playing`, no fault was recorded, and the gravity timer was pending.

## Limits

- Local Node 22.23.3 is indicative, not authoritative; CI runs Node 26 or newer. One local run; the scratch tests change nothing.
- The source inventory is a pattern search of `public/`, `e2e/` and the caller type, not a completeness proof.
- The browser suite was not run; browser-side coverage here is a source reading of the committed specs only, with no run evidence.
- The reachability reading is a source argument for the named methods and states, not an exhaustive proof over every caller.

## What this record does not do

- The Entry-wrapper cases entry keeps its Candidate state; this record classifies nothing.
- It establishes no requirement violation and no implementation defect.
- It proposes no fix, no test change, and no requirement change, and it moves no phase.
- It asks for no owner decision.
