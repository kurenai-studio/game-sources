# Landing and Moving Off a Ledge

Bounded model comparisons and recorded reset-count differences.

Production base, public-identical documentation main. Original comparisons use frozen model revision 4 without edits. Coordinator Node26; independent review Node22. No finding classification, production correction, model acceptance or closure.

The ambiguity labels model-reading A4 and A4b are model tags, not authoritative state item A4 (hold-used). Revision 5 was received as a separate author attachment. Revision 5 was frozen by its actual byte hash before comparison. Its pack-only source review and comparison review are separate from the D41 revision 1-4 record. No executable publication or merge is implied.

## Original revision 4 comparison

Thirty-one predeclared cases combine 25 orientations falling to the floor on an empty board and O moves onto/off a single support at counts 0, 14 and 15. All 25 floor landings agree. Five cases differ:

- Off the ledge at counts 0, 14 and 15: production increments to 1, 15 and 16; model keeps 0, 14 and 15. Both cancel the delay.
- Onto the ledge at counts 0 and 14: production keeps 0 and 14; revision 4 increments to 1 and 15. These are model-reading A4 source/model-mapping issues, not established production deviations.
- Onto the ledge at count 15: both lock at once.

The supplied O spawn (0,4) is a caller reading, not a unique normative choice, and affects only the matching post-lock case. An initial Undefined A2 attempt was discarded. It is not counted.

Independent pack-only review found model-reading A4 genuinely ambiguous: the source can be read as consuming a reset only when initially resting or when a move ends resting. Revision 5 exposes both readings through a caller choice or Undefined. Revision 4 evidence is not reattributed to revision 5. Later comparisons require their own frozen hash, domain and choice record.

## Separate frozen revision 5 comparison

Revision 5 bytes were frozen at `b7920735e8aebf82c63d7e1e91fb4cbed1b8a26ce6f2668530022a7f62a91156` before this comparison. A strict boolean caller preflight avoids its known truthy-choice harness hazard. The existing 31 input cases are run under absent, false and true choices. Absent choice yields 29 defined cases and two Undefined model-reading A4 traces; full state and random-source rollback were checked and those traces are excluded. False yields three off-ledge count differences; true yields the original five count differences. All 25 floor falls agree under the labeled model-reading A4b unchanged-count reading. Neither choice is selected because it matches production. Independent Node22 comparison review verified the frozen revision 5 source hash and reran all 93 rows byte-identically. The two Undefined cases passed full state/random-source rollback checks; only the count field differs. This is bounded comparison evidence, not oracle acceptance. Original revision 4 evidence remains separate.

## Separate frozen revision 6 comparison

Revision 6 was frozen at `f958f910a7a8ae02e2abd4a25a82f4f6127d5ff41440d45008cb92e4b63e93d2` before comparison. Its strict boolean choice checks fix the revision 5 truthiness hazard; all required boolean choices are preflighted by the harness because the model checks are lazy. The coordinator independently regenerated the 93 comparison rows using the separate revision 6 source. The JSON has the same bytes, size and hash as revision 5. The defined absent/false/true domain produces the same outcomes; the output was not copied. Independent Node22 review checked the source hash and code diff, regenerated all 93 rows byte-identically to the stored revision 6 and revision 5 outputs, and regenerated the production data. It also checked bad integer/string/list choices raise ChoiceError with exact state/random-source rollback. These are completed bounded checks; the matching output does not establish oracle acceptance. External storage callbacks still cannot be rewound, and other partial choices and exclusions remain.

## Public off-ledge reachability

A public trace uses New Game O, one hard drop, 16 soft drops onto the locked O, then 13, 14 or 15 surface moves and a move off the ledge. No fields are assigned by the trace. Independent review reproduced the outputs and checked the legal geometry.

- After 13 surface moves, the off-ledge move increments to 14.
- After 14, a further still-resting move consumes restart 15; the next off-ledge move increments to 16.
- After 15, the off-ledge move increments to 16.

All end playing and non-resting with the lock timer cancelled and zero production faults. B9.1 permits count 16 only while paused and resting. The 14/15 traces therefore support a strong bounded B9.1/count-16 candidate. Treating the 13-to-14 increment as a deviation additionally depends on reading a cancellation as distinct from a restart. No later pause or landing at count 16 was executed in this class. No model run is claimed for the public trace.

These remain separate source, model, implementation and mapping investigations. No production observations go to the clean author. Empty-board/single-support/O, fake scheduler, successful storage and a narrow count domain are limits. No all-reachable-state, rotation-history, real-deadline, bag/queue or storage proof is claimed. This record is not part of current PR77.
