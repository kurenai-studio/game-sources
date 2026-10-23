# Soft Drop Restarts Gravity

Compare the piece movement and timer effects with the independent model.

This held check compares production with the independent model when a soft drop moves the piece down one row. It covers only the successful-fall subset of PLY-3, with O5/O8 source and oracle separation. It is not a full bag/timing/landing proof, classified finding or phase closure.

## Independent expected relation and adapter

The requirement says a soft drop restarts gravity. For a successful fall, the expected relation moves the current piece down one row and restarts the gravity schedule. The frozen independent model's successful soft_drop/_fall_one relation increments gravity_restarts once. That counter expresses the model restart event; it is not a native timer, cancellation log or elapsed-time measurement.

The production adapter compares the piece row and column before and after the drop, outstanding scheduler entries, and actual cancel/request effects. It does not treat the concrete timer handle as the model counter or infer cancellation from handle truthiness.

## Held input and actual result

The held production case starts a game with a declared O-only factory and successful memory storage. The scheduler is a nonfiring map/effect ledger. The selected O piece starts at row zero, column four. One softDrop moves it to row one at the same column while mode stays playing and no fault is recorded. The old outstanding gravity entry is cancelled and replaced by one request for 700 ms at score zero. Exactly one gravity entry remains outstanding and no lock-delay entry is present in this successful-fall case.

The corresponding model case supplies an O opening queue, O spawn at row zero/column four and an explicit full permutation shuffle input. It moves the O piece down one row and changes gravity_restarts from zero to one. The held model output marks the trace defined and the before/after state checks valid. These fixture choices are declared inputs, not new adopted rules. The production O-only factory supplies no evidence about shuffled-bag correctness.

The first model harness attempt failed because it called valid_state as a Model method. The corrected held version uses the module-level error-list predicate instead. No passing result is claimed for the failed attempt. This record reads back held production and model artifacts. It is not a new execution or independent verification by every reviewer.

## Limits and separate observation

The source calls landIfResting and, while still playing, startGameLoop even when the piece cannot fall. A fall that ends resting can start lock delay or lock/replace the piece. Those resting, blocked and fall-ending-resting branches are excluded from the successful-fall relation here. The later held floor-blocked soft-drop observation also cancels/replaces gravity, but the model's blocked restart reading remains unspecified. It is not treated as a defined model differential result. This record does not prove every field's frame, opening queue/bag correspondence, all reset-count/landing branches, native timing or universal gameplay. Requested delay, actual cancellation effects and the model restart counter remain different evidence.

## Source identity

The GameManager file at public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77` hashes to `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`, matching the held production source. SoftDrop at `public/game/gameManager.js:527-529` calls the guarded drop route at 245-258; startGameLoop at 359-367 cancels/reissues gravity. The independent model revision 6 SHA-256 is `f958f910a7a8ae02e2abd4a25a82f4f6127d5ff41440d45008cb92e4b63e93d2`. Exact held input/output bindings remain privately recoverable; no executable artifact or private trace is published by this record.
