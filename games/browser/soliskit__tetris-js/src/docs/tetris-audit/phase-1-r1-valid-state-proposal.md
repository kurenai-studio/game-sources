# Valid Game State Proposal

The earlier proposal for valid game state.

Status: **PROPOSAL FOR REVIEW. This is not an approved decision.** No owner decision is recorded by this document, no row in `DECISIONS.md` refers to it, and none is added.

Base: main. D16 is merged and governs the state categories, the authoritative transition boundary, V1 and F2. Its document `docs/phase-1-state-decision.md` (SHA-256 0ca7916f67e1b6a2e784272af15732b018b41ed70f3ec0fe05ceb72a5dcc0bad) is not modified. Nothing in `REQUIREMENTS.md`, the blueprint, `DECISIONS.md`, the production code, the tests, the CI configuration or any proof tool is changed by this document.

Independence (blueprint O8): the assistant that drafted this has read the production code. This proposal is built from `REQUIREMENTS.md`, the blueprint and D16, and no rule below rests on how the current code represents or checks anything. It is still not an independent model. It judges the implementation against no predicate and classifies no finding (F21, Q1, Q2, Q3 and the score-domain candidate are not classified).

The document has two parts. Part A is review material: requirement reasoning, alternatives and owner choices. Part B is a separate draft of clean candidate normative text, DRAFT and NOT APPROVED. Where Part B holds a bracketed OWNER CHOICE, it is unresolved and the surrounding text is conditional on it.

## Part A. Review material

### A1. Support classes

Each proposed rule is tagged with how the text supports it:

- **[D]** directly required by existing text (a requirement, the blueprint or D16).
- **[L]** logically derived from several existing statements.
- **[O]** a genuine owner interpretation or clarification. Calling it required would be wrong.

An [O] item is never presented as required because it gives a cleaner model. Where the text supports two readings, both are shown with consequences. Where a recommendation appears it is the drafter's, labeled, and claims no sufficiency.

### A2. Kinds of state R1 applies to

1. **Ordinary certified state [D, V1].** A state reached by a successful committed legal transition. The ordinary valid-state predicate (`OrdinaryValid`) governs exactly these. Ordinary STA-3 game over is an ordinary state with game mode "game over".
2. **SAF-3 safe terminal/fault state [D, D16 section 8].** A separate certified class, identified by its own marker in the model and not by game mode. "Game over" alone cannot identify it, because ordinary game over exists. Its content is governed by the SAF-3 skeleton (game over, no timers running, fault reported, last good save kept) and by later fault decisions. `OrdinaryValid` imposes nothing on ordinary contents retained after a fault (D16 F2).
3. **Untrusted external persisted representation [D, SAF-1, SAF-2].** Arbitrary stored bytes may be malformed without making the authoritative state invalid. R1 separates (a) an arbitrary external stored representation, which is not part of any state, from (b) a representation that the application accepts and converts into authoritative state. Only (b) is subject to ordinary validity, and only through the acceptance predicate in Part B section B13. Malformed storage cannot make the system state invalid, and a rejected save leaves no partial state.

### A3. Three kinds of rule

R1 keeps these apart. A history-dependent rule is not forced into a snapshot invariant unless the text supports it.

- **State predicates:** properties of one ordinary state. Only these are `OrdinaryValid`.
- **Transition postconditions and history properties:** what a legal operation must do, or what holds over a sequence of states (for example the once-per-seven dealing guarantee of PCE-5). These belong to the later transition and proof-obligation work. R1 only records them so they are not lost.
- **External-input acceptance:** which external representations may become a state (section B13).

### A4. Board (PCE-1, PCE-2, PCE-6, SAF-4)

- The board is a total grid of exactly 20 rows and 10 columns, so exactly 200 positions, each holding a value [D, PCE-1, SAF-4: "board 20 by 10"].
- Every position is present. A missing position, a missing row, an extra row or an extra position is not a valid board [L]. PCE-1 says positions outside the grid "hold nothing", so there is no 201st position to hold anything. A board with a hole in its representation is therefore not a board with an empty cell. An empty cell is a present position holding the empty value. This is a semantic statement and does not depend on any array behavior.
- Cell domain: a cell is Empty or Occupied, and an Occupied cell identifies one of the seven piece kinds (OWNER CHOICE C1).
- A full line (all ten cells Occupied) is not itself invalid unless C2 says so.

**C1, locked-cell content [O].** PCE-2 gives each piece a fixed color, and DSP-6 requires saved games to keep the usual colors. Option C1a: an Occupied cell records the piece kind, and color is a fixed function of the kind. Option C1b: an Occupied cell records only occupancy. C1b cannot keep PCE-2 colors for locked blocks without extra state that D16 does not list. Drafter's recommendation: C1a. It is the only option under which D16's "locked blocks" carry what the color requirements need. This does not establish that C1a is sufficient.

**C2, full lines at a commit boundary [O].** SCO-1 says cleared rows disappear and everything above moves down. No text says whether a full line may exist in a committed ordinary state. Option C2a: a full line may exist in a snapshot, and clearing is transition behavior. Option C2b: no committed ordinary state has a full line, which makes "all full lines are cleared before commit" part of the validity predicate. Consequence of C2b: a legal save or board with a full line is invalid, which strengthens the invariant and the acceptance rule. Consequence of C2a: the invariant is weaker, and "no full line after a lock" becomes a separate transition postcondition if the owner wants it. Both are consistent with the text. No recommendation.

### A5. Piece kinds and canonical piece (PCE-2, PCE-3, PCE-4)

- The seven piece kinds are I, O, T, S, Z, J, L and nothing else [D, PCE-2].
- A canonical piece is a triple (kind, rotation state, position) whose four blocks are exactly the standard SRS block set for that kind and rotation state, translated by the position [D, PCE-2: "four blocks, standard SRS rotation states"]. Four blocks and fixed color follow from the kind.
- Rotation-state domain: I, T, S, Z, J and L have the four SRS rotation states. The O piece has exactly one rotation state, its non-rotating canonical state [D, PCE-4: "The O piece does not rotate"]. A representation of the O piece with another rotation state is not canonical, even though its blocks might coincide with the canonical ones.
- Position domain: a pair of integers locating the piece on the grid. Non-integer or non-numeric positions are not canonical [L].
- A piece is valid only if it is canonical. A geometric fit test alone is not piece validity: a set of four cells that fit on the board is not a piece unless it is the SRS block set of a valid kind, rotation state and position. A shape with the wrong number of blocks, a block set that is not an SRS block set, or an unknown kind or rotation state is not a valid piece even if every cell it names is free.
- Dependency: "the standard SRS block set" is not tabulated in `REQUIREMENTS.md`. R1 states the predicate over the canonical SRS table. Which written source fixes that table is a later oracle and specification choice, reserved to the owner, and is not made here.
- PCE-3 (first rotation, horizontally centered, top two rows) is a rule about the transition that brings a new piece in. It is not a property of every current piece, and R1 does not make it a snapshot predicate.

### A6. Current piece, fit and mode (PCE-6, STA-1 to STA-5, SAF-4)

`Fits(piece, board)`: the piece is valid, all four of its blocks lie inside the 20 by 10 grid, and every grid position it occupies holds Empty. PCE-6 ("can never be outside the board or overlap a locked block") applies to a piece that is present.

- Playing: a current piece is present and fits [D, PCE-6, SAF-4].
- Paused: a current piece is present and fits [L]. STA-4 restores "exactly what was saved, paused", and PCE-6 has no "while playing" qualifier. SAF-4's check wording ("while playing the piece fits") does not weaken PCE-6 for a paused committed state, because under V1 PCE-6 constrains every committed ordinary state and SAF-4 only names when the engine checks.
- Ordinary game over: genuinely open (C3a). STA-3 says the game ends when a new or held piece has no room to appear. A piece with no room does not fit, and PCE-6 forbids it as a committed current piece. DSP-8 shows no falling piece at game over, but DSP-8 is a display rule.
  - **C3a [O].** Option G1: an ordinary game-over state has no current piece (absence is a valid current-piece value only in game over). Option G2: an ordinary game-over state may retain a current piece that fits. G2 has no support in the text for which piece it would be or why it would stay, and it forces a retained-piece rule that nothing requires. G1 introduces "no current piece" as a valid value in one mode. A non-fitting current piece in an ordinary state is excluded under both options. Drafter's recommendation: G1, as the reading that adds no unrequired state. This does not establish that G1 is sufficient.
- SAF-3 fault state: no ordinary current-piece predicate applies.

### A7. Queue (PLY-8, SAF-4)

- A queue is an ordered list of exactly three entries, every position present, each entry one of the seven piece kinds [D, SAF-4 "three pieces queued", PLY-8; L for entry kinds]. A missing entry, an empty entry, a non-kind value, a fourth entry or a sparse list is not a valid queue.
- Order is significant (it is the dealing order).
- Duplicate kinds inside the three entries are not invalid. The dealing sequence passes through bag boundaries, and the three-entry window can span two bags, so a kind can repeat inside it. Uniqueness is not a snapshot property of the queue [L]. R1 does not claim that the snapshot proves PCE-5.
- Open (C3b): SAF-4 says "three pieces queued" with no mode qualifier, and PLY-8 says "always known" but "shown while a game is in play or paused". STA-1 says the game opens at game over, and DSP-8 says a new game "deals its own" pieces.
  - **C3b [O].** Option Q-A: every ordinary state, including game over, has a valid three-entry queue (the literal SAF-4 reading). Option Q-B: the queue is required in playing and paused states and is unconstrained or absent in ordinary game over. Both fit the text. Q-A makes the opening game-over state carry a dealt queue. Q-B needs a defined "no queue" value in game over. No recommendation.

### A8. Bag (PCE-5, STA-1, STA-4)

D16 makes the remaining bag contents authoritative. R1 adds snapshot rules only as far as the text supports.

- Allowed entries are the seven piece kinds. No kind appears twice within one remaining bag [L, PCE-5: a bag holds each kind once]. A remaining bag therefore has between 0 and 7 entries, and a new game starts with a full bag, which is exactly the seven kinds [D, PCE-5].
- The relation between a snapshot and the global "each appears once per seven" guarantee is a history property. A valid snapshot alone does not prove it, because the dealt part of the current group is not recoverable from the snapshot. R1 states the snapshot rule only.
- **C4, order [O].** D16 says "remaining bag contents". Option B-ord: the remaining bag is an ordered sequence, and its order is part of the state (STA-4: restores "exactly what was saved, including the pieces left in the bag"). Option B-set: the remaining bag is an unordered set and the next piece is drawn by the random input. Both fit PCE-5. B-ord makes the saved order observable and means the shuffle result is state. B-set makes the draw a transition input. D16's wording does not choose between them, and R1 does not extend D16 by assuming one.
- **C5, empty bag at a commit boundary [O].** The text does not say whether a refill happens when the last piece is taken or when the next one is needed. Option E0: a remaining bag of 0 entries can exist at a commit boundary (lazy refill). Option E1: at least 1 entry always remains at a commit boundary (eager refill). No recommendation.

### A9. Score and level (STA-1, SCO-1, SCO-2, SAF-4)

SAF-4 says "a valid score" and no requirement defines the word further. What the text gives: a new game resets the score (STA-1), clearing 1 to 4 lines adds 100, 300, 500 or 800 (SCO-1), and nothing else changes it.

- Non-negative: [L], from the reset and the additive-only rules.
- Integer: [L].
- Multiple of 100: the reachable scores from 0 are all multiples of 100, but "reachable" is a history property. Whether a snapshot predicate may use it is the closure policy C6 below.
- Finite maximum: none exists in the requirements. A snapshot rule that names a maximum would be an invented limit.
- Safe integer: the phrase has no normative basis in the requirements. R1 does not adopt "safe integer" or any implementation numeric limit.
- Consequence for later evidence: the model's score is a mathematical non-negative integer with no upper bound. A finite implementation number format is a correspondence assumption, to be bounded or excluded by later work, not a validity rule here.

The level is derived (D16, SCO-2): level = floor(score / 1000) + 1. It is not an independent predicate. A later cached copy that disagrees is a correspondence matter, not a second authority.

### A10. Hold (PLY-7)

- Held state is either Absent or exactly one of the seven kinds [D].
- A held piece is in its "starting state": it has no position and no rotation state. Position and rotation are not meaningful while held [L].
- Hold-used is a boolean with one meaning: a successful hold has already occurred for the current piece instance [L, PLY-7 "Hold works once per piece"]. Its resets and sets are transition rules (reset when a new piece appears after a lock; set by a successful hold, including for the piece brought in by that hold). R1 states only the domain.
- Whether hold-used true implies a held piece is present is a closure item (C6). R5's hand-edited-save question is not decided here.

**C6, snapshot closure policy [O].** Several candidate snapshot rules hold on every state reachable by legal play but are not stated as such: score is a multiple of 100; hold-used true implies a held piece is present. Option P-dom: ordinary validity checks domains and the relations the text states directly, and the reachability-derived relations are transition and proof obligations, not snapshot predicates. Option P-clo: the reachability-derived relations are added to the snapshot predicate. Consequence of P-clo: a stronger invariant and a stricter acceptance rule for saved games (a save with score 150 is rejected). It also adds rules the text states only through histories. Consequence of P-dom: a weaker invariant, so states that no legal play reaches can be ordinary valid. No recommendation.

### A11. Game mode and combinations (STA-1 to STA-5)

Game mode is exactly one of playing, paused, game over [D, STA-1 to STA-3]. Combinations the text supports:

| Mode | Current piece | New Game confirmation pending |
| --- | --- | --- |
| playing | present, fits [D] | not allowed [D, STA-1: New Game "never while playing", the dialog is asked "while paused"] |
| paused | present, fits [L] | allowed [D, STA-1] |
| game over | open (C3a) | not allowed [L, STA-1: the dialog is the paused-game question] |

Pending confirmation therefore implies paused. Held-direction and repeat state combinations are in A13.

### A12. New Game confirmation (STA-1)

- Pending is a boolean. Selected choice is one of two values, Cancel and New Game, and exists only while pending [D].
- Initial selected choice when the dialog opens is Cancel [D, STA-1 "Cancel is selected when it opens"]. That is a transition rule, and the snapshot domain is the two values.
- While not pending there is no selected choice (a distinct "none"). Option: a neutral stored value. R1 states "none" and does not decide a stored default [L].
- The visual highlight is presentation state (D16). The selected choice is the logical value, not its drawing.

### A13. Held-direction, soft-drop and repeat state (INP-2, INP-3, INP-4)

- **Control sources.** The model has a finite set of horizontal control sources, one per physical control that can be held: each keyboard key mapped to left or right, the stick toward each side, and the directional pad toward each side [L, INP-1, INP-2, INP-4]. Each source has a fixed direction. Soft drop has its own sources (the S and Down keys, the stick down, the pad down) [L]. Distinct sources are needed because releasing one source must not erase another that is still held (INP-2: "releasing it goes back to one still held").
- **Held-direction state.** An ordered list of the horizontal sources currently held, without duplicates, ordered by when each became held, newest last. The "newest direction wins" relation is the last entry [D, INP-2]. One analog source cannot hold both directions at once [L]. The soft-drop held set is unordered and has no duplicates.
- **Modifier rule.** A key pressed with Cmd, Ctrl or Alt never enters the held state [D, INP-3]. This and "disconnecting releases everything" [D, INP-4] are transition rules.
- **Repeat position.** One of: no active repeat; the initial wait before the first repeat (167 ms after the first move); repeating at the 33 ms cadence; for soft drop, repeating at the 50 ms cadence after the immediate first drop [D, INP-2]. The names are descriptive and the model may use others. This is semantic position, separate from any scheduler handle.
- **Combinations.** An active repeat requires mode playing and a corresponding held source [D, INP-2: repeating stops when the game stops playing]. In paused and game over an active repeat does not exist. A pending confirmation presses nothing [D, STA-1]. Repeat position none is the only position when no source is held [L].
- **C7, held state after the game stops playing or the window loses focus [O].** INP-2 says repeating stops. It does not say whether the held sources are also cleared. Option H-clear: they are cleared, so a key still physically down does nothing after resume until pressed again. Option H-keep: they are kept with repeat position none, so resuming with the key still down can restart the repeat. Both fit the text. No recommendation.

### A14. Touch-drag state (INP-5, D16 item 14)

D16 item 14 already lists "the controlled falling piece and the gesture state needed to determine required future behavior". R1 states the semantic content without adding fields.

- Inactive, or Active with: the gesture origin; the accumulated horizontal and vertical displacement measured in gesture coordinates (in step with the finger, and not accumulating past a wall); whether the movement has exceeded the 10 px wobble allowance (tap versus drag, INP-5); and whether the gesture still controls the current piece.
- "Controls the current piece": a drag controls only the piece that was falling when it began [D, INP-5]. The proposal realizes this inside item 14 as a flag that a drag sets when it begins and that any transition replacing the current piece clears (a lock, a hold, a new game, game over). A cleared drag keeps tracking the finger but moves nothing, until it ends. No piece-identity field is added.
- **C8, piece identity for the capture [O].** The flag realization above needs no identity. Option T-flag: adopt it. Option T-id: read "the controlled falling piece" in item 14 as an opaque piece-instance identity, which gives the current piece an identity that D16's current-piece item (item 2) does not list. T-id is a D16 interpretation or amendment decision. Drafter's recommendation: T-flag, as the smallest realization inside the approved wording. This does not establish that T-flag is sufficient.
- Pixel and cell sizes belong to the presentation layer. The semantic state is in gesture coordinates supplied with each touch event, and the cell size and the 10 px allowance are input parameters. R1 does not fix their values.
- Active drag requires mode playing for it to control anything. In other modes a drag, if present, controls nothing.

### A15. Resting, lock-delay resets and gravity (PLY-2, PLY-6, STA-2)

- `Resting` is derived [D, PLY-6; D16]: a current piece is present and the same piece shifted down one row does not fit. It is defined from the piece and the board only, not from any stored flag. Whether the game is playing is a separate condition used by the timer rules.
- Lock-delay reset count: a whole number from 0 to 15 [D, PLY-6: "at most 15 times"]. The domain is a snapshot rule. When and how the count changes is transition behavior.
- Gravity interval is derived: max(0.25, 0.7 - 0.02 x (level - 1)) seconds [D, PLY-2]. R1 states only the mathematical value. Timing tolerance (R3) and any number-format correspondence are not decided here.
- **C9, the 15-reset boundary [O].** PLY-6 says moving or rotating while resting restarts the delay "at most 15 times", and "once the 15 are used, landing locks at once". STA-2 says pausing during the delay "counts as one reset". Two points are not settled by the text. (a) Whether a pause reset is subject to the 15 limit, which decides whether the count domain is 0 to 15 with saturation (option K-sat) or can reach 16 (option K-16). (b) What "landing" means once the 15 are used: lock at the next moment the piece comes to rest, with the delay already running left to expire (option N-rest), or lock at once on any landing including the current rest (option N-any). These choices set the transition rule and, for K-16, the domain. No recommendation.
- **C10, reference row for resets [O, D16 gap].** PLY-6 says "reaching a lower row than before resets the count". "Before" needs a remembered reference, for example the lowest row the current piece has reached. D16 lists the lock-delay reset count but no such reference quantity, and it cannot be derived from the board and current piece alone. Whether this quantity is covered by D16's existing items or needs a D16 clarification is an owner question. R1 does not add it. The snapshot count domain (0 to 15) can close without it. The exact transition semantics of PLY-6 cannot.

### A16. Timers and resources (SAF-4, PLY-2, PLY-6, STA-2, STA-3, INP-2)

"Running" is defined semantically and not as a field being non-null. A resource is **outstanding** in a state when the model records a future firing that will occur unless cancelled. A raw handle-like value does not by itself define outstanding or not outstanding; a representation that is neither a recorded future firing nor the recorded absence of one is not a valid timer state. What a firing is and when it is due belongs to the later scheduler decisions (R3 and trust decisions).

Known resources and their requirement-supported rules:

- **Gravity [D].** Outstanding exactly when mode is playing (PLY-2, SAF-4). Not outstanding when paused (STA-2) or game over (STA-3).
- **Lock delay [D].** In mode playing, outstanding exactly while the current piece is `Resting` (SAF-4, PLY-6). Not outstanding when paused or game over (STA-2, STA-3). Pausing during the delay cancels it, and resuming starts it again (STA-2, PLY-6).
- **Key and stick repeat [D, INP-2].** Outstanding only as part of an active repeat position (A13), which requires mode playing and a held source. Repeating stops when the game stops playing.

**The open SAF-4 timer question and R1.** SAF-4 says "after every action and every timer", and, for the timers, "while playing ... gravity is running and the lock delay runs exactly while the piece rests, otherwise no timers run". The meaning of "timer" in SAF-4 is an open owner decision (D15, D16). Two points need care:

1. The word "otherwise" has two readings: (i) when the game is not playing, no timers run; (ii) in every other case, including while playing, no timers other than gravity and lock delay run. Reading (ii) would contradict INP-2 whenever a key is held while playing, unless repeat resources are outside the SAF-4 timer set. Reading (i) does not conflict with INP-2.
2. The set of things SAF-4 calls timers, call it T, is open.

R1 proposal: parameterize. `ValidKnownTimerState` is defined over the three named resources above and is complete for them. The broader statement "when not playing, no resource in T is outstanding" is stated with T as a parameter, with gravity and lock delay required to be in T and every other member deferred to the later owner decision. Under this, R1 can close without deciding T. What stays blocked by T and is not decided here: classification of Q3, and any claim that the "no timers run" invariant covers every scheduled callback. If the owner wanted R1 to fix T now, the smallest decision needed would be whether the repeat resources are in T. R1 does not need it and does not take it.

### A17. Wake lock and presentation (DSP-3, DSP-7)

- Wake-lock state is a runtime resource (D16). Acquisition is not a precondition of ordinary validity, because DSP-7 says that if the wake lock is unsupported or refused, the game plays normally. DSP-7's lifecycle (kept while playing, released at pause and game over, re-requested if taken back) is a separate requirement for its own evidence and is not part of `OrdinaryValid`.
- Other scheduled callbacks are not SAF-4 timers by being scheduled. R1 does not turn them into timers.
- Presentation state, including the locked-block redraw/change marker (D16), is not part of `OrdinaryValid`. Display correctness is evidence for the display requirements, not authority over state validity.

### A18. Persisted representation interface (SAF-1, SAF-2, STA-4, STA-6)

R1 gives only content-validity and acceptance rules. R2 and R4 own when a save is forgotten, deletion versus discoverability, failed reads and writes, rollback, "last good save" and persistence ordering. None is decided here.

- An accepted save is accepted whole and decodes to an ordinary state. A rejected save yields no state and no partial state [D, SAF-1].
- Piece values in an accepted save are rebuilt from the built-in definitions, so every accepted piece value is a valid kind and a canonical piece [D, SAF-1].
- An accepted save decodes to an `OrdinaryValid` state in mode paused [D, STA-4 "restores exactly what was saved, paused"].
- The supported formats are the current format and the earlier format that also stored the level [D, STA-6]. The earlier format's stored level is not authoritative: the level is derived (A9). A save before the bag was saved omits the bag and continues with a fresh full bag [D, STA-4], the random input being a transition input (D16).
- **C11a, which authoritative fields a save carries [O].** STA-4 says continue restores "exactly what was saved", and the control state (confirmation, held directions, repeat position, drag) is authoritative under D16. The text does not say which fields a save contains. Proposal: the saved content is the game core (board, current piece, held piece, hold-used, queue, bag when the format has it, score, lock-delay reset count), and a continued game starts with the control state at its initial values: no confirmation, no held sources, repeat none, drag inactive. The owner confirms or changes this. The reset-count reference (C10) would also need a place if it is authoritative.
- **C11b, an ignored legacy field and SAF-1 [O].** SAF-1 says "every field is checked". STA-6 says loading ignores the stored level. Option V-check: a present stored level is checked for validity even though it is ignored, so an invalid level rejects the save. Option V-ignore: an ignored field is not checked. Both are consistent with the text. Consequence of V-check: a save from the earlier format with a malformed level is rejected, which changes which fixtures-like saves load. Consequence of V-ignore: "every field" means every field the application uses. No recommendation.
- The stored high score is persisted representation and not authoritative state. A malformed stored value may exist without making state invalid; SAF-2 says invalid stored values are ignored. What makes it good is R4's decision, so R1 defines no high-score predicate.

### A19. Completeness check for the pending R1 questions

This table says only which proposed rule will later answer each question. It classifies no finding and cites no implementation behavior.

| Pending Question | Answered later by |
| --- | --- |
| F21: sparse or holey board | B3 (board is a total grid of 200 present positions; a missing position is not an empty cell) |
| Q1: malformed queue | B5 (exactly three present entries, each one of the seven kinds) |
| Q2: malformed current piece, vacuous fit | B4 (the piece must be canonical, and Fits is defined only for valid pieces) |
| Q3: non-semantic timer representation | B10 (outstanding is a recorded future firing or its recorded absence), subject to the open timer-class parameter T |
| Score-domain question (safe integer) | B7 (non-negative integer, no maximum, no safe-integer rule), subject to C6 |
| PLY-7 hold-used question | B8 (hold-used meaning and domain), subject to C6 |

### A20. Owner choices exposed by this proposal

Choices the owner must make before R1 can close:

| ID | Question | Options |
| --- | --- | --- |
| C1 | Locked-cell content | C1a records kind (drafter's recommendation); C1b occupancy only |
| C2 | Full line at a commit boundary | C2a permitted; C2b invalid |
| C3a | Current piece in ordinary game over | G1 absent (drafter's recommendation); G2 retained fitting piece |
| C3b | Queue in ordinary game over | Q-A always three; Q-B only playing and paused |
| C4 | Remaining bag order | B-ord ordered; B-set unordered (D16 wording does not decide) |
| C5 | Empty remaining bag at a commit boundary | E0 allowed; E1 not allowed |
| C6 | Snapshot closure policy | P-dom; P-clo (score multiple of 100, hold-used implies held present) |
| C7 | Held sources after the game stops playing or focus is lost | H-clear; H-keep |
| C8 | Touch-drag capture realization | T-flag (drafter's recommendation); T-id (a D16 interpretation or amendment) |
| C9 | The 15-reset boundary and pause reset | K-sat or K-16; N-rest or N-any |
| C10 | Reference row for PLY-6 resets | D16 clarification needed or already covered |
| C11a | Fields a save carries and initial control state on continue | proposal in A18 or other |
| C11b | SAF-1 and the ignored legacy level | V-check; V-ignore |

Dependencies that are not R1 choices: the written source of the canonical SRS block table (a later oracle and specification decision); the SAF-4 timer universe T (open owner decision, see A16); R2 and R4 persistence semantics; R3 timing tolerance; R5 hand-edited saves.

Does the SAF-4 timer-definition question block full R1 closure? No. R1 can close with `ValidKnownTimerState` defined for gravity, lock delay and repeat, and with the broader "no timers when not playing" clause parameterized by T. The timer-class decision blocks the classification of Q3 and any claim that the invariant covers every scheduled callback. It does not need to be pulled forward unless the owner wants R1 to fix T, in which case the smallest decision is whether the repeat resources belong to T.

D16 points surfaced and not extended: item 14's "controlled falling piece" (C8), the missing PLY-6 reference quantity (C10), and the wording "remaining bag contents" (C4).

## Part B. DRAFT candidate normative text. NOT APPROVED.

This part is a draft for later review. It is not an owner decision and not an adopted rule. It contains only requirements-based rules and the bracketed owner choices above. It has no implementation observations, code locations, tests, finding history or reviewer commentary.

### B1. Classes of state

1. An **ordinary state** is a state reached by a successful committed legal transition. `OrdinaryValid` (B14) is the conjunction of the predicates below and governs exactly the ordinary states.
2. The **safe terminal/fault state** is a separate class with its own marker. It is not identified by game mode. No predicate of this document applies to ordinary contents retained in it.
3. An **external representation** is arbitrary stored data. It is not a state. It becomes part of a state only through B13.

### B2. Piece kinds

`PieceKind` is exactly one of I, O, T, S, Z, J, L.

### B3. Board

`ValidBoard(b)` holds exactly when b is a total grid of 20 rows and 10 columns: every one of its 200 positions is present and holds a cell value, there is no other position, and each cell value is Empty or Occupied. [OWNER CHOICE C1: an Occupied cell records its PieceKind, and color is a fixed function of the kind / an Occupied cell records occupancy only.] A missing position is not an Empty cell. [OWNER CHOICE C2: a full line is a valid cell pattern in an ordinary state / no ordinary state contains a full line.]

### B4. Pieces and fit

A **canonical piece** is a triple (kind, rotation state, position) where kind is a PieceKind, the rotation state belongs to the rotation states of that kind (I, T, S, Z, J and L have four, the O piece has exactly one, its non-rotating state), and the position is a pair of integers. `Blocks(piece)` is the four grid positions given by the canonical SRS block set for that kind and rotation state, translated by the position. A value that is not a canonical piece is not a piece.

`Fits(piece, b)` holds exactly when piece is canonical, all four of `Blocks(piece)` lie inside the 20 by 10 grid, and every position in `Blocks(piece)` holds Empty in b.

`ValidCurrentPiece(mode, piece, b)`: in modes playing and paused, piece is present and `Fits(piece, b)`. [OWNER CHOICE C3a: in game over, no current piece is present / a current piece may be present if it fits.] A present current piece that does not fit is not valid in any ordinary state.

### B5. Queue

`ValidQueue(q)` holds exactly when q is an ordered list of exactly three entries, every position is present, and each entry is a PieceKind. Duplicate kinds are permitted. [OWNER CHOICE C3b: this applies in every ordinary state / this applies in modes playing and paused only.]

### B6. Bag

`ValidBag(g)` holds exactly when each entry of g is a PieceKind and no PieceKind appears twice in g, so g has at most seven entries. A full bag is exactly the seven PieceKinds, each once. [OWNER CHOICE C4: g is an ordered sequence and its order is state / g is an unordered set.] [OWNER CHOICE C5: g may be empty in an ordinary state / g has at least one entry in an ordinary state.] The relation between a bag and the dealing guarantee of PCE-5 is a history property and is not a part of `ValidBag`.

### B7. Score and level

`ValidScore(s)` holds exactly when s is a non-negative integer. There is no maximum. [OWNER CHOICE C6: and s is a multiple of 100 / and nothing more.] No implementation numeric limit is part of validity. The level is derived: floor(s / 1000) + 1. It is not an independent state predicate.

### B8. Hold

`ValidHeldState(h, u)` holds exactly when h is Absent or a PieceKind and u is a boolean. The held piece has no position and no rotation state. u is true exactly when a successful hold has already occurred for the current piece instance. [OWNER CHOICE C6: u true implies h is not Absent / no such rule.]

### B9. Game mode and confirmation

`ValidMode(m)` holds exactly when m is one of playing, paused, game over. `ValidConfirmationState(c, m)`: c is either Not pending, or Pending with a selected choice that is Cancel or New Game. A selected choice exists only while Pending. Pending implies m is paused. The selected choice is a logical value, and its highlight is presentation state.

### B10. Timers and resources

A resource is **outstanding** in a state when the state records a future firing of it that will occur unless cancelled. Being outstanding is not defined by the value of a handle. A state in which a resource has neither a recorded future firing nor the recorded absence of one is not valid.

`ValidKnownTimerState` holds exactly when all of the following hold.

1. Gravity is outstanding exactly when the mode is playing.
2. The lock delay is outstanding exactly when the mode is playing and a current piece is present and `Resting`.
3. A repeat resource is outstanding only as part of an active repeat position (B11), which requires the mode playing and a corresponding held source.
4. When the mode is not playing, no resource in the set T is outstanding, where T is the set of things the open owner decision on SAF-4 calls timers. T contains gravity and the lock delay. No other member of T is decided by this document.

Wake-lock state is a runtime resource and is not part of `ValidKnownTimerState` or `OrdinaryValid`.

### B11. Control state

1. **Sources.** The model has a finite set of horizontal control sources, each with a fixed direction, and a finite set of soft-drop control sources. The sources are the physical controls named by the input requirements.
2. `ValidHeldDirectionState(d)`: d is an ordered list of horizontal sources without duplicates, ordered by when each became held, newest last. No source appears in two directions at once. The newest direction is the direction of the last entry. A control pressed with Cmd, Ctrl or Alt never enters d.
3. The soft-drop held state is a set of soft-drop sources without duplicates.
4. `ValidRepeatState(r, d, m)`: r is one of: no active repeat; the initial wait before the first horizontal repeat; horizontal repeat; soft-drop repeat. The initial wait and horizontal repeat require d to be non-empty. Soft-drop repeat requires a held soft-drop source. Any active repeat requires m to be playing. When no source is held, r is no active repeat. [OWNER CHOICE C7: when the game stops playing or the window loses focus, all held sources are cleared / held sources are kept and r becomes no active repeat.]
5. `ValidTouchDragState(t, m)`: t is Inactive, or Active with an origin, a horizontal and a vertical displacement in gesture coordinates, a Boolean recording whether movement has exceeded the tap allowance, and a Boolean recording whether the gesture controls the current piece. A gesture that controls the current piece requires m to be playing and a current piece to be present. Any transition that replaces the current piece sets that Boolean to false. [OWNER CHOICE C8: the capture is the Boolean above / the capture is an opaque piece-instance identity, which requires a D16 interpretation or amendment.]

### B12. Resting, lock-delay resets and gravity

1. `Resting(piece, b)` holds exactly when `Fits(piece, b)` and the piece shifted down by one row does not fit.
2. `ValidLockResetState(n)` holds exactly when n is a whole number from 0 to 15. [OWNER CHOICE C9: the pause reset is capped at 15 / the count may reach 16. The meaning of landing after the 15 resets are used is also an owner choice, a transition rule.] [OWNER CHOICE C10: the reference quantity for "reaching a lower row than before" is covered by D16's lock-delay reset count / needs a D16 clarification.]
3. The gravity interval is derived: max(0.25, 0.7 - 0.02 x (level - 1)) seconds. This document decides no timing tolerance.

### B13. Acceptance of an external saved representation

`Accept(x)` holds exactly when all of the following hold.

1. x is in a supported format: the current format, or the earlier format that also stored the level. [OWNER CHOICE C11b: a stored level in the earlier format is checked and an invalid one rejects the save / a stored level is not checked.]
2. Every piece value in x is rebuilt from the built-in definitions, and is a canonical piece or a PieceKind as the field requires.
3. x decodes to a state whose game core satisfies `ValidBoard`, `ValidCurrentPiece`, `ValidQueue`, `ValidBag` (a format that omits the bag decodes to a fresh full bag), `ValidScore`, `ValidHeldState` and `ValidLockResetState`, with the mode paused. The stored level, where present, is not authoritative.
4. The control state of the decoded state is at its initial values: no confirmation pending, no held sources, no active repeat, touch drag inactive. [OWNER CHOICE C11a: this, or another set of saved fields.]

An x for which `Accept(x)` does not hold is rejected whole and yields no state. Malformed external data is not a state. Nothing here decides when a save is forgotten, how a failed read or write behaves, which save is the last good save, or persistence ordering.

### B14. Ordinary valid state

`OrdinaryValid(S)` holds exactly when S is an ordinary state and all of the following hold: `ValidBoard`, `ValidCurrentPiece`, `ValidQueue`, `ValidBag`, `ValidScore`, `ValidHeldState`, `ValidMode`, `ValidConfirmationState`, `ValidLockResetState`, `ValidHeldDirectionState`, `ValidRepeatState`, `ValidTouchDragState`, and `ValidKnownTimerState`. Derived values (level, resting, landing position, gravity interval) are not independent conjuncts. Every successful committed legal transition ends in an ordinary state satisfying `OrdinaryValid`, under V1. The safe terminal/fault state is separate (B1).

### B15. Not decided here

- The meaning of "timer" in SAF-4 beyond B10, item 4.
- R2 and R4 persistence semantics, R3 timing tolerance and R5.
- The exact fault-reporting criterion and the meaning of "last good save".
- The written source of the canonical SRS block table.
- Transition rules and history properties, including PCE-3 spawning, hold-used resets, lock-delay resets, line clearing and the once-per-seven dealing guarantee.
- Scheduler, browser, storage and render trust decisions.
- Proof-obligation mappings and the contents of the O8 model input pack.
- Implementation correctness and the classification of any finding.
