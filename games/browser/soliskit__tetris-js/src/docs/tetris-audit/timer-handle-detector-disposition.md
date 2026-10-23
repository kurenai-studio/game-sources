# Timer Handles and Outstanding Firings

A handle comparison is not a resource-history check.

The engine checks whether a timer handle is null. The adopted rule instead asks whether a future firing actually exists. Under the declared injected cases below, an undefined handle with no scheduled firing passes a playing-state check that should detect missing gravity or lock delay. These are source comparisons, not new timer executions or claims that the browser normally returns undefined.

Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md). No correction, test, model, CI or requirement change is included.

## Independent resource meaning

R1 B13 defines a running resource as an outstanding scheduled firing. A fired or canceled request is not outstanding. Handle spelling is not the criterion. While playing, gravity must be running, and lock delay must be running exactly when the current piece rests. Paused and ordinary game-over states have neither resource running. D23 U4 supplies the gravity, lock-delay and held-repeat scope and required firing checkpoints.

The original blueprint Q3 method selects representative undefined/null/present handle combinations in playing, resting and stopped modes. It does not require every Cartesian combination or establish that undefined can arise from the ordinary native scheduler. The admitted injected detector comparison and the ordinary provider/writer relation are separate claims.

## Declared inputs and independent answers

All rows use ordinary stable objects, unmodified built-ins, a dense empty 20 x 10 board, score zero and three real upcoming pieces. The O piece uses the fixed adopted 2 x 2 offsets. At box position (0,4) it fits and can fall, so it is not resting; at (18,4) it fits and cannot fall, so it rests. The resource column is an explicit fixture premise, not a conclusion drawn from the handle. No callback is delivered, no persistence effect occurs and no custom getter or alias changes the state during the check.

For these selected timer predicates, G means gravity and L means lock delay. A present handle is an ordinary non-null, non-undefined value paired with the named live request where the row says live. No assertion is made that the remaining fields certify a full semantic history.

| Mode and piece | Handles G / L | Actual outstanding requests | Required timer-condition result | Source monitor result |
|---|---|---|---|---|
| Playing, nonresting O | undefined / null | None | Reject: gravity missing | Returns null |
| Playing, nonresting O | null / null | None | Reject: gravity missing | Gravity-stopped reason |
| Playing, resting O | present / undefined | G only | Reject: lock delay missing | Returns null |
| Playing, resting O | present / null | G only | Reject: lock delay missing | Resting-with-no-lock reason |
| Playing, resting O | undefined / undefined | None | Reject: both missing | Returns null |
| Playing, resting O | present / present | G and L | Timer conditions satisfied | Returns null |
| Paused | undefined / undefined | None | Timer conditions satisfied | Timers-running reason |
| Ordinary game over | null / null | None | Timer conditions satisfied | Returns null |

The positive rows check only the stated timer conditions, not whole R1 validity, successful provider behavior or legal history. The paused row's source rejection illustrates a handle/meaning mismatch but is not a claim that a valid production paused state normally carries these handles.

## Source derivation

At main, unchanged public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77`, `findInvariantViolation` checks board sizes, queue length and score before its mode branch. Those prefixes succeed under the declared fields. In playing mode it checks current-piece fit, then:

- Gravity is rejected only when `gameLoopTask === null`. Undefined is not null.
- A non-null lock handle off the surface is rejected. A resting O avoids that branch.
- A resting piece is rejected only when `lockDelayTask === null`. Undefined is not null.

Thus both missing-resource witnesses and the both-undefined resting case return null. The paired null controls return their named reasons. Outside playing mode, either handle not equal to null returns the timers-running reason, even in the declared no-request fixture. These are finite predicate deductions; no actual return log is created here.

The independent expected rejection is the explicit SAF-4 gravity/lock condition interpreted through B13, not a production monitor agreement. Missing lowest/count history prevents a full-state certificate but does not turn an explicitly absent required resource into a running one.

## Ordinary provider and writer relation

The constructor sets both handles to null. `startGameLoop` first cancels the old gravity request, then assigns the value returned by schedule. The gravity callback clears its handle before dropping. `startLockDelay` cancels the old lock request before assigning a new returned handle. Successful stop/cancel calls clear the corresponding handle to null. A thrown cancellation can exit before that clearing; a registration that retains a callback and then throws can leave the new handle unknown. Those failure compositions already have separate source and historical evidence.

The default scheduler delegates to global setTimeout/clearTimeout. Under the adopted successful-feature/provider semantics, ordinary native handles are not shown here to be undefined. A custom dependency or direct field injection does not prove ordinary native creation. Conversely, a non-null handle by itself does not prove that a request remains outstanding: the ledger and delivery/cancellation history determine that relation.

No new platform source is adopted, and no scheduler is run. Failed cancellation, retain-then-throw, fired-request handles, every controller resource and all direct writer/alias paths remain separate.

## Historical evidence stays separate

The earlier Q3 record describes a 20-row handle/registration-label comparison, with direct and guarded calls to the same production monitor. Its supposed semantic result was a predeclared literal in the row table; it was not independently computed from a complete resource model. Map labels were not executable callback retention or native timer identities. Its timeout pipeline result did not prove child completion. Exact original ledger, harness and result bytes are not recovered in this continuation, so this draft neither upgrades those rows nor reports a fresh reproduction.

The current argument is independently stated source/criterion comparison at the pinned tree. It supplies no new process receipt, native execution, original raw recovery or actual provider-failure outcome.

## Proposed narrow disposition and limits

For independent review: Confirmed by conditional source argument for the explicitly admitted injected detector domain in which an undefined gravity or lock handle has no corresponding outstanding request, but the selected playing boundary returns null. The both-undefined resting case is another composition of those same predicates, not an added native failure claim.

Unclosed: all Q3 partitions, native undefined-handle creation, full resource correspondence, every writer/checkpoint/failure composition, held-repeat coverage, complete SAF-4/R1 and Phase 4 certification. A correction and regression/collateral proposal needs its own approval. Successful documentation publication cannot authorize production or test changes.

## Source pins

`public/game/gameManager.js:65-68,93-100,263-288,306-312,358-372,382-432`: SHA256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`. Geometry: fixed adopted O offsets in R1 B2; B13 resource meaning; D22 T3; D23 U3/U4; blueprint section 4.8 Q3. Predicate pins and earlier narrative identities are not execution receipts.
