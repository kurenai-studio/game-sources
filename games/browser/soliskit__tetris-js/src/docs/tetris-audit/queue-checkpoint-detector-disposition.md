# The Queue Check Can Miss Invalid Pieces

Source comparisons for declared malformed queues at safety boundaries.

The safety check counts the next pieces but does not check what is in those slots. A three-slot queue containing no real pieces can pass. This conflicts with the adopted requirement to check three valid upcoming pieces at each required safety boundary. The comparison below is a source argument for an explicitly injected malformed queue, not a new game run or evidence that ordinary play creates it.

Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md). This draft confirms no finding until independent review and publication gates pass. It changes no code, tests, model, requirements or CI.

## Independent meaning and admitted input

The published queue decision requires three valid semantic upcoming pieces. R1 B3 rejects missing entries, sparse collections and values of another type; B7 requires three valid pieces in every mode. Waiting pieces do not acquire the current falling piece's live position, board-fit or timer rules. The original audit blueprint's Q1 method explicitly selects `[null, null, null]` and a sparse length-three array for invariant-boundary comparison, with ordinary writer creation examined separately.

Take a completed ordinary opening game-over state with its dense 20 x 10 empty board, score zero, null gravity and lock handles, no pending confirmation and successful ordinary dependencies. Replace only the upcoming queue with one of these declared scratch inputs:

- A dense list `[null, null, null]`. Its three values are not semantic pieces.
- A sparse list of length three, with no entries. Length does not supply its missing semantic entries.

Both fail the independent queue criterion. The current falling-piece fields have no semantic falling-piece value in ordinary game over; this argument does not borrow a paused or playing piece-history certificate. No custom getter, replaced monitor, storage change, callback delivery or external actor is included.

## Exact source result

At source main, the production tree remains `1e09ad61c19e0b235a231ad8810dae176be4ea77`.

`findInvariantViolation` checks the board dimensions, then evaluates `this.nextTetrominos.length !== UPCOMING_COUNT`. Both declared inputs have length three. No queue element is visited or classified. Score zero passes the subsequent score predicate. In game-over mode the remaining resource condition checks that both engine handles are null. Under the stated unchanged opening fields, the function returns null for either malformed queue.

An injected boundary check therefore misses invalid upcoming content. The governing rule calls for checking three real pieces, not merely successful downstream use of those pieces. No attempted `spawned` call or natural queue fault is needed for this specific detector comparison. A later next-piece operation could fail for another reason; that does not supply the earlier required check.

This is inspection of the finite source predicates, not an executed return value. No historical Q1 output or process receipt is claimed recovered here. The expected rejection comes from the adopted criterion, not the implementation's own validator.

## Ordinary writer relation

The inspected constructor and New Game fill the queue through three factory draws. The built-in factory generates fresh canonical pieces from its seven-kind inventory under its valid random-output and ordinary-object premises. Next-piece generation shifts the current queue head and appends another draw. An already malformed queue may fail during that consumption before its later checkpoint; this does not show an ordinary writer created it.

Continue first checks a list of length three and then visits each waiting entry through `parseWaitingPiece`, which selects built-in geometry by known kind/color. Null entries and holes do not become accepted queued pieces on that inspected successful reconstruction route. Whole accepted-save validity, complete history and failure prefixes remain separate.

These named writers supply conditional successful-path preservation evidence. They are not every-writer or alias-exposure proof, and do not replace runtime checking under the selected detector extent. No shipped ordinary path creating the two malformed inputs is established by this argument. Custom factories, external aliases and arbitrary object-shaped queues need separate comparisons.

## Proposed narrow disposition

Confirmed by conditional source argument, if independent review accepts these premises: the explicitly admitted dense-null and empty sparse length-three queue inputs pass the selected ordinary-over invariant boundary despite the requirement to check three valid upcoming pieces.

Not Established here: ordinary malformed creation, all Q1 partitions, queue behavior in every mode, every writer/checkpoint/failure composition, native execution, complete R1 or SAF-4 certification. F21's separate board-reachability gate and the current-piece Q2 disposition are unchanged. A correction and its regression/collateral review require their own approval; this finding cannot authorize them.

## Source pins

- `public/game/gameManager.js:93-126,182-195,230-242,397-432`: SHA256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`.
- `public/game/tetrominoFactory.js:91-110`: SHA256 `25e1da6c0b1992b0317aef7025fb7030803a8fd20e649a45eb2ddeaa166ae8b4`.
- `public/game/session.js:123-126,163-169`: SHA256 `54acbea460218f0e0a827619eae51e265461fe9ac6575dc8bf48727f6483049b`.
- Criteria: `docs/tetris-audit/queue-piece-check-decision.md`; R1 B3/B7; blueprint section 4.8 Q1. Source identities do not authenticate historical execution.

## Later partitions: object, numbers and one detector group

Independently reviewed source comparisons extend the same mechanism to more named inputs. They are additional source evidence for this disposition, not a new reproduction, a separate defect, an ordinary-writer creation claim or a certificate for all of Q1. The original dense-null and sparse inputs and their status are unchanged.

### Object and number inputs

Keep the same completed ordinary opening state, successful plain providers, unchanged board, score and null handles, and no outside actor. Replace only the upcoming queue with a plain `{ length: 3 }` or a dense `[1, 2, 3]`. Neither is an ordered list of three valid semantic pieces. Both expose ordinary numeric length 3, so by source control flow they pass the count-only monitor and the later predicates, with no iteration or piece method. No custom length getter, Proxy, replaced monitor, storage write or piece method is introduced. The current Continue parser rejects a non-array queue and rejects entries that are not objects, so these shapes are not reconstruction routes; parser rejection does not replace the runtime check.

### One detector group

With the ordinary opening state unchanged, every queue whose ordinary length access completes with numeric 3 takes the same branch and the same later predicates. That includes valid canonical lists, which are supposed to pass, so the shared result alone is not a defect. The group describes what the detector looks at, not semantic validity. Each invalid partition needs its own witness. Throwing length access, getters, Proxy, reentrancy and changed surrounding state are outside this argument.

### Empty-geometry queue

A dense queue of three ordinary generic recognized-yellow Tetromino values with zero-cell geometry (`[[[]]]` rotations, `[[]]` kicks) is a further malformed partition. Its length 3 passes the monitor. A recognizable color does not establish the adopted four-block O geometry. No constructor run, piece method call, current-piece history or earlier run receipt is borrowed. Current Continue reconstruction selects built-in geometry and does not install supplied rotation matrices.

### Still open

Other malformed canonical representations, ordinary creation, every mode and writer, failure histories, native execution and full Q1, R1 and SAF-4 remain open. No code, test, requirement, model, CI, settings, cache, storage or release change.

Evidence: reviewed source packets `Q1-object-and-number-partition-extension.md` (SHA-256 `84088f02d83dfff80875e07142fdb002493770ebcb755665af723a0c3c8f11f4`) and `Q1-length-three-predicate-equivalence.md` (SHA-256 `cec8b73dbec439547904abd5c0027e7e21fbeb1e4da00a72fdf5f9540eede8d8`). Reads were not one atomic snapshot and no run receipt is claimed.
