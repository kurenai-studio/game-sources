# Code Writes and Safety Checkpoints

Inspected source locations and conditional failure observations.

This record checks where the code writes state and what happened at selected failure checkpoints. It does not prove that every writer or runtime route is covered.

The source is main. Its public tree remains identical to the D43 scoped source. These are direct static reads of actual fetched source bytes. There are no repository edits, execution, tests, model author contact, rule adoption, or finding classification.

W01-W21 and W25-W33 anchor groups are checked. Direct static anchors for W22-W24 and W34-W35 are checked below. Their full native-focus, alias, reachability, and category relations remain unproved. No full writer exhaustiveness or runtime proof is claimed.

## Static results

### W01/W02: construction and spawn

Constructor and factory/piece spawn writes match the cited lines. IC RAF registration at112 sits outside its callback try. Concrete starting values do not prove semantic opening validity.

### W03-W05: action and dialog cancellation

The performAction A10 clear at468 is inside the GM guard. The softDrop clear at528 is before guard529. The cancelNewGame clear at535 is inside the guard. The onChange call at391 remains outside the runChecked catch.

### W06-W09: reset, load, pause, and Resume

Actual writes and line anchors match. Accepted load216 uses resetLockDelayForNewPiece308/309, not saved reset/lowest restoration. Resume499 calls landIfResting; pieceLanded280 uses >=15. The source's expected count15/count16 distinction remains D18 B9.2 line45.

### W10-W14: movement, rotation, gravity, and HardDrop

Movement position554 and rotation state145/position146 precede the outer check. Lowest helper300-310 records the box row. Gravity callback364 clears its handle before drop; drop245 has a mode gate. Harddrop542 assigns the ghost position, then locks. This is static correspondence, not model agreement.

### W15-W18: lock, board, hold, and reset

Lock callback267 calls lock without a mode guard. Its conditional state check controls only gravity restart268. Helpers317-350 contain board, row, score, highscore, queue, and spawn effects. Hold559-580 and reset helpers match their citations.

A failed-cancel counterexample must honor the actual source's scheduler-failure assumptions. It cannot assume an arbitrary firing after a successful cancellation.

### W19: failSafe

failSafe sets mode437, then stops/cancels at438-439 before pushing the fault and calling onFault. Only reporting blocks are caught. Controller repeats are not referenced here. Required visible-message/output handling and failedcancel cutpoints remain evidence gaps.

### W20/W21: save and storage events

Save payload221 precedes eligibility222. The eligibility setter catches flag writes internally. storageChanged175 sets cacheundefined: it invalidates the cache, but does not prove that the cache models the separate A16 session lifetime. Cross-tab storage event553 invalidates and redraws without a GM guard.

### W25-W29: controls and repeat timers

Alias120 occurs before held-set126/127. The control's own writes have no GM monitor.

startMoving writes movement259, clears260, performs GM action261, and registers270. It reissues at268 after GM action267. Repeat stop264 performs no GM check. Soft timer291's callback checks mode292/stops293 before GMsoftDrop296.

releaseAll clears through stop calls306/307, then sets/clears308-311. A throwing cancel may prevent later clearing. No failure trace was run here.

### W30-W33: drag and visibility

Drag begin433-436 precedes capture437. Pointermove's mutable anchors/offsets and inner GM operations match. endDrag488 does not read final client coordinates; it resets after inner rotation489. Hidden reset546 precedes optional GMpause547. These anchor checks do not prove tap/excursion or combined visibility-frame correctness.

### W22-W24: focus and dialog routes

SC226-229 shows/closes the dialog. HTML64-73 contains Cancel autofocus69. SC528/529 queries activeElement and focuses a clamped button. SC531 clicks only a focused question button.

No focusin/focusout handler or explicit A11 field was found in these source files. Browser focus behavior, initial focus latency, Tab/accessibility/pointer routes, and visual highlight still need runtime evidence.

### W34-W35: calls, copies, and mutable values

A direct scan of shipped SC/IC manager calls found handleAction, softDrop, togglePause, cancelNewGame, storageChanged, getters, and public field reads. It found no direct GM lock/hold/reset helper call. This is a two-file scan, not universal reachability proof.

Tetromino.copy45-52 shares position and rotation/kick arrays. Ghost353-356 replaces its copied position, not the current piece's position. Session parse builds new board cells90 and built-in active/waiting pieces; load then assigns accepted pieces.

Fresh value objects are not runtime-immutable. Position11 returns a plain object. External mutation possibilities and shared geometry references remain relation gaps.

## Independent static review limits

The independent spot review hashed the first six snapshots and checked about forty-five specified line anchors. It did not compare those hashes to the fetched commit, check all clauses, verify helper317-350/guard structure/source adoption, or run failures. Coordinator attribution to fetched Git bytes is separate.

A later bounded fidelity review checked W22-W24 focus/ghost anchors and found them matching. A later optional gap check hashed the actual session/position snapshots. It inspected session parse line90's fresh cells and position line11's plain-object/no-freeze anchors.

Full W34-W35 external-mutation, shared-geometry, and reachability relations, plus the complete two-file call scan, remain unreviewed. Conditional cutpoints received the separate state-worker reproduction/source-scope review recorded below. The document-fidelity reviewer did not rerun them.

## Distinctions retained

Private source checks do not change merged D43 pending wording or certify claims. Concrete absence of a field is not a proven absence of semantic representation. Ordinary gameover semanticabsence is not mandatoryclearing; fault-retained contents have a separate projection. A guard after an inner action does not establish an outer control/touch commit or all-state frame.

## Actual source identities

public/game/gameManager.js SHA256 31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea
public/game/inputController.js SHA256 7454a3c23b9de0acb152fe76bedab74bb4a604ac62ca11d41ff5ee12e3ed27e2
public/game/tetromino.js SHA256 d99c1bd6cb4a9e255b9ef2840264281e46a9665dcb30f66c6b45e654d1654bfe
public/game/tetrominoFactory.js SHA256 25e1da6c0b1992b0317aef7025fb7030803a8fd20e649a45eb2ddeaa166ae8b4
public/index.html SHA256 96f7fb5b112d6890b33b0f38d51e2bb47fe2289875354559a82ab4e036ab85c1
public/script.js SHA256 59fcb3343f35d0022c739cce82c5c9601a9e3bc354a9dc991eb1660c4e599ad4

public/game/session.js SHA256 54acbea460218f0e0a827619eae51e265461fe9ac6575dc8bf48727f6483049b
public/game/position.js SHA256 e598b5ea4ff8f125bcb405b35ab6fb21d64e1fc6fc623a862b46ca839c2b6144
public/game/gameState.js SHA256 4d4d88f18f8d2335fac4104e746b972214991df8b1c6e72e0cc5d8d12cb30878

## Conditional checkpoint observations and correction

These used scratch Node22 adapters. They do not claim native browser failure or public-action reachability. Before running, the cases and expected source domains were written in cutpoint-plan.md. The initial plan's silent-cancellation attribution was too broad. This record corrects it and preserves its artifacts.

### Move: onChange throws

The piece moves from column4 to3. The game stays playing, gravity remains registered, and there are zero faults/reports. The exception escapes. GM guard391 calls onChange after runChecked. Whether this callback failure applies to the SAF-3 boundary remains open.

### HardDrop: factory and gravity-cancellation failures

The factory throws during HardDrop, then gravity cancellation throws during failSafe. Mode becomes over, four blocks remain, gravity is outstanding, and there is no fault record/report. The cancel exception escapes. This is conditional T3/U3 failure evidence, not a claim that native clearTimeout throws.

### Original silent no-op cancellation cases

Both cases return normally, then deliver a retained lock callback while paused or over. The board changes from zero to four blocks, and the concrete piece changes. D22T3 trusts a successful cancellation not to fire. These adversarial success-return cases fall outside that trust assumption. They show no entry-mode gate, not firm U3/U4 violations.

### Reviewer throwing-lock variant

The separately preserved variant was reproduced with only imports changed. Both throw-all and throw-lock-only cases have modeover, zero blocks, and zero faults/reports after failSafe escapes. Delivering the actually retained lock callback makes four locked blocks and a new concrete piece while still over. This is within U3's conditional failed-cancel fault-stop domain. The throw-all delivery also escapes cancel; the throw-lock-only delivery does not.

### Successful pause cancellation control

No lock firing is retained, and none is delivered.

### Injected prestate and retained snapshots

The resting prestate is built-in O injected at row18,column4 on an empty board, with resetcount0 and lowest occupiedrow19. It is a declared valid semantic prestate, not proved public-action reachable. The fault case invokes the real guard with an injected throwing operation. Full board/piece/mode/count/lowest/timer/effect/report snapshots remain in the manifest's artifacts.

## Independent checkpoint review

The reviewer reran the five original probes. After changing import paths to its source copy, it obtained byte-identical JSON and ran the throwing-lock variants. It checked source/scope and supplied the silent-cancel correction.

It did not rerun the static record or establish native failure/public reachability. Its source comparison to0f4e510 was modulo a reconstructed trailing newline. Actual Git-byte/source identities are the coordinator's separate evidence. No conditional result is a formal finding or certification.
