# Identity and substance match for the three appendix entries not located in the union

Read-only grounding record. No code, test, requirement or CI change. Prepared by the auditor. This record adopts no status word, closes nothing, classifies no finding, and changes no roster; it records, for each of the three blueprint appendix entries that the coverage sweep did not locate in the crosswalk's named-source union, where their substance actually lives in the audit's records and what identity or supersession relationship is established. It asks for no decision.

## Method and limits

Each entry's text was read in `audit-blueprint.txt` (the carried-forward "Current audit finding record" section). Substance was matched across DECISIONS.md, the Phase 1 decision records, the Phase 3 obligation and writer-frame records, and the Phase 5 records (Obs). A match is reported as one of: a candidate record of the same kind covering the same case, an adjacent requirement or trust-ledger record bounding the entry's question, or no match. Limits: word-based search can miss differently-worded records; a substance match is not a classification; whether the matched records settle an entry is the audit's classification step, which this record does not perform.

## Score (appendix: "Status: Candidate. Evidence Gap: possible.")

The entry: replacing `Number.isSafeInteger(score)` with `Number.isInteger(score)` in a scratch mutation permits unsafe integer scores; if the permanent suite does not detect the weakened predicate, the result is primarily a test-strength evidence gap unless a requirement violation is separately established; whether unsafe integers are valid scores is R1's question.

Substance records located:

- R1 B11 (`phase-1-r1-decision.md`): "In every mode, a whole number of zero or more, with no divisibility condition." The in-session semantic score domain.
- R1 B16 as amended: accepted saved-game scores and stored high scores are whole numbers from 0 through 9,007,199,254,740,991.
- The SCO-2 record (`phase-3-obligations-P3-C.txt`): assumption "score is a non-negative safe integer (GM:418, B11)"; limitation "Scores above MAX_SAFE_INTEGER are rejected by GM:418 and SS:160 (B11 sets no format limit, B3)".

Established relationship (Inf): no same-kind candidate finding record was located in the searched sources. The located records are requirement semantics (B11, B16) and a reviewed-argument claim record (SCO-2) that bound what a valid score is and what the implementation rejects; they do not state whether the permanent suite detects the weakened predicate, which is the entry's own stated evidence question. That evidence question remains open here.

## Scheduler fault cases (appendix: "Status: Candidate; classification depends on the O6 trust ledger.")

The entry's classification depends on the O6 trust ledger. The ledger substance exists and is recorded:

- `phase-1-trust-and-timer-scope-decision.md`, U3: if cancelling a timer fails while the game is stopping safely after a fault, a timer may still fire, but it must not change the stopped game; D22 T3 still applies to successful cancellation.
- DECISIONS.md D22 T3: a timer cancelled successfully is trusted not to run afterwards; if registering or cancelling a timer throws, the engine stops in the SAF-3 safe state and the fault is reported.
- `phase-3-O1-O8-obligations.txt`, the timer-scheduler ledger row: successful cancel prevents future firing; there is no registration/cancel success guarantee; a throw or failed cancel callback may fire but must not mutate the stopped game.

Established relationship (Inf): the trust ledger the entry references is recorded with explicit scheduler assumptions. No same-kind candidate finding record was located in the searched sources for the entry's fault cases, and this record does not determine whether the ledger's assumptions settle the entry's classification.

## Entry-wrapper cases (appendix: "Status: Candidate pending boundary inspection")

Positive substance match: `phase-3-writer-frame-checkpoint-matrix.txt` covers all three wrappers the entry names, each with status "Candidate mapping;Not Assessed implementation/frame/checkpoint claim".

- W03: `handleAction` (GM handleAction459-460->performAction464-520->guard389-407).
- W04: `softDrop` (GM softDrop527-530): "A10false528 beforeguard;drop guarded529", with the note "A10write occurs beforetry/check" and the claim "Pre-guardwrite independentlyneeds operation/frame/failure/commit mapping;trivial assignment notexception grant."
- W05: `cancelNewGame` (GM cancelNewGame533-537): "A10false535 withinguard."

The appendix entry records the same observation for `softDrop` (at 30e0085: `softDrop` sets `isConfirmingNewGame = false` before calling the guard, gameManager.js line 528; the previous audit's statement that all three wrappers contain only the guard call was wrong for `softDrop`). The matrix's A10 is the same flag (Obs).

Established relationship (Inf): the two records cover the same wrappers and record the same pre-guard write for `softDrop`; both are candidate-level (the appendix entry pending boundary inspection, the matrix mapping Not Assessed). Neither contradicts nor supersedes the other; the entry's classification remains open.

## What this record does not do

- It adopts no status word, closes nothing, and classifies no finding; the three appendix entries keep their candidate states.
- It changes no roster: the crosswalk's 53-ID union accounting and the coverage sweep's not-located result remain unchanged in the reviewed crosswalk and sweep records; this record asserts nothing about their publication state, which is verified separately.
- It asks for no owner decision and names no new audit phase, gate, or fix.
- It does not resolve whether the named-source union covers every finding the exit criterion means.
