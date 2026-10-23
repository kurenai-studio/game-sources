# Stopping After a Fault

What the inspected stop path does when timer cancellation throws.

This record follows the source path when timer cancellation throws during fault stop. It is source deduction and a conditional frame relation, not a fresh runtime trace, native cancellation proof, classified finding or phase closure.

## Expected relation

SAF-3, D16 F2, D22 T1/T3, D23 U3/U4 and D21 S3/S6 require fault stop after an ordinary operation/check throws. Mode becomes over. Successfully cancelled resources do not fire; a retained firing after failed cancellation must not change the stopped game. Player notice and the observable signal remain required, and prior independently good save contents are kept. This does not imply rollback of completed persistence effects or ordinary invariants for all retained contents.

## Inspected exceptional path

The actual schedule wrapper calls guard, which calls runChecked and then onChange. runChecked catches ordinary operation/check throws. The failSafe call inside that catch is not protected by a second catch. The invariant-violation branch also calls failSafe outside the try.

failSafe sets mode over, calls stopGameLoop, then cancelLockDelay, then independently caught record/report attempts. Both cancellation functions call clearTimeout before clearing the corresponding handle. If clearTimeout throws during fault stop, a gravity-cancel throw exits before lock cancellation and both record/report attempts. A lock-cancel throw exits after gravity cancellation but before both attempts. The outer onChange call is not reached. This call therefore does not reach the page redraw that updates the Game Over display. This escape also precedes its onFault attempt; the default onFault reports to the console. These are path-specific effects, not a claim that no player-notice wiring exists anywhere.

A throwing clear call leaves its corresponding non-null handle unchanged under this statement order. Whether the retained resource actually fires is a separate scheduler/native fact.

This is straight-line exceptional-control-flow evidence under a stated throwing-cancellation premise, not an observed native failure.

## Retained delivery and storage frame

The gravity callback clears its handle and calls dropTetromino, which returns outside playing mode. Its guard/check/onChange path can still encounter cancellation failure again. The lock callback lacks the corresponding mode guard before lockAndSpawnNext, so inspected source permits entry into board/clear/queue changes while over. Actual retained lock delivery and pre/post field changes are not demonstrated here. Fault timing and resource-ledger binding remain necessary for an executed witness.

The default failSafe contains no storage write, read, withdrawal or serialization. saveGameSession at lines 219-226 calls setItem with serializeSession(this), then sets isSessionSaved true on success or false on a caught failure. That save path is separate from failSafe. The eligibility setter at lines 164-171 invalidates its cached eligibility through storageChanged, separately attempts a stored flag write and ignores its failure. Its getter later rereads the flag when the cache is undefined. This is not an independent in-memory true/false assignment. Persisted payload contents and stored eligibility are distinct. Conditional on an independently valid successful prior payload and external callbacks not writing storage, preservation follows from no writes on the inspected stop path even when it escapes. Arbitrary injected callback effects need their own ledger. A bad new payload is not a prior-good control.

The finite report-escape and conditional default-storage relations are mapped as stated methods with source evidence. Actual delivery, callback effects and broader fault-position domains remain separate. No universal safe-conversion certification follows.

## Source binding

Historical public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77`. This record describes the inspected snapshot, not the current source. Inspected `public/game/gameManager.js:245-269,312-324,358-408,436-455`; SHA-256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`. Default callback frame at lines 70-89 is separate from arbitrary caller-injected effects.
