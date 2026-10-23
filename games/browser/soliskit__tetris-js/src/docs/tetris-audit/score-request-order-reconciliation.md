# Score Checks and Gravity Requests

The order of score validation and timer requests under stated assumptions.

The engine's action guard checks the score after the action returns. Some actions can request the next gravity timer before that check. A later invalid-score stop therefore does not establish that no invalid-score request was made.

This is a source-order reconciliation for independent review, not a new executed finding or a claim that ordinary play creates five full rows. It follows the published score-writer and gravity-request maps. No code, test, CI, requirement or finding-status change is included.

## Source and premises

Pinned main; `public/game/gameManager.js` SHA256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`.

Assume ordinary stable objects, getters, built-ins and a scheduler that returns from cancellation and registration without throwing. A row-clear input has more than four full rows after the piece lock. The existing score table has only keys 1 through 4, so `clearFullRows` assigns NaN at line348. This case was already recorded in the row-clear source evidence and P3-C270. It is not a new discovery.

Further suppose generation and any nested resting-piece handling finish with state still playing. That premise is important: generation can stop the game, throw or recursively lock a resting next piece. This packet does not construct a complete independently valid fixture or prove ordinary legal reachability. The released parser rejects full rows, so ordinary accepted Continue is not an entry to the selected preexisting-full-row case.

## Common order

`handleAction`459-460 and `schedule`382-384 enter `guard`. `runChecked`398-407 calls the whole operation first, then `findInvariantViolation`. The score rejection at418 is therefore a post-operation check.

`lockAndSpawnNext`318-325 locks, clears rows, generates the next piece and, if rows cleared and play continues, attempts a save. Only after it returns do the enclosing Hard Drop, lock callback, drop or Resume paths decide whether to call `startGameLoop`.

For ordinary Math and numeric NaN, `level`118-120, `standardDropInterval`178-180 and multiplication in `startGameLoop`359-367 remain NaN. The schedule wrapper forwards that NaN as the `setTimeout` argument. This is a JavaScript source deduction, not a native timer-conversion or delivery measurement.

## Caller partitions

| Caller following the selected clear | Request before enclosing score check | Boundary |
|---|---|---|
| Hard Drop539-547 | If `lockAndSpawnNext` returns still playing,545 requests before the action returns to `runChecked`. | Ghost computation and earlier lock failures may prevent the selected clear. |
| Lock callback264-269 | After its clear/generation/save chain returns still playing,268 requests before its scheduled operation's check. | Actual callback delivery and outstanding-resource identity remain separate. |
| Drop245-258 | If `landIfResting` takes the count-limit immediate-lock branch and returns still playing,255 requests before the check. | A non-locking drop does not reach this score writer. |
| Resume496-501 | A resting count-limit lock may clear rows; if play continues,500 requests before the check. | Resume without that lock does not reach this writer. |
| Hold560-580 | Incoming/next-piece resting handling can conditionally enter a nested lock; if that returns still playing and Hold finishes,579 requests before the check. | This is conditional nested source composition, not a legal Hold witness. |
| Move/rotate550-558,582-589 | No explicit fresh gravity request after their reset-limit lock. | A nested generation/resting chain can add other requests, and an earlier timer may remain pending. Neither is discharged by this row. |
| Direct `clearFullRows`334-351 | The helper itself makes no gravity request and no invariant check. | External composition is outside this specific helper relation. |

Confirmed New Game resets score to zero before its request. It does not pass through the selected row-clear writer on its normal reset path. A call to `startGameLoop` with externally edited score is a different admission case.

## Safe stop is later and conditional

After an ordinary enclosing operation completes, the monitor rejects NaN if the earlier board-shape and queue-length checks pass. Malformed prefixes can instead return an earlier violation or throw during the check; the score-specific rejection reason is not universal. `failSafe`436-452 sets game over, cancels gravity and lock handles, then tries fault retention/reporting. If both cancellations succeed under their scoped scheduler premise, this later path cancels the newly registered timer. That does not erase the earlier registration argument.

Cancellation failure can interrupt safe stop before remaining cancellation/reporting. That existing failure-containment issue is separate from the requested-value argument. No retained callback firing or stopped-state mutation is asserted here.

`saveGameSession`219-225 can also run before the check. Its call is not evidence of a valid saved payload; serializer validation and failure/withdrawal effects need their own relation. This packet makes no new saved-content finding.

## What this adds

The published numerical bound remains conditional on a finite nonnegative integer score at the request. Post-action score rejection alone cannot supply that premise at all earlier request points. The selected source composition supplies a concrete conditional ordering reason, not a whole F22/PLY2 counterexample.

A broader claim still needs independently valid input admission, exact route composition, generation/resting premises, request applicability, scheduler behavior, storage/failure effects and claim-specific criterion review. Ordinary-history row-count induction and unrestricted valid snapshots remain distinct. Phase4, finding classification, correction and certification gates remain open.
