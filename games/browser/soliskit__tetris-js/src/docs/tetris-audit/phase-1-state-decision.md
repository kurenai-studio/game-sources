# Game State and Transition Boundary

A proposed state model, awaiting review and owner approval.

Status: **CANDIDATE normative decision text, for fidelity review. Not yet an adopted owner decision.** This text encodes the owner-choice package prepared from the completed proposal and reconciliation process. It awaits fidelity review of this exact text and then explicit owner approval of it. Until that approval it is not recorded in `DECISIONS.md`, and it is a candidate for D16 only. The proposal that preceded it is `docs/phase-1-state-model-proposal.md` (deleted, kept in git history), kept as historical review material and not normative.

Limits of this text: it certifies nothing and establishes no implementation property. APP-2 and APP-6 remain in audit scope although outside this state model. R1 and the later Phase 1 decisions remain open. These are limits on the semantics below, not implementation evidence.

## 1. State categories

Every item of modeled state belongs to exactly one of five categories: authoritative game state, derived state, runtime resources, persisted representation, presentation state. There is no sixth category.

### 1.1 Authoritative game state

1. Locked blocks.
2. The current falling piece, including its kind, rotation and position.
3. The held piece.
4. The once-per-piece hold-used state.
5. The next-three queue.
6. The remaining bag contents.
7. The score.
8. The game mode.
9. The lock-delay reset count.
10. The logical New Game confirmation-pending state.
11. The logical selected confirmation choice.
12. The held-direction state and the newest-direction ordering.
13. The repeat-sequence position needed by INP-2.
14. The semantic touch-drag state needed by INP-5, including the controlled falling piece and the gesture state needed to determine required future behavior.

Each of items 10 to 14 is an individual placement.

### 1.2 Derived state

1. The level.
2. Whether the current piece is resting.
3. The landing (ghost) position.
4. The gravity interval.

Derived state has no independent semantic authority. It is determined by other modeled state according to the applicable rule. An implementation may compute, store or cache it. Later correspondence evidence must establish agreement where required.

### 1.3 Runtime resources

1. The gravity timer handle and state.
2. The lock-delay timer handle and state.
3. The key-repeat timer and scheduler handles.
4. Other scheduled-callback handles where modeled as runtime resources.
5. The screen wake lock.

### 1.4 Persisted representation

1. The saved game.
2. The stored high score.

### 1.5 Presentation state

1. The rendered UI, including board and canvas output, text, hints, buttons, the Game Over display and the visual rendering of the confirmation dialog.
2. The locked-block redraw/change marker. It is presentation state, not a sixth category.

## 2. Randomness

Nondeterministic random values and the random source are modeled as input to bag refill and shuffle transitions. They are not authoritative game state. The resulting remaining bag contents are authoritative state (1.1, item 6).

No requirement is adopted here that random-generator internal state be exposed or preserved.

## 3. Service-worker, cache and version state

Service-worker, cache and version state is outside this state model, while remaining in scope as outer-layer state subject to APP-2 and APP-6 inventory, evidence, falsification and certification.

- APP-2 and APP-6 remain fully in audit scope.
- Placing that state outside this model does not take those requirements out of scope and does not certify them.
- Evidence about the engine state model must not be presented as covering APP-2 or APP-6 unless a later proof obligation explicitly establishes that correspondence.
- APP-2 and APP-6 need their own later evidence, including the applicable Phase 2 outer-layer inventory, trust accounting, Phase 4 attacks and falsification, and later certification.

## 4. Authoritative transition boundary

A transition is a specified legal operation that attempts to move authoritative state from one certified state to another certified state, or to the certified safe terminal/fault state.

The authoritative transition boundary is the conceptual commit point at which the specified legal operation commits the authoritative changes the model permits, together with any authorized persistence effects belonging to that transition.

1. The boundary is defined independently of implementation function structure.
2. A function does not become authoritative merely because it validates.
3. No privileged exception is adopted at this gate.
4. External or environmental routes may change external, runtime or persisted state without gaining authority to commit game state.
5. External data becomes authoritative only when accepted through an authorized transition.
6. Drawing, polling and other outer-layer routes do not directly commit authoritative game state, unless a later explicitly approved exception says otherwise.

## 5. Conceptual control operations

Because the control values in 1.1 are authoritative, the operations that may commit them cross the authoritative transition boundary. They are conceptual model operations, not claims about implementation function names.

1. New Game confirmation open.
2. Confirmation selection change.
3. Confirmation answer.
4. Direction or control press.
5. Direction or control release.
6. Repeat-control progression.
7. Touch or drag begin.
8. Touch or drag update.
9. Touch or drag end or cancel.

## 6. Validity policy V1

V1 is the owner's validity policy: validity at the commit boundary.

1. Intermediate authoritative mutations inside an unfinished transition may temporarily violate the ordinary valid-state predicates.
2. Every successful committed legal transition ends in a certified valid state under the R1 predicates, which a later Phase 1 decision approves.
3. The certified SAF-3 safe terminal/fault state is separate and is governed by its own definition. V1 does not require malformed ordinary game contents retained after a fault to satisfy R1.

This is an owner-approved interpretation of the word "never" in PCE-6, for this audit. Under it, PCE-6 constrains successful committed legal states. It does not create a requirement that every invisible internal microstep preserve ordinary validity.

This decision does not reduce or reinterpret SAF-4. SAF-4 still requires invariant checking "after every action and every timer". SAF-4 does not prove V1. V1 is an explicit owner interpretation.

## 7. Thrown-transition rule F2

F2 is the owner's thrown-transition rule. If a transition throws after authoritative mutation has begun but before successful completion, the ordinary authoritative contents reached at the point of fault are retained, except for fields and effects that must change to enter the SAF-3 safe terminal/fault state. The safe-terminal transition is then applied.

1. No rollback guarantee for ordinary authoritative contents is adopted.
2. F2 does not itself prove that the system is safe. Safety claims still depend on SAF-3 and on later evidence.
3. Persistence-specific consequences are not decided here. The meaning of "last good save", persistence ordering, storage rollback and discoverability, STA-3 forgetting effects and related persistence semantics remain for R2 and R4.
4. Retained partial in-memory contents do not become valid game state by being retained.

## 8. SAF-3 safe terminal/fault state

Only the fixed skeleton of SAF-3 is recorded:

1. game over;
2. no timers running;
3. fault reported;
4. last good save kept.

No board, queue, piece, score, hold or other validity condition is added. This decision does not decide what "fault reported" means, what "last good save" means, or persistence ordering. Those remain later Phase 1 decisions.

## 9. SAF-4 timer meaning

SAF-4 keeps its literal wording: "after every action and every timer". This decision adopts no interpretation of what "timer" means for SAF-4. It narrows no required check point. It does not merge SAF-4 with the "no timers running" part of SAF-3. The SAF-4 timer interpretation remains an explicit later owner decision.

## 10. Not decided here

- The exact R1 valid-state predicates.
- R2 and R4 persistence semantics, beyond the non-decision in section 7.
- R3 and R5.
- The exact fault-reporting criterion.
- Scheduler, browser, storage and render trust decisions.
- Oracle and specification choices.
- Proof-obligation requirement mappings.
- The contents of the O8 model input pack.
- Implementation correctness.
