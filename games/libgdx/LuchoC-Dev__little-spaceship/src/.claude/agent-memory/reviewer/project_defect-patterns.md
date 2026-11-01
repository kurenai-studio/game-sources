---
name: defect-patterns
description: The recurring shapes of defect found when auditing this repo — where to look first in a phase review, including second-round, data-driven, seam, design-fidelity, workflow-enforcement and cross-agent-handoff passes
metadata:
  type: project
---

Defect patterns observed auditing phase 01 (`feat/core-foundations`, PR #2). None of them are visible to a grep, and none of them failed a test.

**Why:** this project defends its invariants with self-written architecture tests and with a status/PR narrative. Both can be *narrower or staler than they claim* while everything stays green, so the audit has to check the claim against the check, not just run the check.

**How to apply:** on any phase review, walk these before reading the implementation line by line.

1. **An architecture test whose scope is narrower than the criterion it is cited for.** Read the test's package/class filter, not its javadoc. Phase 01's boundary check inspected only two of the three core layers while the plan's criterion and the PR table said "no public type in core". The test was still useful; the *claim* was overstated.
2. **Public accessors with zero call sites that hand out a mutable internal.** Grep the accessor name across `src/main` and `src/test`; a getter used by nobody is usually a boundary hole that a later phase will walk into. Cross-check it against the "no abstraction without a real case in the MVP" invariant, which catches it on two grounds at once.
3. **Two ways to destroy/mutate the same state, only one of which is safe.** Whenever a class documents "the caller always does X", check whether the API also allows not-X and what happens then. Ghost state that survives destruction is the shape this takes here.
4. **Agent memory under `.claude/agent-memory/` contradicting `docs/plan/*/status.md`.** Memory gets committed mid-phase and then the phase moves on; the memory file is not updated. Diff the two whenever both changed on the same branch.
5. **Docs conventions.** The English-only rule is absolute outside `docs/sources/`, and `spikes/` is already fully Spanish, so new files added there inherit the violation. Check whether an offending line is pre-existing on `main` before treating it as introduced by the PR — `git diff main...HEAD -- <file>` settles it and changes whether it can block.

Three more, from phase 02 (`feat/core-mechanics-02`, PR #10). Same family: the code was sound, the *claims attached to it* were not.

6. **A quoted measurement whose benchmark has a different data shape than the code citing it.** This repo justifies design choices with numbers from `spikes/web-viability/` and `docs/planning/11-technical-prototype-results.md`, and those numbers get copied into javadoc, commit bodies and PR descriptions. Open the benchmark source before accepting the citation: the collision figure was measured on flat per-layer `float[]` arrays, while the ECS implementation scans a whole `ComponentStore` per pair — same algorithm class, ~50× the operation count and a much costlier inner iteration. The *decision* was right and the *evidence* did not cover it.
7. **A criterion whose enforcement is split between `core` and an adapter that does not exist yet.** The test then asserts the trivial half and the criterion gets a green tick. "Keyboard and mouse in opposite directions cancel" was tested by feeding a zero vector and asserting no movement. Ask, for every criterion: which module actually contains the rule? If the answer is a module with no code yet, the criterion is deferred, not met.
8. **Forward-looking notes about how a *future* phase will reuse something.** They are written from intent and never compiled. Verify them against the declaration they depend on — `SystemOrder`'s ordinals are the usual one, and `WEAPON` sits *before* `COLLISION`, which invalidated a note saying a future `WeaponSystem` could read the collision buffer unchanged. These notes live in both `status.md` and agent memory, so the same wrong claim usually appears twice.

Also worth checking every time: whether the branch edited its own `plan.md` acceptance criteria. Phase 01 did, and the edit *raised* the bar rather than lowering it, which is fine — but it has to be read, not assumed.

And the counter-pattern, so the review stays calibrated: phase 02's agent memory did **not** repeat pattern 4 in the dangerous direction — it recorded the invented rules honestly, including one that contradicts a literal line of the spec. What it did instead was absorb phase progress from `status.md`. Both are worth naming, but only one of them is a defect in the code.

## Second-round passes have their own two shapes

From the round-2 pass on PR #10, where every finding had been addressed and the honest result was "accept, nothing new".

9. **A fix that relocates the identity of a subject, leaving the old identifier guarding nothing.** Phase 02's collision fix stopped matching the player by `CollisionLayer.PLAYER` and started resolving it through the `Player` component. Correct, faster, and it left `CollisionLayer.PLAYER` referenced by no production code at all — so a player collider on the wrong layer is now caught by nothing, and a future player-side collidable that is a *separate entity* would not be detected. On any round-2 pass, ask of each fix: what did the old mechanism used to catch that nothing catches now? Grep the old identifier across `src/main` and `src/test` separately — production-empty is the tell.
10. **A refactor sold as cost-only that also reorders an output buffer.** `CollisionSystem` writes `World.collisionHits()` and `DamageSystem` consumes it *in order*, so append order is behaviour, not an implementation detail. The reorder was safe here only because the two pairs `DamageSystem` consumes kept their relative order and the moved pair has no consumer yet. Nothing in the suite pinned that — every `CollisionSystemTest` case emits exactly one hit, so cross-pair order is untested. When a detection or event loop is restructured, reconstruct the emitted sequence by hand for the fixture population; do not expect a test to catch it.

Related to 10: **`DamageReplayTest` is not a regression net.** It runs the same build twice and compares fingerprints, with no golden value committed, so it proves determinism *within* a build and cannot detect a refactor that changes the outcome. Do not treat "the replay test passes" as evidence that behaviour was preserved across a diff.

## Four more from phase 04 (`feat/content-pipeline`, PR #16), where content became data

This phase's defects are the *data-driven* family: the code is generic and correct, and what leaks is
a rule that used to be in Java and is now a JSON field nobody validates.

11. **A geometric guarantee in a class javadoc that only holds for the zero case the tests use.**
    `SpawnSystem` promised every enemy "starts fully off-screen regardless of its size" while adding
    only the *entity's* radius, not the *formation's* vertical extent — so any slot with a negative
    `offsetY` spawns on-screen, and the phase's own `diagonal` fixture had two. The tests asserted
    position only for flat formations. Whenever a javadoc says "always" about a computed position,
    reconstruct the value by hand for the least flat fixture in the branch, not the first one.
12. **An optional content field whose default is the minority value of the roster it configures.**
    `spec.flag("fragile", false)` decides the crash rule for six archetypes, four of which are
    fragile. Omitting the field in JSON silently inverts a spec rule, with the symptom appearing in
    `DamageSystem`. For every optional field a factory reads, ask: what fraction of the real content
    wants the default, and what game rule flips when it is wrong?
13. **Typed optional accessors that treat "present but wrongly typed" as "absent".** `MapComponentSpec`
    fails loudly for required fields and silently defaults for optional ones, while its javadoc claims
    the loud behaviour for all of them. This directly defeats the "fails naming the offending id, not
    an NPE" criterion, and only for the half nobody tests. Read the *optional* overload, not the
    required one — the required one is always the correct one.
14. **An extension seam wired to a `private static final`.** `ComponentFactoryRegistry.register` is
    public with zero production callers; `SpawnSystem` holds one registry as a private static built
    from `withDefaults()`, so nothing outside `core` can substitute or extend it. Pattern 2's
    "accessor with no call site" in its builder form: the seam exists, is tested against a registry
    the test constructs itself, and no production path can ever be that registry.

Also from phase 04, and worth keeping the calibration honest: **every citation in the branch checked
out** — `docs/design/04-hud-layout.md:25` for the 270 playfield height, `02-sprite-sizes.md:38` and
`:77-84` for radii and ids, `10-mvp-initial-values.md:105-115` for the score table, and the
`SystemOrder` ordinals in `status.md`. After two phases where patterns 6 and 8 both fired, the
citation check came back clean. Run it anyway; do not assume it will fail.

The criteria-table defect (pattern 7) reappeared exactly once, narrowed to a single row: "all content
ids are in English" ticked met on the strength of test fixtures, in a branch with no content files.
The other five rows hedged honestly. Also new in that document: a plan **task** half-built
(trajectories yes, firing patterns no) with the reason recorded in prose but the task surfaced as
outstanding nowhere. Check `plan.md`'s task list against the branch, not only its criteria list —
the criteria table is not a superset of the tasks.

## Four more from phase 05 (`feat/game-systems`, PR #22), where systems started consuming input and killing at range

This phase's family is the *seam* one: every piece was individually correct and the defect lived in
the join between two of them, which is why nothing failed and nobody noticed.

15. **An edge-shaped input consumed once per tick, under a loop that replays one frame's input across
    N ticks.** `GameLoop.advance` feeds the *same* `InputFrame` to every tick a frame produces, and
    says so in its own javadoc; `InputAdapter` debounces with `isKeyJustPressed`, which is an edge
    per *render frame*. `BombSystem` spends a charge on every tick where `input.bomb()` is true, so
    one press costs two charges at 30 fps and up to the whole cap after a stall. Neither layer is
    wrong on its own and neither owns the tick-level edge. For any new system, ask whether the field
    it reads from `InputFrame` is a level or an edge, and if it is an edge, whether the consumer is
    idempotent across a repeated frame. `fire()` is a level and is fine; `bomb()` is the first edge.
16. **A stage inserted before the detection stage, when all it does is *mark* destruction.**
    `markForDestruction` does not remove the collider and `CollisionSystem` does not filter
    `pendingDestruction`, so `BOMB` at ordinal 3 means everything the bomb "cleared" still generates
    a `CollisionHit` at ordinal 6 and still costs the player a life at 7. The stage javadoc argued
    its placement against `SPAWN` and never mentioned `COLLISION`. Whenever a stage is added, list
    what it *marks* rather than destroys, then read forward through every later stage that iterates
    the same store — the answer is almost never in the javadoc that justified the placement.
17. **A whole-screen effect with no screen bound, in a world that deliberately spawns off-screen.**
    `BombSystem.detonate` walks every enemy collider; `SpawnSystem` puts every wave at
    `y = 270 + radius` and above. The spec says "on screen". The branch's own `BombReplayTest`
    scores off enemies 93% above the playfield, and its `bombActuallyScoredSomething` guard asserts
    on exactly that score. Any system whose scope is "the screen" needs a bound: grep it for
    `PLAYFIELD_HEIGHT`/`PLAYFIELD_WIDTH`, and if neither appears the bound is missing.
18. **A hand-enumerated completeness test that quietly stopped being complete.**
    `WorldTest.destroyStripsEveryComponent` sets four components and asserts four stores are empty,
    while its javadoc claims to be the guard against forgetting a store in `destroyEntity`. `World`
    now has thirteen. `destroyEntity` was correct anyway — by hand, not by check — and has been
    since phase 02. Count the stores declared in `World` against the assertions in that test on every
    phase that adds a component; the drift is invisible and the failure mode (a `Health` left on a
    recycled slot) is silent.

Calibration from this phase, in both directions: the author's verified/inferred split in `status.md`
held up on every point I checked, and the criteria table hedged honestly on the two rows that
deserved it (the completion-bonus reading, the replay's missing golden). But pattern 7's cousin fired
again — plan **task** 8 (guaranteed drops) is unbuilt, `level-01.json` carries two of the four drops,
and `status.md` says "the phase's task list is complete". Read the task list against the content
files, not against the criteria table.

## Round 2 on PR #22: what a *correct* response to a rejection looks like

Recorded because "accept, nothing new" is hard to calibrate and this round is a good reference for
the shape of an honest fix.

- **A replay fixture rewritten after a fix is not automatically a whitewash.** The test to apply:
  (a) did the fix make the old scenario *vacuous* rather than *failing* — here the old bomb presses
  at ticks 65/185 landed on enemies now correctly out of reach, so the run would have scored zero
  and proved nothing; (b) is the behaviour the old fixture accidentally exposed now pinned
  somewhere deliberate — here three unit tests, above/exactly-at/inside the 270 edge; (c) did the
  rewritten fixture gain a non-vacuity assertion. Three yeses is a correct response, not a
  disappeared failure.
- **A golden fingerprint is worth what its fields encode, and it usually does not pin the fix that
  prompted it.** `BombReplayTest`'s `score=200 lives=3 bombs=0 entities=4` would not move if the
  on-screen bound were deleted (the scripted presses now land on visible enemies either way), and
  `LevelScoreReplayTest`'s does not encode shield/attachment state. That is fine — the golden is a
  net for *unintended* drift, the unit tests are the net for the rule — but do not accept "the
  golden pins the fix" as an argument.
- **Boxed-`Integer` set lookups in a per-tick O(n^2) loop are within budget here.** `CollisionSystem`
  builds `Set.of()` when nothing is pending (no allocation) and only boxes at the `contains(int)`
  call sites. At MVP collider counts that is a few thousand short-lived `Integer`s per tick against
  ~10 ms of drawing — not a finding under this project's own "drawing is the cost" rule. If it ever
  matters, ordering the layer filter before the `contains` removes most of it for free.
- **A log-once `Set<String>` keyed on sprite ids is bounded** as long as every id is either a
  compile-time constant or composed from a value validated against a closed set — after round 2,
  `SpawnSystem` rejects an unrecognised `drop` id at spawn time, so `"pickup-" + drop.pickupId`
  cannot invent new strings. Check the validation, not the `Set`.
- **A statement of intent inside `status.md` becomes checkable in the next round.** F11 promised
  "every commit from this point on respects the limit"; one round-2 subject is 75 characters. Cheap
  to verify (`git log --format='%s' <base>..HEAD | awk '{print length}'`) and exactly the class of
  claim this repo tends to leave behind.
- **Pattern 4 again, in its slow form:** `core-domain`'s memory closes by pointing at "the exact
  `game`-module compile breakage this phase leaves behind", which round 2's `status.md` records as
  closed. The memory line was true when written and nobody revisits it — diff memory against
  `status.md` whenever both changed on the branch, in both directions.

See [[audit-techniques]] for how to confirm these cheaply without touching the repo, and [[review-tooling-and-memory-placement]] for the operational traps around posting the verdict.

## Six more from phase 06 (`feat/hud-and-screens`, PR #26), where a design document became screens

This phase's family is the *fidelity* one: the code runs, the owner played it, and what drifted is
the distance between the document that was drawn and the thing that was built. Nothing here fails a
test either, and "the owner confirmed it works" does not touch any of it.

19. **A game rule reimplemented in the presentation layer while `core`'s tested copy stays uncalled.**
    `PlayScreen` computed `lifeCompletionBonus() * lives + bombCompletionBonus() * bombs` inline the
    same pass that *edited* `ScoreSystem.completionBonus`'s javadoc to explain why it has no caller.
    Two implementations of one rule in two modules, and the tested one is dead. Whenever `game` reads
    a `PlayerStatus` field and then does arithmetic on it, ask which document that arithmetic comes
    from and grep `core` for the same formula — this is pattern 2 (accessor with no call site) seen
    from the other end, and the giveaway is a `static` method in `core` whose only callers are tests.
20. **A domain field justified by a design document, consumed by something that document assigns
    elsewhere.** `Invulnerable.source` was added to `core` because "`04-hud-layout.md` asks the HUD to
    draw the three sources differently *on the ship*". The ship treatment was never built; the only
    consumer is a plate widget the same document assigns to the power-up alone. The field is still
    the least-bad option — read the *consumer* before accepting the justification, and check whether
    the cited section is the one the code implements.
21. **A spec bullet list ticked as a whole when one bullet is unbuilt.** `02-mvp-functional-spec.md`'s
    HUD section has eight bullets; seven were drawn and "clear feedback for hits and for losing
    upgrades" was not, while the criterion "the HUD shows everything the spec requires" was marked
    **earned**. Read the source list item by item against the implementation; do not accept a
    criterion that quotes a document as evidence that the whole document was satisfied. In this case
    the missing half was not blocked on `core` at all — it is a frame-over-frame diff of
    `PlayerStatus` — which is worth checking before believing "deferred".
22. **"Everything else is unchanged from the first pass's assessment", where the first pass assessed
    two rows of seven.** A criteria table can be dodged by reference as well as by overclaim. When a
    status pass defers to an earlier one, open the earlier one and count the rows it actually
    evaluated.
23. **Batching broken by texture alternation, in the phase whose criterion is batching.** `new
    BitmapFont()` twice produces two distinct `Texture`s even for the same bundled font, and a HUD
    that alternates label -> filled rects -> label rebinds once per switch. ~12-14 binds per frame
    from `HudRenderer` alone. Absolutely trivial at this scale and *not* worth optimising — but it is
    the literal task-12 criterion, and it is the finding that matters more than any allocation count
    under this project's own "drawing is the cost" rule. Reconstruct the bind sequence by reading
    the draw method top to bottom; no profiler needed.
24. **A pixel-exact mock is a checkable artefact, and nobody checks it.** `docs/design/mockups/src/
    05-screens.js` draws all six screens as explicit calls. Diffing those calls against the shipped
    screens found six omissions (title rule, credits entry, pause plate, menu subtitle/footer,
    unpadded defeat score, stat bars turned into raw numbers) that "the owner played the build and
    it works" cannot surface, because reachability and fidelity are different claims. The
    counter-example in the same branch: the omitted second ship slot *is* documented with a reason,
    which is how a deviation should look.

Calibration from this phase, and it matters: **the per-frame allocation the parent flagged as the
invariant most at risk turned out not to be a defect.** `WorldView.player()`'s fresh record plus the
zero-padded score come to ~6-10 short-lived objects per frame, constant in entity count.
`12-architecture.md:159` states the intent as "not one object per *entity* per frame", which is
intact; only `03-first-playable/plan.md:45`'s absolute phrasing is now literally false. The honest
finding was the stale criterion, not the allocation. Do not manufacture the O(1) case into a defect.

## Round 2 on PR #26: presentation timers, and the limit of a snapshot contract

The verdict was accept. What is worth keeping is not the findings — they were all notes — but four
shapes that will recur the moment presentation grows.

25. **A snapshot contract can report *what changed*, never *what happened*.** Phase 06 derives five
    of the six feedback events from a frame-over-frame diff of `PlayerStatus`, which works only
    because they are monotone state transitions. The sixth (pickup collected at maximum) is
    indistinguishable from an ordinary kill, because `maxedPickupBonus` and `enemy-tank`'s score are
    both 500. Whenever presentation is asked to react to an *event*, check whether the port hands it
    a state or an occurrence. The seam for occurrences already exists and is empty:
    `core.port.GameEventSink`, `core.domain.event.GameEvent` (a marker interface with **zero**
    implementations) and `GameEventQueue` (buffers, drains in emission order after the tick), with
    `PlayScreen` passing `event -> { }`. Audio in phase 08 needs the same distinction, so the first
    concrete `GameEvent` closes both at once.
26. **Presentation timers counted in `draw()` calls, against a design table written in simulation
    ticks.** `HudRenderer`'s flash counters and `WorldRenderer.sourceTicks` advance once per render
    frame, while `04-hud-layout.md` specifies ticks of 1/60. Desktop pins the two together
    (`DesktopLauncher` sets `useVsync(true)` **and** `setForegroundFPS(60)`); the web target paces
    off `requestAnimationFrame`, so a high-refresh display runs every blink and flash fast while the
    durations, which come from `BalanceValues` in seconds, do not move. Constants named `*_TICKS`
    that a render loop decrements are the tell.
27. **An identity duplicated as a literal across modules fails silently in both directions.**
    `WorldRenderer` matches the player by `"ship-basic"`, copied from `Simulation`'s
    `private static final SpriteId PLAYER_SPRITE`, because `SpriteVisitor.accept` carries no player
    flag. Rename either side and every ship-side treatment stops drawing with no compile error and
    no failing test. Distinguish this from a string that genuinely *crosses* the boundary
    (`PlayerStatus.attachmentId`), which cannot drift.
28. **A domain method that goes `public` to serve `World.View` escapes `PublicContractTest`
    entirely.** Its `BOUNDARY_PACKAGES` are `core.port` and `core.application` only, so
    `ScoreSystem.completionBonus(BalanceValues, Player)` — public, taking a mutable domain component
    — passes untouched. Not a breach in practice (`game` cannot obtain a `Player`), but the guard
    becomes the javadoc. Pattern 1 in its newest form: check the test's package filter every time a
    fix widens visibility inside `domain`.

Calibration, and it is the point of the round: the two claims the parent asked me to distrust —
hand-traced tick counts and a deliberate omission — both held. The counters set-draw-decrement in
one method, so a timer of N is visible for exactly N frames, no off-by-one anywhere; the omission
was the correct call and was documented rather than guessed. What the write-up does instead, twice,
is state an omission once in prose while the summary sentence beside it reads as complete. That is
the residual shape in this author's status documents, and it is a note, never a rejection.

## PR #30 (`feat/sprite-production`), art-only, no code — the clean-branch calibration case

Nine commits, docs/design only (`git diff --stat main...HEAD -- core game desktop web` is empty), so
invariants 1-6 could not be at risk structurally and the review became fidelity-checking a design
document against itself and against the PNGs it describes. Worth recording because this branch
passed almost everything, and knowing what "clean" looks like here matters as much as the defect
catalogue.

29. **A frozen sizing table not updated when a later document in the *same PR* supersedes its
    granularity.** `02-sprite-sizes.md`'s boss row still reads one sprite, `boss-l1`, 119x87; the
    same branch's `06-boss-presentation.md` splits the boss into `boss-core`/`boss-pod`/`boss-arm`
    (47x87/25x25/31x45) and says explicitly "five sprites, not one image". The radii and offsets
    agree byte-for-byte between the two documents — only the sprite-id/dimension row was left
    stale. A note, not a blocker: whenever a phase adds a document that supersedes part of an
    earlier frozen one, diff the specific row, not just the shared numbers (radius, offset), since
    those are what people check first and the id/dimension column is what silently drifts.
30. **A Skin's `skin.json` loaded through `Skin(FileHandle, TextureAtlas)` is exactly the reflective
    `Json` class the web-pitfalls section warns about**, and the design doc for it
    (`docs/design/07-skin.md`) commits to that loading contract (`skin.load(Gdx.files.internal(...))`)
    without mentioning TeaVM reflection config. Not a defect on an art-only branch with no code, and
    scene2d's own Skin format has no non-reflective loader — but it is a suspicion worth handing to
    whichever phase writes the `Skin.load` call: confirm the TeaVM reflection declarations exist for
    every style class named in the JSON before that call ships, since CLAUDE.md's own JSON rule reads
    as an absolute and this is the one legitimate exception to it.
31. **Numeric self-consistency across a design PR is checkable in full, cheaply.** Every measurable
    claim in this branch's `status.md` table checked out against the committed PNGs: frame counts
    (29 = 5+6+8+10), per-frame sprite sizes (21/31/47/95, read via `struct.unpack` on each PNG's IHDR),
    font sheet dimensions (96x60, 128x78), and the boss's ±59 px arm reach recomputed by hand from
    odd-width sprite geometry (half-width to edge is 15, not 15.5, because rule 1 makes every
    dimension odd with a true centre pixel). Zero mismatches. This is the counter-example to keep
    calibration honest: "read every number, trust none of them until reconstructed" does not always
    find something, and this branch is the proof it does not have to.

## Phase 08 (`feat/audio`, PR #31): clean, and worth recording *why* nothing fired

Five commits, 29 files, a synthesised-WAV generator, a runtime, and volume sliders. Verdict was
accept — no invariant violation, no misclaimed criterion. Recording this one because "I found
nothing" needs the same rigor as a rejection, and because two shapes from earlier phases were
present here in their *safe* form, which is the useful contrast to keep.

- **Pattern 27 (identity duplicated as a literal across modules) recurred, in the form the project
  already has precedent for accepting.** `AudioDirector.SHOT_P1`/`SHOT_P2` copy `WeaponSystem`'s
  private `SpriteId("shot-p1"/"shot-p2")` literals verbatim, exactly the way `WorldRenderer.
  PLAYER_SPRITE_ID` already does for the ship. Confirmed both sides still match by grep. Still a
  real fragility (rename either side and the shoot cue goes silent with no compile error and no
  failing test) — worth a note every time, not a blocker, since the project already made this
  trade-off once and it holds for the same reason: no `core.port` type currently carries a role tag,
  and adding one without a second real case would trip invariant 6.
- **A "blocked, waiting on another branch" claim is a citation, and checks out the same way any
  other citation does.** `status.md` asks `core-domain` for an `EnemyDestroyed` event and says
  `WorldView.bossStatus()` "does not exist on `main` yet — it is on `feat/boss`". Both grepped to
  zero hits in `core/src/main` and `game/src/main` on this branch. The task's own framing (context
  section) said not to report this as a defect if true; verifying it cheaply is still worth doing
  rather than taking the framing on faith — it would have been a real finding if the grep had come
  back non-empty.
- **A design-time-only tool living inside a module that TeaVM compiles is not a risk *while the web
  build stays commented out*.** `game/.../tools/audio/{Wav,Synth,GenerateAudio}.java` use
  `java.nio.file`, which has no TeaVM guarantee, but `web/build.gradle.kts`'s `gdxTeaVM {}` block is
  entirely commented out (phase 03 reverted it, phase 09 owns bringing it back). So nothing compiles
  those classes for the web target *yet*. This is a suspicion to hand forward for phase 09's audit,
  not a defect now — the distinction is the same one `audit-techniques.md` already draws for
  `List.copyOf`: unverifiable is not the same as wrong. Check whether `tools.audio` gets excluded
  from the TeaVM source set (or moved to a separate Gradle source set entirely) when phase 09 lands.
- **The counter-example to go with pattern 21/22:** the acceptance criterion "audio starts without
  an error in the browser, verified on a real browser" is *not* claimed met — `status.md` says
  outright "did not confirm by ear; this sandboxed environment has no audio capture... phase 09's
  real-browser pass is still the first time anyone actually listens to this." Same for task 5
  (animations): marked "in progress" with the exact missing pieces named, not folded into "done".
  This is what an honest partial-completion entry looks like next to patterns 21/22's dishonest one.

## PR #29 (`feat/boss`), phase 07 — a coordinator-committed last commit that held up, and a citation gap in what a replay actually covers

The largest branch reviewed so far (46 files, 16 commits) and the cleanest on the invariants: no
`com.badlogic.gdx` in `core`, no `Math.random`/clock read, no `Thread`/`ExecutorService`, JSON read
through `JsonReader`/`JsonValue` only, `SystemOrder` extended with two new stages (`SPAWNER`,
`ENEMY_WEAPON`, `BOSS`) each placed with a written reason and none out of order. Worth recording
because it is the reference case for a good last-minute, unreviewed commit rather than a bad one.

32. **A commit finished by the coordinator after a spend-limit cut, with a self-reported test count,
    checked out exactly.** `b33f302`'s message claims "277 tests green at the point of the cut";
    `grep -rn "@Test" core/src/test --include=*.java | wc -l` on the tree as committed returns exactly
    277. The commit itself is otherwise unremarkable: a new component (`EnemyWeapon`), a new stateless
    system (`EnemyWeaponSystem`) mirroring `SpawnerSystem`'s own shape, and `CleanupSystem` emitting
    `EnemyDestroyed` — the first concrete `GameEvent` this codebase has built, closing the empty seam
    pattern 25 named two phases ago. No invariant violated, no shortcut taken under pressure. The
    lesson is not "trust a coordinator-committed cut" but "the self-reported number is free to check
    and worth checking every time" — `grep -c` here, not a rebuild.
33. **A status document can go stale from a commit that lands *after* it, not just from one that
    precedes it.** `docs/plan/07-boss/status.md` (dated the same day) lists "no enemy `weapon`
    component factory exists yet" as an open gap in its own "gap this phase did not close" section —
    true when written, and then the branch's own next and final commit closed exactly that gap.
    Pattern 4 usually fires because memory or status stops being updated; here the *order* inverted
    it — check commit timestamps against a status doc's own date before treating a documented gap as
    still open, in either direction.
34. **A criterion's replay evidence and its unit-test evidence can point at different scenarios, only
    one of which is boss-specific.** The acceptance table cites `BossReplayTest.defeatIsDeterministic`
    for "the boss can... kill the player, to the right screen", but `defeatContent()` in that file
    never calls `.withBoss(...)` — `hasBoss("level-01")` is false for that scenario, so it exercises
    the ordinary, pre-phase-07 rammer-kills-the-player path, not a boss fight. The actual boss-specific
    rule (`DEFEATED` wins a same-tick tie against `bossDefeated`) is genuinely covered, just at the
    unit level (`BossSystemTest.defeatWinsATieWithBossDefeat`, which does call `.withBoss(...)`), not
    by the full-pipeline replay the criteria table cites for it. Worth a follow-up, not a blocker:
    whenever a criteria table cites a "replay" test for a rule, open the fixture builder and check it
    actually configures the subsystem the rule is about, separately from checking that a unit test
    somewhere does.
35. **Content built ahead of a real consumer, correctly labelled as such, in the same commit that
    builds the capability.** `EnemyWeaponSystem` and its `"weapon"` `ComponentFactoryRegistry` entry
    ship in `b33f302`, but `assets/data/enemies.json`'s `enemy-shooter` carries no `"weapon"`
    component — the capability exists and nothing in shipped content uses it yet. Not a defect: this
    is `game`/content's job in a later step, not `core-domain`'s in this commit, and nothing in the
    commit or `status.md` overclaims it as wired. Recorded as the calibration case for pattern 14 (an
    extension seam wired to nothing) — the difference here is the seam *is* reachable through the
    ordinary content pipeline (`ComponentFactoryRegistry.withDefaults()`, not a private static test
    fixture), so it is a gap to close later, not a boundary hole.

Calibration from this phase: the drop-slot fix (issue #23, `SpawnEvent`'s sixth field) and the
`level-01.json` content pass both cross-checked cleanly against their own stated verification —
every `atX`, `dropSlot` and drop-kind claim in `status.md`'s "What was verified" section reproduces
by reading the file. The one place content underclaimed rather than overclaimed: `status.md` flags
`:game:compileJava` as failing before the boss-loading fix landed, and it genuinely did (confirmed by
reading `JsonContentSource` before and after `2ddab6e`) — an honest, checkable "not yet" rather than a
premature "done".

## PR #35 (`ci/github-actions`), phase 09 task 7 — a status document falsified by its own branch's later commit

The workflow itself was clean: no `core`/`game`/`desktop`/`web` source touched, no dependency
added, commit hygiene perfect, and the desktop-build and core-test criteria were confirmed by
reading real GitHub Actions run logs (`:desktop:compileJava/:jar/:assemble/:build`,
`:core:test`, both `BUILD SUCCESSFUL`), not assumed from the YAML. The one defect was in prose,
and it is a new variant of pattern 4/33 worth naming on its own.

36. **A status document's claim is falsified by a *later commit on the same branch*, and the
    correction is skipped even though it was possible.** `docs/plan/09-web-ci-release/status.md`
    said "[the workflow] has never been run on an actual GitHub Actions runner — that only happens
    once the PR is opened", written in commit `4e11d87`. By the time that commit's own push
    triggered a run, the run had already failed (`gradlew: Permission denied`, exit 126) on a real
    runner. The branch's next and *final* commit, `8542034`, fixed exactly that failure — proving
    the claim wrong from inside the same branch — and two more real runs then succeeded. Nothing
    after `8542034` corrected `status.md`. This is pattern 33 in its worse form: that pattern is
    about a gap closing silently after a status doc is written (unavoidable, order is just what it
    is); here the branch's own subsequent commit *disproved* the doc's claim and the author had
    every opportunity to fix the sentence and didn't. The tell is generic and cheap: whenever a
    status doc makes a claim about "has/hasn't happened yet", check it against every commit that
    lands *after* that doc on the same branch, not just against commits that precede it — `git log
    --format="%H %ai %s" <the doc's commit>..HEAD` on the branch is enough, no run logs needed.
    The same sentence, near-verbatim, was also carried into
    `.claude/agent-memory/game-presentation/project_github-actions-ci-shape.md` ("the workflow
    itself is untested until GitHub Actions actually runs it on the opened PR") — confirming that
    pattern 4 (memory contradicting `status.md`) and this new variant are often the *same* wrong
    sentence, copy-pasted into both stores, not two independent errors. Check both files for the
    identical claim, not just one.

Calibration: the coordinator had independently pushed a deliberate failing-test run on a
throwaway branch specifically to demonstrate "CI fails when tests fail" — a criterion this review
had flagged as inferred rather than observed. `290 tests completed, 1 failed`,
`Task :core:test FAILED`, `BUILD FAILED`, confirmed on a real runner before the throwaway branch
was deleted. Recorded here because it is the calibration case in the other direction from pattern
36: a criterion that looked like a reasonable inference from Gradle's own behaviour is still
worth demonstrating directly when the cost of doing so is one throwaway push, and "the tool
guarantees this" is a weaker form of evidence than this project otherwise insists on.

## PR #37 (`docs/readme`), phase 09 task 9 — the README itself was clean; a coordinator's own fix commit left a sibling document stale

Docs-only branch (`README.md` + `docs/plan/09-web-ci-release/status.md`, confirmed by
`git diff main...HEAD --stat`), and every checkable claim in the README reproduced exactly:
289 tests (summed `tests="..."` across `core/build/test-results/test/*.xml` after
`./gradlew core:test --rerun`), port 8080 (not `spikes/web-viability/README.md`'s stale 8181 —
its own `build.gradle.kts` hardcodes `serverPort.set(8181)`, confirming *that* file is wrong, not
the README), every Gradle task name (`desktop:run`, `web:gdx_teavm_web_js_run`,
`web:gdx_teavm_web_js_build -Prelease`) existing verbatim, the controls table matching
`InputAdapter.java` line for line including "Escape releases pointer lock" and the additive
keyboard+mouse rule, and all six architectural invariant claims (no `com.badlogic.gdx` / no
`Math.random` / no `Thread`-family / no `Json` reflection class in `core` or `game`, `game` never
importing `core.domain`, `core/build.gradle.kts` declaring zero dependencies).

37. **A coordinator's correction commit fixed the claim in the document a stranger reads and left
    the identical stale claim in the document only the team reads.** Commit `9406151` (the final
    commit on the branch) rewrote README.md's License section from "no license file yet" to
    "[MIT](LICENSE)" — correct, `LICENSE` (MIT, added by `5c5d610`) really does exist. But
    `docs/plan/09-web-ci-release/status.md`, edited by an *earlier* commit on the same branch
    (`f70c6e3`, timestamped 3 minutes before `9406151`), still asserts in present tense "**Not
    done in this issue: no LICENSE file exists**" after the merge — and `9406151` touched only
    `README.md`, never revisiting the sibling doc that made the same now-false claim. This is
    pattern 33/36 with the fix and the miss in the *same commit*: the author demonstrably knew
    the claim was wrong (that is what `9406151` is) and fixed it in exactly one of the two places
    it appeared. The generic tell from pattern 36 still applies and would have caught this in
    seconds: `git log --format="%H %ai %s" <doc's commit>..HEAD` on the branch, then grep the doc
    for anything that commit range's diff touches.

Calibration, in the direction that matters for judgement: the *other* correction in the same
commit (downgrading "Chrome, Firefox, Edge" to "Chrome and Firefox... verified by hand") is
accurate and complete in the one place it needed to be — the README, the public-facing document —
and status.md never made the Edge claim to begin with, so there was nothing to leave stale there.
One correction was fully propagated, the sibling one was not; the difference was not effort, the
Edge fix and the License fix are the same size, so treat "the coordinator already fixed X" as a
claim to verify per-document, not a fact that generalises across the branch's two docs once
confirmed in one.

## Phase 11a (`phase/11a-rule-asserting-tests`, PRs #100–#107) — a clean branch, and the shape a legitimate "argue with a routing decision" prompt takes

38. **A phase can hold up on every axis at once, and the honest report is "accept."** Checked: the
    `git diff dev..phase -- '*/src/main/*'` claim (exactly `Rng.java` comment lines + the new
    `rngparity` module, confirmed by running the diff myself); the boss-replay geometry in
    `BossReplayTest.podKillSimulation` (recomputed the pod/arm/x-distance arithmetic by hand —
    `[[project_boss-replay-geometry]]` in `test-engineer`'s own memory independently derives the
    same numbers, which is a second, unprompted confirmation rather than trusting one narrative);
    the `alive`-conjunct-is-dead-code finding (read `World.View.outcome()` directly — the early
    `state.lives <= 0` guard really does make the later `&& alive` unreachable-false in both
    branches); every rule-to-test table row in `status.md` for tasks 2–4 against the actual test
    bodies; both architecture-test narrowings (`ALLOWED_JAVA_UTIL_TYPES` against a grep of every
    `java.util.*` import in `core/port`+`core/application`, `DOMAIN_CONTRACT` whitelist against the
    one real `GameEventSink` import) for both under- and over-narrowing. Nothing failed. Do not
    manufacture a finding to justify review effort — this phase's report was "accept, one thing
    worth arguing with" and that was the true state.
39. **A "route this open item to a later phase" decision (D5) can be correct about the concrete
    assertions and still bundle in a separable, format-independent sub-question.** #19 asks two
    things at once: what to assert about `JsonContentSource`'s error messages (genuinely blocked on
    11b's rewrite of that class) and how to unit-test anything depending on `FileHandle` without
    dragging LWJGL into the suite (a test-harness design question, independent of which JSON shape
    11b lands on). D5 routed the whole issue to the 12 group on the first ground without addressing
    that the second question could be resolved earlier. Worth naming as "worth arguing with" rather
    than a defect: nobody had written the harness question down as separable before this reading.

## Calibration from phase 11b task 1 (`feat/entity-lifetime`, PR #116), a clean branch

Recorded so "accept, nothing new" stays calibrated against a real example, not just the rejections.

Every checkable claim in the branch held: the `SAFETY_MARGIN` derivation (`column-3` 44-unit spread x
`enemy-carrier` 15-unit radius -> y=329, 314 from its own edge) reproduced exactly by hand from
`assets/data/formations.json`/`enemies.json` and `SpawnSystem.positionSpawned`'s formula; the escape
rule (no score, no drop, no `EnemyDestroyed`) verified by reading `ScoreSystem`, `CleanupSystem` and
`ComponentStore.remove` and confirmed by a full-pipeline unit test in the same PR
(`anEscapedEnemyGivesNothing`); the two-pass structure in `expireEnemies` genuinely needed (`Component
Store.remove` is a swap-remove that reorders the dense array mid-iteration — confirmed by reading the
class) and the two-pass version has no version of the same bug (pass 2 iterates a separate `ArrayList`,
never the store pass 1 walked); `CleanupSystem`'s "converges uniformly" claim stayed true with zero
change to that class, because the strip happens upstream and both consumers were already conditional
on component presence. Full clean build (`./gradlew clean build --rerun-tasks`) green across all five
modules including `web`; 310 core tests, 0 failures/skipped/errors.

The one thing worth naming as a *pattern to watch for, not a defect here*: a worst-case measurement
combining the extreme value of two independent data files (largest formation spread, largest enemy
radius) is only a real bound if the spawn system actually allows that combination to occur — checked
by reading `SpawnSystem.spawnWave`, which assigns one `enemyId` to every slot of a formation, so any
(formation, enemy) pairing the schema allows is reachable by a future wave even if no current level
uses it. Worth re-deriving on every phase that touches `formations.json`, `enemies.json`, or the
spawn-positioning formula, since the bound silently goes stale if either file's extremes move.

Also worth naming: the `new ArrayList<>()` allocated once per tick in `LifetimeSystem.expireEnemies`
(populated in the near-totality of ticks with nothing) is the same shape as the phase 05 boxed-`Integer`
finding calibrated as noise — thousands of tiny, short-lived allocations across a multi-minute level
against ~10ms/frame of drawing cost. Named, not blocking.

## PR #121 (`feat/wave-spawning`, phase 11b task 4), a hand-off between two agents on the same branch

`SpawnSystem` migrated off a flat timeline cursor onto `ContentSource.placements(String)` +
`wave(String)`, with a genuine mid-task hand-off (first author killed by a spend limit, second
author inherited the uncommitted diff). Verdict: accept. Full clean build
(`./gradlew clean build --console=plain`, `little-spaceship-wave-spawn` worktree) green across all
five modules; `core/build/test-results/test` aggregated to 322 tests, 0 failures/skipped/errors.
`pre-pr-check --base phase/11b-wave-system` reproduced the PR's own pasted output verbatim.

40. **A test can be named after a rule, assert something, and never touch the system that rule
    governs.** `SpawnSystemTest.movingAPlacementEarlierChangesNoOtherOffset` builds two
    `List<WavePlacement>` by hand, reusing the *same* `WavePlacement` object instance in both lists,
    and asserts `assertEquals(untouched, originalOrder.get(1))` — trivially true by object identity,
    regardless of anything `SpawnSystem` does. Confirmed vacuous by scaling `scheduleNext`'s offset
    arithmetic by 1000x in a scratch worktree: the test stayed green. The other three rule-asserting
    tests in the same PR (`fixedDurationEndsExactlyAtItsOwnDuration`, `clearedWaveWaitsForEvery
    EntityToBeGone`, `negativeOffsetOverlapsTwoWaves`) all genuinely exercise `SpawnSystem.update`
    and all went red under a matching one-line break (`>=`→`>` on the duration check, dropping the
    `noEntityCarries` guard, and replacing the do-while re-check loop with a single pass,
    respectively) — so this is not a blanket problem with the phase's tests, just this one. The
    "rule" it half-demonstrates (offset is relative-only, no absolute-position field) is actually a
    true structural property of `WavePlacement` being an immutable record with no such field, and
    needs no runtime test at all — the test should either construct genuinely distinct objects and
    assert on `SpawnSystem`'s emitted spawn order, or be deleted as redundant with the record's own
    javadoc guarantee.
41. **A `default`-with-throw contract method copies the justification of a sibling method
    word-for-word without checking it still applies.** `ContentSource.timeline(String)` was demoted
    from abstract to `default` in this PR, with javadoc citing the same reasoning as `wave(String)`
    ("kept only because `game`'s `JsonContentSource` still overrides it") — but `JsonContentSource`
    *does* override `timeline()` on this branch (confirmed by reading the file), so nothing forces
    the demotion; the module-boundary need that justifies `wave(String)` and the new
    `placements(String)` (grep `implements ContentSource`: `JsonContentSource` has no override of
    either, so an abstract method would break `game`'s compile, a module `core-domain` may not edit)
    genuinely does not apply to `timeline()`. Net effect: this single PR takes `ContentSource` from
    one defaulted method to three, not two as its own PR description counts ("the second defaulted
    contract method") — `placements(String)` is real and justified, `timeline(String)`'s demotion is
    an unforced, minor widening dressed in the justification of its neighbours. Worth flagging every
    time a `default`-throw method's javadoc cites "the same reason as X" — reread whether the actual
    production implementer(s) already provide an override; if they do, the default adds a silent-
    failure mode for a case that cannot currently occur.

Also confirmed correct, worth recording as the positive case: the claimed inherited bug (`update()`
scheduling the level's first placement *after* `levelTime += step`, so `scheduleNext`'s clamp-forward
logic delayed every one of the level's first-wave spawns by one tick) is real in the sense that the
described mechanism would produce exactly that symptom, and the shipped fix — scheduling the first
placement before the tick's own step is added — resolves it without touching the separate `Cleared`
clamp path (`scheduleNext(world, levelTime)` from `resolveEnded`, called only after detection, is
untouched code, confirmed by diff). Reconstructed by hand rather than trusting the commit body: with
the fix, `scheduleNext(world, 0f)` runs while `levelTime` is still its initial `0f`, giving
`start = max(0 + offset, 0)`; only then does `levelTime += step` run, so the first tick's `spawnDue`
computes `localTime = step - 0 = step`, matching the old flat-cursor system's own first-tick check
(`events.at() <= levelTime` after the same increment). Reversing the two statements (increment first,
schedule second) reproduces the claimed bug exactly: `start` would clamp to `step`, not `0`.

## For a second-round PR whose top-level GitHub description predates the fix commit

- **The PR body (`gh pr view --json body`) is not updated automatically when new commits land** —
  it is prose the author wrote once and can leave stale. PR #120 (task 7, phase 11b) round 2 deleted
  the load-time flattening and the `Cleared`-placement rejection its round-1 self had; the fix commit,
  a fresh PR *comment*, and `status.md` all say so correctly, but the PR's top **description**
  (`## What changed` / the JSON example / the verification log) still describes the deleted
  round-1 behaviour verbatim — it was never edited after the round-2 commits. Read `gh pr view --json
  body` *and* `gh pr view --json comments` separately and diff what each claims against the code;
  the top description is what a reader sees first and is not guaranteed to be the current claim.
  Not a code defect here (status.md and the latest comment are accurate, code matches them), but
  exactly the shape of "false statement in a document" the project's own precedent (phase 09's two
  rejections) warns about — flag it for correction even when a later comment already fixes the record,
  because the top description is the part most likely to be read alone. **Recurred in PR #168, phase
  11c** (see below): same shape, same verdict (note, not blocker), so it is a real recurring pattern
  in this project's workflow, not a one-off.
- **`./gradlew build` never runs the actual TeaVM JS/Wasm compile** on this repo — `web:build`
  finishes with `compileTeavmJava NO-SOURCE` and no `dist/js` output. The real check is a specific
  task, `./gradlew :web:gdx_teavm_web_js_build` (list them with `./gradlew :web:tasks --all | grep -i
  teavm`), which does the asset copy (confirms `startup-logo.png` ships) and the actual compile. A
  claim of "the web target still builds" backed only by `:web:build` or the top-level `build` is
  weaker than it sounds; run the JS build task directly when the PR touches anything under `web/` or
  makes a TeaVM-compatibility claim.

## Phase 11b closing group: PRs #124, #125, #127 — the migration's real math checked out, two claims did not

Merged all three into a scratch worktree (`git worktree add ../ls-review-final --detach origin/phase/11b-wave-system`, three plain `git merge --no-edit`s, no conflicts). `./gradlew build` green, 322 core tests / 0 failures, `./gradlew :web:gdx_teavm_web_js_build` green (`waves.json` and `startup-logo.png` both copied into `dist/js/webapp/assets`). Verdict: #124 accept (clean, matches #122 exactly, both implementers confirmed to override both methods, no third implementer). #125 accept on the migration itself, with one real false claim to correct. #127 accept, the falsification claims reproduced exactly.

42. **A "checked every pair, nothing else repeats" claim is disprovable by one `Counter` over the same
    92 events the author had in front of them.** #125/`status.md` claims `enemy-tank`/`single`/`atX
    0.5` (no drop) is "the *only* exact spawn-composition duplicate anywhere in the 92 events." It
    is not: `enemy-rush`/`column-3`/`atX 0.5` (no drop) repeats **six** times (118.5, 195.5, 215.0,
    224.0, 276.5, 293.0), `enemy-basic`/`line-5`/`atX 0.5` five times, plus four more pairs/triples.
    None of this touches the acceptance criterion (still genuinely reused 3x, still an honest,
    correct reuse) or the reconstructed timing (my own independent Python re-simulation, using only
    the placement list's offsets and the waves' durations — no access to the author's script —
    reproduced all 92 original absolute times exactly, `diff` clean). The lesson: "checked every
    block pairwise" is a claim about a search that was run, not about the result being correct;
    counting duplicates by `(spawn, formation, atX, drop, dropSlot)` tuple across the whole file is
    three lines of Python and should be run every time a content migration claims uniqueness, even
    when the *consequence* of the false claim is zero (a stronger reuse example existed and was not
    used).
43. **The acceptance criterion "the determinism replay of level 1 still passes" has no committed
    test that loads real content.** `LevelScoreReplayTest` and `LevelContentIntegrationTest` both
    build content through `TestContent` (grepped, confirmed); `game/src/test` does not exist at all
    (`find game -path "*/test/*"` empty). What actually verified the migration was the author's own
    uncommitted scratch program (`FileHandle` over real `assets/data`, ticking a real `Simulation`
    for 310s) and my own independent reconstruction — neither is a regression net that runs again on
    the next content edit. Worth naming every time a phase's central acceptance criterion is a
    behavioural claim about real JSON content: ask what test the CI actually runs that would fail if
    a future edit to that JSON broke it, separately from asking whether the migration was correct
    *this time*.
44. **A predictive-scheduling rewrite can make an existing boundary check untestable through the
    path that used to expose it.** #127 rewrote `FixedDuration`→`FixedDuration` follower scheduling
    from reactive (`hasEnded` must return true before the next wave is scheduled) to predictive
    (`start + duration.seconds()` computed once, at chain-build time). Mutating `hasEnded`'s
    `FixedDuration` boundary (`>=` → `>`) leaves **all 24** `SpawnSystemTest` cases green —
    `--rerun-tasks` confirmed, not a stale-cache false negative. The reason: once a `FixedDuration`
    chain is scheduled predictively, `hasEnded` for that condition only gates removal from
    `activeWaves` (harmless — the wave's own spawn cursor is already exhausted) and the exact tick
    `world.markWaveTimelineExhausted()` fires; nothing in the suite pins that exact tick for a
    `FixedDuration`-only chain (the one exact-boundary completion test, `completesOnceThe
    TimelineIsExhaustedAndNothingIsAlive`, gives the boundary 0.5s of slack, not zero). Meanwhile the
    two DisplayNames that read as if they test that boundary
    (`fixedDurationEndsExactlyAtItsOwnDuration`, `movingAPlacementEarlierChangesNoOtherOffset`) *do*
    genuinely fail under a **different** mutation — breaking the chain arithmetic itself
    (`start + duration.seconds()` → `start + duration.seconds() - 1f`) fails both. So the tests are
    not vacuous, they just protect a different thing than their exact-boundary framing suggests.
    Whenever a system moves from reactive to predictive scheduling, mutate the *old* boundary check
    on its own, separately from the arithmetic that replaced its job — they can diverge.
45. **A phase's own unmet acceptance-criterion bullet, honestly flagged inside the very PR that
    doesn't close it, still has to be caught at phase-boundary time.** `.claude/agents/
    level-designer.md`'s "a level is a timeline of timestamped spawn events" paragraph is still
    "Not built yet" as of all three PRs (`git diff ... --stat -- .claude/agents/level-designer.md`
    empty on all three) — `status.md`'s own #114 entry says so ("Not this task's to fix, flagged for
    whoever owns it"), correctly. Not a false claim anywhere, but it is a real, plan-listed
    acceptance-criterion bullet with no owning PR in the closing group. When a coordinator says "I
    close the phase after these," re-check the full acceptance list against the merge, not just
    against each PR's own stated scope — an honestly-deferred item from three PRs ago is still open.
- **`status.md` on the phase branch does not gain an entry for #124 or #127.** Neither branch
  touches `docs/plan/11b-wave-system/status.md` (confirmed by `git diff <phase>...<branch> --stat`);
  the only trace of the negative-offset bug and its fix on the phase branch itself is two agent-memory
  commit *messages* ("record the negative-offset overlap fix" / "note wave lookup defaults retired"),
  not a status.md line. Since `status.md` is supposed to be "the only place phase progress is
  recorded" and the plan's own decision text already asserts negative offsets work ("A negative
  offset overlaps them"), a reader of `status.md` alone would not learn that this was broken until
  28/08/2026 and had to be fixed by #126/#127. Not a false statement (status.md says nothing wrong,
  it says nothing at all), but the closing PR set should add the entry rather than leave it to two
  memory-commit subject lines to carry the fact.

## Phase 10d — auditing rules written from inside one lived case (workflow-enforcement phase)

46. **Two sibling scripts that enforce "the same rule" almost never enforce the identical set of
    exceptions, and only running both against the same commit proves it.** `tools/hooks/commit-msg`
    exempts `Merge `, `Revert "`, `fixup!`, `squash!` and an empty/comment-only subject (case
    statement, `tools/hooks/commit-msg:32-34`). `tools/pre-pr-check`'s own commit-hygiene loop
    (step 2, around line 80) only skips `"Merge "*`. A plain `git revert --no-edit` — which the hook
    explicitly documents as legitimate — produces a subject the hook accepts at commit time and
    `pre-pr-check` then rejects before the pull request, with a generic "not a conventional subject"
    error that gives no hint the two checks disagree. Confirmed by actually running
    `git revert --no-edit <sha>` on a scratch branch and then `tools/pre-pr-check`: `FAIL 1 commit
    subject(s) break the convention`. Worse: `docs/plan/10d-enforced-workflow/status/
    137-issue-contract.md:13` states outright that `commit-msg` checks "the same rule
    `tools/pre-pr-check` applies… Merges, reverts, `fixup!`, `squash!` and an empty or comment-only
    message are skipped" — a claim about parity between the two scripts that is false for four of
    its five listed exemptions, written the same way phase 09's "never run on a runner" claim was:
    plausible, unverified, and contradicted by one command. This is the shape to check first
    whenever two enforcement scripts are said to share a rule: read each one's actual exemption list
    side by side, don't trust the sentence that says they agree.
47. **A status-fragment naming check that verifies "the basename matches the issue number" is not
    the same as verifying "the fragment lives under the phase actually being worked."** Neither
    `tools/pre-pr-check` (which only checks presence — by its own comment, deliberately) nor
    `.github/workflows/pr-check.yml` (which matches `docs/plan/[^/]+/status/[^/]+\.md` against any
    phase directory and only checks the basename against the cited issue number) confirms that the
    `[^/]+` phase segment matches the phase branch the pull request targets. Confirmed by
    constructing a branch against `phase/10d-enforced-workflow` that adds
    `docs/plan/11c-movement-shapes/status/999-misplaced.md` and citing "Closes #999" in the body: both
    the real `tools/pre-pr-check` and a line-for-line extraction of `pr-check.yml`'s logic pass it.
    Weaker than #46 (the gap is explicitly narrowed-by-comment in `pre-pr-check`, "checking the name
    against the issue… is pr-check's job" — but `pr-check` doesn't close that gap either), still
    worth naming as a second instance of the same phase's blind spot: a check specified from the one
    case its author tested (issue number matches fragment number) rather than the full shape of
    "illegitimate" (issue number matches, but wrong phase directory).

## Phase 11c round 1 (PRs #168 `feat/movement-state`, #169 `content/movement-shapes`) — two agents in parallel over disjoint files, and a clean pair

The first phase to run `core-domain` and `level-designer` in parallel over `core/` and
`docs/`+`assets/data/` at once, with a real mid-round correction crossing between them (#169's
catalogue landed while #168 was open; #168's author had already added `Trajectory.originX/originY`
on a defensible guess, the coordinator asked for them to come out once the catalogue settled the
question the other way, and they did, same branch, same PR — confirmed via `git log` on the branch
showing the follow-up commits `fix(core): drop Trajectory origin now the shape catalogue refuses
it` immediately after the design landed). Both branches touched only their own module (`git diff
<phase>...<branch> --stat` for #168: `core/` + its own status fragment only; for #169: `docs/`
only, no `assets/data/` written — deliberately, since #163 owns the parser). Both green on real
CI runs (`gh run view <id> --log`, `BUILD SUCCESSFUL` on both `build` jobs). Verdict: accept both,
nothing blocking on either.

48. **A PR's top-level description can describe a design the branch's own later commits reversed,
    while every other record (PR comment, status fragment, code) agrees on the current state.**
    #168's `gh pr view --json body` still says `Trajectory` "carries origin (`originX`/`originY`)
    alongside elapsed time" under a "Decision made where the plan was silent" heading — that was
    true of the branch's first 5 commits, false after the next 3 (`fix(core): drop Trajectory
    origin now the shape catalogue refuses it` and its sibling test/doc commits). The correction is
    recorded faithfully in a PR *comment* ("Update: per the coordinator's instruction, dropped
    `Trajectory.originX`/`originY`...") and in the status fragment, which additionally narrates
    *why* the guess was made and *why* it was reversed rather than hiding the churn — the actual
    `Trajectory.java` on the branch has one field, `elapsed`. This is exactly the shape named as a
    recurring pattern by PR #120's round 2 (see the note above), now confirmed to recur a second
    time in a different phase: the top description is written once and nobody is in the habit of
    revisiting it after a follow-up commit, even when a comment two clicks below it does. Calibrated
    as a note, not a blocker, both times — the description is stale, nothing downstream (code,
    status.md, the latest comment) is.
49. **A status fragment's component-store ordinal claim can be off by a small, harmless amount and
    still be a checkable numeric error worth naming.** #168's `status/161-...md` calls `Trajectory`
    "a fifteenth `ComponentStore<Trajectory>` field" — `grep -c "private final ComponentStore<"
    World.java` on the branch returns 19 (18 pre-existing + this PR's one). Costs nothing
    functionally (the test that actually guards store count, `WorldTest`'s `stores.size() >= 15`
    floor, does not depend on the ordinal claimed in prose), but it is exactly the kind of
    quantitative claim this project's own citation-checking habit exists to catch — count the
    `private final ComponentStore<` lines whenever a status fragment numbers a store by ordinal, it
    is one grep.
50. **A design-fidelity document's derived-quantity arithmetic (turn time, apex depth, screen-exit
    time) is worth reconstructing by hand even when it spans several entries, because the discipline
    generalises and the author's habit of citing exact source lines (radius from `enemies.json`,
    `SAFETY_MARGIN` from `LifetimeSystem.java`) makes it cheap.** Recomputed all of #169's
    `shape-catalogue.md` claims independently: `strike-run`'s turn time (`110/27 = 4.074s`, matches
    "4.07 s") and apex depth (`110²/(2·27) = 224.07`, matches "224 below spawn"); `veer-left`'s
    (`95/20 = 4.75s`, `95²/40 = 225.6 ≈ 226`, both match) and its crossing-x arithmetic at `atX 0.9`
    (`187 - 32·4.75 = 35`, matches "apex x ≈ 35" exactly); the safety-box bounds cited (`x ∈
    [-128, 336]`, `y ∈ [-128, 398]`) against `LifetimeSystem.SAFETY_MARGIN = 128f` and
    `PLAYFIELD_WIDTH`/`PLAYFIELD_HEIGHT` (208/270) — exact match. One inexactness found and judged
    not worth blocking: the stated screen-exit times for `strike-run`/`veer-left` (9.15s/9.85s)
    solve `y = 398`/`x = -128` rather than `y - radius = 398`/`x - radius = -128`, which is what
    `LifetimeSystem.isPastSafetyBox` actually checks — the true exit is a few hundredths of a second
    later (recomputed: `y=402` gives `t≈9.18s`, not `9.15s`). Immaterial to the rule the document is
    proving ("every shape leaves in finite time"), and this project's own calibration (pattern 31,
    the phase 03 sprite-production branch) already established that a design document can check out
    in full — do not manufacture the rounding gap into a defect it doesn't support.
51. **A "phase 12's levels give us no beat list to point a shape at" finding can be reported by both
    halves of a parallel round without either one copying the other, and both halves agreeing is
    itself evidence, not just a coincidence to note.** The coordinator's brief for this round flagged
    this exact gap as "already known, don't spend the audit rediscovering it" — and #169's own
    `shape-catalogue.md` and its status fragment both state it independently and identically ("Phase
    12's levels 2 and 3 justify nothing here, and could not... only half of the issue's... could be
    answered honestly, so all seven entries rest on level 1"), which is the correct, honest response
    to an unanswerable half of an issue's acceptance criterion — the alternative (silently building a
    shape "for phase 12" anyway) is exactly what invariant 6 exists to refuse, and this branch didn't
    take it.

## PR #170 (`feat/movement-shape-content`, phase 11c round 2, issue #163) — a sealed interface actually proven safe under TeaVM, and a clean three-agent branch

The round the parent most wanted a second opinion on: `TrajectoryDefinition` became a `sealed
interface` with a `permits` clause, `core` is what TeaVM compiles, and CI's `build` job runs
`compileTeavmJava` as `NO-SOURCE` (see the closing-group entry above and [[audit-techniques]]'s
"For auditing a TeaVM web dist directory") — so nothing in the PR's own green checks proves the web
target still builds. Settled by actually running the real compile, not by reasoning about the
language feature: `git worktree add` off `origin/feat/movement-shape-content`, then `./gradlew.bat
:web:gdx_teavm_web_js_build` (the task name from the earlier note above), `BUILD SUCCESSFUL`, and
`grep -c ArcTrajectoryDefinition web/build/dist/js/webapp/app.js` returned 20 — the sealed type and
its new permitted record are both really in the compiled JS, not just theoretically compatible.
`WaveEndCondition` (`core/src/main/java/.../core/port/WaveEndCondition.java:17`) really is already
`sealed`, confirming the PR's "mirrors an existing pattern" claim, and this PR is the first time
anyone has actually proven a sealed `core.port` type survives the TeaVM compile rather than assuming
it from `WaveEndCondition` shipping unexamined. **Worth remembering directly: sealed interfaces with
`permits` compile through this project's TeaVM plugin (`com.github.xpenatan.gdx-teavm:1.6.1`) — this
no longer needs re-litigating on a future PR, only re-confirming if the plugin version changes.**

52. **Nothing wrong found, and every checkable claim reproduced.** The eight refused shapes from
    round 1's catalogue (`diagonal`, `logarithmic`, `sine`, `enterAndHold`, `ax`, waypoints,
    formation-relative, player-reading) shipped nothing — no field, no parser branch, no
    `horizontalVelocityAt` (grepped for it directly, zero hits) — and the "nothing points at the new
    entries" claim held (`grep -rln "strike-run\|veer-left\|veer-right" assets/data/*.json` returns
    only `trajectories.json`). `requireOnlyKeys` strictness is pre-existing (already used for waves'
    end conditions), not new machinery invented for this PR, and the four pre-existing trajectory
    entries parse unchanged through it. Full clean `./gradlew build`: 328 core tests, 0
    failures/skipped/errors. `pre-pr-check --base phase/11c-movement-shapes` reproduced the PR body's
    pasted "PASS — 5 commit(s), 8 file(s) changed" exactly (had to `git checkout -b` inside the
    detached worktree first — the branch-name check fails on a bare detached HEAD, a tooling quirk
    worth remembering, not a defect). The `-110 → -56 → -0.002` sequence in both the PR body and the
    status fragment reproduces by hand (`-110+27·2=-56`, `-110+27·4.074≈-0.002`). Recorded as
    calibration alongside PR #22/#26/#31/#08's clean verdicts: an "accept, nothing new" report is
    only worth as much as the TeaVM compile actually run to support it.

## PR #171 (`feat/spawn-shape-id`, phase 11c task 4/issue #164) — the phase's own task, clean

Two agents on one branch, `core-domain` for the binding and evaluation, `game-presentation` for the
loader key, same split as #163. Verdict: accept, nothing found. Recorded as the calibration case for
"velocity becomes a function of elapsed time for the first time" not actually breaking determinism.

53. **A uniform-attach claim ("every entity that gets a Motion now also gets a Trajectory") is
    verified by grepping the one call site of the shared factory method, not by reading its own
    javadoc.** `ComponentFactoryRegistry.attachMotion`/`attachTrajectory` is registered exactly once,
    under `"motion"` in `ComponentFactoryRegistry.withDefaults()`, and only `SpawnSystem` and
    `SpawnerSystem` ever call `attachComponents` at all — the player (`Simulation`), the boss
    (`BossSystem`) and both weapon systems all call `world.motions().set(...)` directly, bypassing the
    registry entirely, so none of them ever gains a `Trajectory` and MotionSystem's per-tick
    re-evaluation loop (which walks `world.trajectories()`, not `world.motions()`) never touches their
    hand-set `Motion`. Confirmed by grepping `attachMotion|attachTrajectory` and `new Motion(` across
    `core/src/main` separately. The "is it really a no-op for constants" half of the same claim is
    provable by mutation-free reasoning once `TrajectoryDefinition`'s two implementations are read: a
    `constant` shape's `verticalVelocityAt` ignores its argument by construction, so re-evaluating it
    every tick is definitionally the same write every time — no probe needed, unlike the boundary
    mutations pattern 44 required.
54. **An "unknown id fails loudly, one level later, by design" claim for a *new* content field is
    fully checkable end to end with two greps, no probe.** `SpawnEvent.trajectoryId` skips validation
    in its own compact constructor (confirmed by reading it — same four checks as before this PR,
    nothing added for the new field) and `JsonContentSource.parseSpawnEvent` never resolves it either
    — the actual throw is `JsonContentSource.require`'s `IllegalArgumentException("unknown " + kind +
    " id '" + id + "'")`, reached through `world.content().trajectory(id)` inside
    `MotionSystem.advanceTrajectories`/`ComponentFactoryRegistry.attachTrajectory`, and
    `Simulation.tick` has no try/catch anywhere in the file — so the exception is genuinely uncaught,
    not merely "loud" in the sense of a logged line. This is the same treatment `enemyId`/`formationId`
    already get (grepped `require(` calls in `JsonContentSource` to confirm the pattern is pre-existing,
    not invented for this field), so the precedent claim holds too.
55. **A phase's own worked numbers (turn time, exact velocity at a stated tick) are the strongest test
    oracle available, and a test that asserts against them is proof against silent accumulation
    drift.** `MotionSystemTest.arcShapeIsFollowedAndCurves` asserts `Motion.vy` at t=5s equals
    `-110 + 27*5 = 25` exactly (0.01f tolerance) — this is `TrajectoryDefinition#verticalVelocityAt`'s
    closed form, and it would NOT match if the implementation instead accumulated `ay * step` every
    tick with float error, or evaluated against a stale `elapsed` (before vs. after the tick's own
    increment). Whenever a "closed form, not accumulation" claim appears, check that the test's
    asserted value is the closed-form result and not just "some value the code currently produces."

Full clean-branch confirmation: `./gradlew :core:test --rerun-tasks` from a fresh worktree, 331 tests
0 failures/skipped/errors (aggregated from `core/build/test-results/test/*.xml`); `DeterminismRulesTest`
and every `*ReplayTest` present and green; `SystemOrder.java` untouched (`git diff` empty for that
file); `./gradlew :web:gdx_teavm_web_js_build` green from the same worktree (this PR touches `game/`,
so worth re-running even though the PR itself only claims "not checked" for the web target — the
claim was appropriately conservative, not wrong); `tools/pre-pr-check --base phase/11c-movement-shapes`
reproduced the PR's pasted "PASS — 4 commit(s), 11 file(s) changed" exactly, after `git checkout -b`
inside the detached worktree (pattern from PR #170's memory entry, still needed). No wave/level/enemy
content references any new shape id (`grep -rln "strike-run\|veer-left\|veer-right" assets/data/*.json`
returns only `trajectories.json`), confirming the "no wave points at a shape yet" claim.

Related: [[audit-techniques]].

56. **Phase 11e's two branches (#203 boss-aimed-attack, #204 enemy-health-numbers) are a second
    clean-branch calibration point, and both status fragments self-flagged their own biggest risk
    instead of waiting for review to find it.** #203's fragment names, unprompted, that collapsing
    spread/sweep into one `fireAimedFan` method "narrows what makes them feel like two" and routes it
    back to task 5's play session rather than asserting the decided "two alternating patterns" rule
    is still intact — a claim I could not fully settle either (it is a rules judgement, not a fact),
    so the honest move was to relay the same open question rather than resolve it either way. #204's
    fragment flags `LevelScoreReplayTest.java:32`'s javadoc as now false without touching the file
    (correctly, since it's `core-domain`'s), and separately flags `bombDamage 50` against the new
    carrier `Health 1000` as dropping the bomb from removing 62% to 5% of a carrier's health — a real
    numeric consequence of the change that the branch's own scope didn't ask it to fix. Both claims
    checked out exactly as stated: `DamageSystem.java:93` genuinely never reads `Collider#fragile` on
    the player-projectile branch (only `:149` ramming and `BombSystem.java:115` detonation do), and
    regenerating `docs/levels/level-01.md` via `node tools/build-level-docs.js` in the branch's own
    worktree produced zero diff. Pattern to reuse: when a fragment volunteers a limitation or a
    downstream consequence unprompted, that is a strong signal of genuine care — verify it like any
    other claim, but it more often survives verification than an unprompted claim of *correctness*
    does.
57. **`Math.sqrt` for vector renormalisation in `core` has a real precedent worth checking rather than
    trusting.** `MotionSystem.java:116` (`scale = cap / Math.sqrt(lengthSquared)`) already does exactly
    this for the velocity cap, so a new use for aim-direction renormalisation in `BossSystem` citing it
    as precedent is checkable with one grep rather than a determinism argument from first principles.
    `Math.sin`/`cos` remain the thing to look for instead — still absent, still the actual TeaVM/JVM
    float-parity risk this project treats as real.

## PR #207 (`feat/fourteen-beat-level-one`, phase 11e task 1) — a content-only branch, clean, and the calibration case for "candidate not verdict"

`assets/data/waves.json` + `level-01.json` + two generated docs + status fragment only (confirmed by
`git diff --stat`), so invariants 1-6 are structurally out of reach. Verdict: accept. Worth recording
because this is a strong example of the honest-partial-completion shape (patterns 21/22/36's positive
case) and because it sharpens when a stated out-of-scope item is a real overstep versus a labelled,
disclosed judgement call.

46. **A per-wave "adapted" claim is checkable by diffing the spawn-tuple list, not by trusting the
    table's prose.** Extracted `(spawn, formation, atX, trajectory)` per wave from both sides of the
    diff with a five-line Python script (`json.load` on `git show <rev>:assets/data/waves.json`,
    compare by wave id). Of nine "adapted" waves, seven were genuine trims (formations and order kept,
    duplicate entries dropped, `atX` raised where the fragment says so). Two went further than a trim
    without the fragment flagging it specifically: `l1-tanks-and-priority` reordered its spawns and
    swapped `vee-5`→`diagonal` for its light entry, and `l1-evolved-shooters` dropped `enemy-light`
    entirely and added an `enemy-basic line-5` in its place. Neither is a violation — the fragment
    never claims "shape kept intact" for either of them the way it does for beat 3, and the beat's
    thematic content survives — but it is the check to run every time a status fragment tables
    kept/adapted/new: extract the tuples, diff them, and see whether the *specific* wave that claims
    a bare "adapted" (no shape-preservation sentence attached) is doing more than trimming.
47. **A candidate branch changing a number an issue's own "out of scope" section assigns to a later
    task is not automatically an overstep — check whether the later task can even be evaluated without
    it.** #198 says "the length... is task 2's and fixed by playing, not here," and the branch moved
    `level-01.json`'s `boss.entersAt` from 302 to 139.5. `boss.entersAt` is independent of the wave
    chain (confirmed by reading the generated doc's own note and `BossSystem`), so leaving it at 302
    was a real option — the branch chose not to. What makes this a defensible judgement call rather
    than a violation: the status fragment states the new number as a proposal with its derivation
    (budget backward from "~3 min, boss included" against the fourteen beats' target durations),
    labels it explicitly "not a verdict: task 2 owns the length," and the plan's own workflow frames
    tasks 1-4 as landing together into one playable candidate for a single play session (#201) — a
    13-wave-then-155-seconds-of-nothing level would not let that session answer the length question at
    all. Recorded as the case to reuse: when a branch touches a value an issue nominally reserves for
    a sibling task, check (a) whether the value is structurally independent of what this issue actually
    builds, (b) whether the branch's own record calls it a proposal or a decision, and (c) whether the
    sibling task could function without this branch having picked *some* value. All three favour
    "accept, note for the coordinator" over "revert before merge" here.
- Also confirmed clean by direct reproduction, not by trusting the write-up: `node
  tools/build-level-docs.js` in the branch's own worktree produced zero diff against the committed
  `docs/levels/{level-01,waves}.md`; every veer placement (`0.88`/`0.12`) satisfies the 11c
  `atX >= 0.75` / `<= 0.25` rule; the swoop-drift arithmetic for the two previously-open Checks
  findings (`l1-carrier-pair`, `l1-finale-a`) recomputed clean inside `0..208` for every remaining
  `enemy-light`/`swoop` spawn in the new content; the per-beat start/end times in the fragment's own
  table match the generated doc to the tenth of a second; `enemies.json` genuinely untouched
  (`git diff --stat`); tank 300 / carrier 1000 / `weaponProjectileDamage 10` confirmed in
  `assets/data/{enemies,balance}.json`, and zero `"cleared"`-type waves confirmed by grep, backing the
  fragment's "every wave is `fixedDuration` on purpose" reasoning. `tools/pre-pr-check --base
  phase/11e-level-one-redesigned` reproduced the PR body's pasted output verbatim, including the real
  `./gradlew build` pass.

## PRs #221 (`fix/pointer-lock-recovery`, #41) and #224 (`feat/shield-attachment-visible`, #43), phase 11f — both accept, one real second-guess finding

Both branches touch `PlayScreen.java` in disjoint regions (#221 the `render()` body, #224 one line in
`show()`); merged both into a scratch worktree (`git worktree add ... --detach phase/11f-web-defects`,
two plain `git merge --no-edit`s) with zero conflicts, and `./gradlew clean build -q` on the merge
result was green across all five modules. Worth recording as the technique: don't reason about whether
two diffs "should" combine, actually merge them.

46. **A same-call read-after-write of a platform-reported flag, right after requesting the change that
    flag reports.** `InputAdapter.managePointerCapture` requests pointer capture
    (`Gdx.input.setCursorCatched(true)`) and, in the same method invocation, falls through to `else if
    (pointerCaptureRequested && !Gdx.input.isCursorCatched())` — which, if the platform's capture grant
    is not synchronous (Pointer Lock in a real browser is asynchronous; a JS `requestPointerLock()`
    call resolves via a later `pointerlockchange` event, not before the calling frame returns), would
    read the not-yet-confirmed state on the very same frame and immediately fire "unexpectedly lost",
    pausing the game the instant the player clicks to engage the mouse. Confirmed the code shape by
    reading the method top to bottom (`if (mouseEnabled && !pointerCaptureRequested && click) { ... }`
    falls through with no `return`/`else`, straight into the `if (escapeJustPressed...) else if
    (pointerCaptureRequested && !isCursorCatched())` pair). Could not confirm or refute the TeaVM/GWT
    backend's actual synchrony for `setCursorCatched`/`isCursorCatched` from this environment (would
    need the gdx-teavm backend source, not present in this repo; searching the Gradle cache for the jar
    timed out) — this is the "unverifiable is not the same as wrong" shape from
    [[audit-techniques]], reported as a suspicion worth a one-line guard (skip the unexpected-loss
    check on the same call that just requested capture) rather than a confirmed defect.
47. **A design document read narrowly by a PR turned out to be read correctly, confirmed by checking
    both the doc and the atlas.** #224 argues `04-hud-layout.md`'s "Invulnerability is shown on the
    ship, not in the plate" is scoped to the three `InvulnerabilitySource` grace periods (respawn,
    damage-absorbed, power-up) and not to `shieldActive`'s own persistent HUD icon, and that no
    shield-ring sprite exists to draw on the ship instead. Both checked out: the document's own "on the
    ship" table lists exactly those three named sources and nothing else, and `assets/atlas/
    sprites.atlas` has `pickup-shield` (the drop capsule) and `icon-shield` (the HUD glyph, now wired)
    but no third, on-ship shield-ring id. A deliberate omission argued from a document is worth
    re-reading against the document before accepting *or* rejecting it — this one held.

Calibration in both directions: keyboard-only play cannot trigger the pointer-loss pause at all
(`pointerCaptureRequested` only ever becomes `true` inside the `mouseEnabled` branch), Escape's
deliberate release and the unexpected-loss branch are mutually exclusive on the same call (`if`/`else
if`, no case where both fire), and skipping `loop.advance` for the lost-lock frame is exactly the
existing pause semantics (`audioDirector.update`/outcome-check already sit inside the same `if
(!paused)` block) — not a new hole in accumulated fixed-step time or the outcome check. Also confirmed:
all six atlas ids the two PRs newly reference exist in `assets/atlas/sprites.atlas` at the lines
`module-satellite:153`, `icon-life:209`, `icon-bomb:216`, `icon-shield:223`, `icon-invuln:230`,
`icon-module:237`; the null-region HUD fallback is whole-widget (icon or full old rect+outline, never
a mix); `WorldRenderer.drawAttachment` adds no new mutable field, reusing the same call's `x`/`y`.

48. **A `pauseGameplay()` guarded by `if (!paused)` makes a second entry point (browser pointer-lock
    loss) safe to call repeatedly without extra guards.** #227 (phase 11f, in-game options) added a
    second panel state (`buildPauseOptionsPanel()`) swapped in place on the same pause `Stage`, and its
    own fragment flagged "does the pointer-lock-loss path re-entering pause while options is open
    double-attach listeners or strand the panel" as unchecked. Traced it: `PlayScreen.render()` only
    calls `input.sample()`/checks `pointerCaptureLostUnexpectedly()` inside `if (!paused)`, and
    `pauseGameplay()` itself no-ops when `paused` is already `true` — so once paused (menu or options
    state), the unexpected-loss branch is never even evaluated again. No double-build, no doubled
    `MenuNavigator`, no dead end. Worth checking this shape on any future PR that adds a second trigger
    for an existing state-guarded method: read the guard first, then trace whether the second trigger's
    call site is itself gated on the same flag.
49. **An excluded feature's justification checked out because of a *pre-existing* gap the author didn't
    even cite.** #227 excluded a live mouse-control toggle from the in-game options panel, arguing it
    "interacts with live pointer-lock state" without pointing at code. Reading `InputAdapter
    .managePointerCapture` found the actual mechanism: pointer-capture release is gated solely on
    Escape (`escapeJustPressed && pointerCaptureRequested`), never on `mouseEnabled` going false — so a
    live toggle-off mid-run would leave the cursor captured/hidden with no release path but pause. The
    exclusion was sound, but the fragment's own reasoning was vaguer than the code justifies; citing the
    actual gate would have made "not decided lightly" into "here is the line that would break."
50. **Octopus-merging two same-phase sibling branches with disjoint file sets in a throwaway detached
    worktree is a fast, real conflict/build check** — `git worktree add --detach <tmp> <phase-branch>`,
    then `git merge --no-edit <branchA> <branchB>`, then `./gradlew build -q`, then
    `git worktree remove --force <tmp>`. Confirms both "do these PRs conflict" and "does the combination
    still build" in one pass without touching either sub-branch's own worktree. `git worktree remove`
    can transiently fail with a Windows file-lock ("Permission denied") right after Gradle touched the
    tree; retrying (or just re-running `git worktree list`) after a couple seconds resolves it — it is
    not a sign the worktree needs manual cleanup.

## PRs #234/#235, phase 11g — a clean pair, and the calibration case for a fully-argued content placement

Merged both into a scratch worktree (`git worktree add ../ls-review-11g --detach phase/11g-shield-and-test-harness`, two plain `git merge --no-edit`s, zero conflicts even though both touch `docs/plan/11g-shield-and-test-harness/status/`, because each writes its own filename). `./gradlew build` green across all modules. Verdict: accept both.

46. **A design-placement argument that cites a pacing table can be checked to the decimal, and here every number was right.** #234's reasoning (drought length, which placement is the first density spike, which slot is the formation's centre, which x that resolves to relative to the player's start x) all reproduced exactly from `docs/levels/level-01.md`'s own generated tables — density 1.77/s at placement #4 genuinely is the highest of the level up to that point and genuinely isn't exceeded again until 88.0s (1.91/s); `dropSlot 1` on a `line-3` genuinely is the middle slot (`(-20,0)(0,0)(20,0)`); atX 0.30 genuinely resolves left of the player's x=104 start. Worth naming as the counter-example to keep pattern 31's calibration point alive in the content-authoring family too, not just the art-only branch it was first observed on.
47. **The two mechanical claims behind a design rejection (`Shield` has no durability; `LifetimeSystem` strips `Drop` from an escaping enemy) are one grep and one class-read each, and are worth doing even when the prose reads as obviously true** — both held exactly as stated (`Shield` is a bare marker class; `LifetimeSystem.strip` removes `ScoreValue`/`Drop`/`Collider` before `markForDestruction`). A rejection argument stands or falls on claims like these, not on the placement chosen.
48. **A harness's "no dependency added, single-threaded, no clock" claim and its "the test can actually fail" claim are independently and cheaply checkable without rebuilding the author's steps.** Reading `FakeInput`'s `invoke()` confirmed the proxy answers only named methods and returns the type's JDK default (false/0/null) for everything else — the exact shape the project's own memory warns can make a test pass for the wrong reason, but here the two real assertions (`keyboardAloneReachesTopSpeed`, `keyboardAndMouseCancelExactly`) both route through methods the proxy actually implements, and the arithmetic behind "cancel exactly" (`mouseX = -140*(208/208)/1 = -140`, `keyboardX(140) = +140`) reproduces on paper from `InputAdapter.sample`'s real formula, not from the test's own comment. The 140f→999f falsification claim is plausible on inspection (the assertion is a direct `assertEquals`, no rounding or pooling in the way) — not independently rerun this session, so that half stays "plausible, not independently reproduced" rather than "confirmed."

Calibration in the other direction, worth keeping: no invariant-1 hit (`grep -rn "com.badlogic.gdx" core/src/main` first returned a spurious hit against `Rng.java` from a truncated `head` pipe; a clean, untruncated regrep of that exact file found nothing — when a grep result looks surprising, rerun it without piping through `head` before trusting it as a finding).

## PR #247 (`feat/test-build-flavour`, phase 11h task 1, issue #244) — a build-flavour absence claim that reproduced exactly, and the calibration case for a public seam judged inert rather than dangerous

Verdict: accept. The whole task turned on one criterion — "absence, not concealment" — and it was
checkable by rebuilding twice, not by reading the Gradle DSL and trusting it.

58. **A "the ordinary build's compiled output contains no trace" claim for a mutually-exclusive-
    source-directory flavour is fully reproducible in under a minute and is worth reproducing every
    time, not just reading the `sourceSets` block.** `game/build.gradle.kts` adds
    `src/tests/java` (real `TestMode`/`TestMenuScreen`/`TestScenarios`) to the `main` source set
    only when `providers.gradleProperty("tests").isPresent`, else `src/teststub/java` (a no-op
    `TestMode`). Reproduced independently: `./gradlew clean :game:compileJava` (no property) then
    `find game/build/classes/java/main -iname "TestMenu*" -o -iname "TestScenarios*"` — empty; same
    command with `-Ptests` — three `.class` files appear; `./gradlew clean build` (no property) then
    `unzip -l game/build/libs/game.jar | grep -i test` — exactly one line, the stub `TestMode.class`.
    Went one step further than the author's own verification (which stopped at the jar): ran the
    *actual* TeaVM compile, `./gradlew :web:gdx_teavm_web_js_build` (not the misleading `:web:build`,
    which shows `compileTeavmJava NO-SOURCE` — see the existing TeaVM-dist entry in
    [[audit-techniques]]), and grepped the emitted `app.js`: `TestMenuScreen`/`TestScenarios` — zero
    hits; `TestMode` — 4 hits (the harmless stub, expected). This is the strongest form of the
    absence claim this project asks for, and it held at every layer checked (compiled classes, jar,
    TeaVM-compiled JS).
59. **A public seam added to satisfy a documented precedent (`LEVEL_ID`'s own javadoc predicting
    "the day a level-select flow exists, this field is the one place that changes") is judged inert
    by grepping its call sites in the shipped source, separately from the flavour's own source-set
    split.** `LittleSpaceshipGame.overrideLevelId(String)` is public, present in every build
    (`main`, not `src/tests`), and has exactly one caller anywhere in the tree —
    `TestMenuScreen.java`, which only compiles under `-Ptests`. `grep -rn overrideLevelId` across
    `core`/`game`/`desktop`/`web` confirms it. A real, small surface (a public setter for which
    level a run plays) but genuinely dead code in the shipped build, not merely hidden — worth
    distinguishing from a runtime-hidden test hook, which this project's own architecture-test
    family (pattern 2, "accessor with no call site") would otherwise treat as suspicious by default.
    Here the absent caller is the point, not an oversight.
60. **A naming assumption stated as "if `level-designer`'s ids differ, only this list changes"
    reproduced exactly against the sibling branch that actually shipped, without coordination.**
    `TestScenarios.ALL` hardcodes `test-wave-04`/`test-wave-09`/`test-wave-12`/`test-boss`; the
    parallel `feat/scenario-levels`-shaped commit (`f19c3e8`, issue #245) added
    `assets/data/{test-boss,test-wave-04,test-wave-09,test-wave-12}.json` — identical ids, confirmed
    by `find assets/data -iname "test-*"` after the fact. Not something this task could have known in
    advance; worth recording as a positive cross-check rather than crediting the branch with
    foresight it couldn't have had.

Also confirmed clean: `core/` and `assets/data/` both empty in `git diff origin/phase/11h-test-mode
...origin/feat/test-build-flavour --stat`; no `Thread`/`ExecutorService`/`CompletableFuture`/
`ReentrantLock`/`Math.random`/clock read introduced (grepped the diff directly); both commit
subjects conventional; `tools/pre-pr-check --base phase/11h-test-mode` reproduced the PR's pasted
"PASS — 2 commit(s), 8 file(s) changed" verbatim, from a worktree needing the usual
`git checkout -b` first (bare detached HEAD — same tooling quirk as PR #170/#171). The status
fragment's every "not checked" (the four scenarios' correctness, the web target as a deliverable,
`level-01.md` regeneration) matched what the branch actually could not have exercised, given
`level-designer`'s files didn't exist on this branch — an honest partial scope, not an overclaim.

## Calibration: another fully clean single-task PR (phase 11h task 2, PR #246, issue #245)

Content-only branch (`assets/data/` + one status fragment, no code) that survived every check applied:
level-01/waves/formations/trajectories genuinely absent from the diff (not just "unchanged" — not
present at all, the strongest form of that check); the boss block's 13 keys verified one by one
against `JsonContentSource.parseBoss`'s `requireOnlyKeys` list and against `level-01.json`'s own boss
block, differing only in the one field the task allowed (`entersAt`); the wave-placement offset
arithmetic (`start = max(previousEndTime + offset, levelTime)`, chained through `FixedDuration`) was
reproduced by hand for the boss prelude's three overlapped placements and landed on the exact
numbers the status fragment claimed (starts 0.0/4.0/8.0, last prelude spawn at 20.0, core in position
at 31.4s); the LoadCheck claim was independently reproduced with a fresh probe, not just re-read; and
`node tools/build-level-docs.js` really did print `unchanged` for both docs when run from the actual
worktree. The one deviation from the signed-off level (three wave scenarios shipping at weapon level 1
instead of the level's accumulated level 2-4) was argued with reasons, not asserted, and stated as a
real trade-off rather than hidden. Worth keeping next to phase 11g's PR #239 as a second calibration
point for what "nothing to report, and it was earned" looks like on a docs/content-only branch.

## Phase 11h's two rejection-corrections, PR #254 and PR #253 — one clean, one mislabelled issue citation

Both were narrow, single-file corrections the project owner asked for after reviewing PR #249.
Both were code/content-correct and both passed every architectural and arithmetic check applied
(rebuilt in scratch worktrees, not trusted from the diff): #254's stub/real `TestMode.startScreen`
split confirmed by inspecting `game.jar` (only the stub `.class`, no `TestMenuScreen`/`TestScenarios`)
and by running the *real* TeaVM task (`:web:gdx_teavm_web_js_build`, not `:web:build`) and grepping
`app.js` for both names — zero hits, matching the claim; #253's boss-alone `entersAt` arithmetic
(310 → 175, 135px at 25px/s = 5.4s, +2.0s start = 7.4s) reproduced by reading `BossSystem.java`
directly, and the "empty `waves: []` loads and behaves" claim independently reproduced with a fresh
`LoadCheck` probe against the built jars — output matched the fragment's pasted transcript
character for character, including `placements=[]`.

46. **A citation to an issue number can be checked exactly like a citation to a file line, and the
    project's own precedent (false statements in documents outrank code defects) applies to it the
    same way.** PR #253's status fragment says a content-format gap ("no way to place a standalone
    power-up without an enemy dying") was "Filed as #252." Issue #252 is real, open, and entirely
    about something else — pickups not falling once already dropped — filed by the *project owner*
    (not by this branch's `level-designer` author), 23 seconds before #251, both in the same review
    batch that produced #250/#251. `gh issue view 252` and `gh api .../issues/252 --jq
    '{created,updated}'` (identical timestamps, never edited) settle both halves at once: the citation
    doesn't check out, and it wasn't even this branch's author who created the issue being cited.
    Whenever a status fragment says "filed as #N," open #N and read its actual title/body — do not
    assume a number in a document is correct just because a plausible-looking issue with that number
    exists in the tracker. Non-blocking here (the fix itself and every other claim in the fragment
    checked out; this is a documentation-accuracy note, not a code defect), but exactly the class of
    finding the project weighs most heavily.
47. **Direct-quoting the project owner's original Spanish review comment inside an English status
    fragment is a real, minor English-only violation, distinguishable from `docs/sources/`'s carved-
    out exception.** PR #253's fragment quotes *"si el test es para el boss solo debería aparecer el
    boss, no pre-enemigos"* and *"a lo sumo dejar power-ups"* verbatim — defensible in spirit (avoids
    mistranslating the actual instruction, the same reason `docs/sources/` exists) but the exception
    is written narrowly to that one directory, and this file is not in it. Worth a note on any status
    fragment that quotes a Spanish-language review comment directly rather than paraphrasing it in
    English.

Calibration: #254 alone had nothing to report at all — every observation in its fragment
reproduced exactly, including the one this project has burned itself on before (a `:web:build`-only
claim would have proven nothing about TeaVM; this fragment named the real task and I ran it myself).

## Calibration: a fully clean single-task PR (phase 11i, PR #263, `feat/path-trajectories`)

Passed on first read. Worth keeping as a reference for what a legitimate `default` method and a
correctly-argued deferral look like, since both were explicit judgment calls this task asked for.

- **A `default` interface method is not automatically the `BalanceValues` trap.** That trap was a
  fallback masking an unread JSON key — a genuine gap nobody would notice failing. Here,
  `TrajectoryDefinition.horizontalVelocityAt`'s default (`return vx()`) is the actual, permanent,
  correct behaviour for two of the three sealed permits (`constant`/`arc` have no case for
  horizontal acceleration anywhere in the catalogue) — not a stand-in for something unbuilt. The
  test: does the default skip reading data that exists and matters (trap), or does it encode a
  design fact that will only ever change by an explicit override on a new permit (legitimate)?
  `grep`-ing for any other implementer or exhaustive `switch`/`instanceof` chain over the sealed
  type outside `core` (there was none) is what confirms the second reading rather than assuming it.
- **A task can satisfy "argue where a mechanism lives" without shipping it, when the phase plan
  itself splits the argument (task N) from the implementation (task N+1) across different owners/
  modules.** PR #263 argues mirroring belongs in `game/` as content-load composition over public
  record accessors, demonstrates it once in a `core` test with no new API, and ships zero mirroring
  code — correct here specifically because the issue and plan explicitly scope the loader to a later
  task in a different agent's module, not because "argued, not delivered" is generally acceptable.
  Check the plan's own task split before treating a deferral as a gap.
- **A refusal reopened vs. dissolved is easy to fake by symmetry of prose and easy to verify by
  asking whether the *named cost* still applies.** `enterAndHold`'s hazard (LifetimeSystem never
  collects a resting entity) is unchanged for the unbounded case and only answered by a new
  constraint (bounding) — genuinely reopened. Waypoints' named cost ("per-entity path state") is
  the thing that stopped existing once loops/waits are bounded — dissolved. Reading which specific
  clause of the old refusal text the new one answers is faster and more reliable than reading the
  tone of "reopened"/"dissolved" labels themselves.
- Verified independently rather than taken on the status fragment's word: `./gradlew :core:test
  --rerun-tasks` (348 tests, 0 failures/skipped, via the XML aggregation technique), a full
  `./gradlew build`, the "no exhaustive switch on the sealed type outside `core`" claim (two greps),
  `Trajectory.java` untouched (`git diff` empty), declared-forbidden files untouched (`git diff
  --name-only` against the phase branch), and `tools/pre-pr-check --base phase/11i-path-vocabulary`
  reproducing the PR's pasted transcript exactly.

## PR #262 (`fix/pickups-fall`, phase 11i task 4, issues #260/#252) — the `BalanceValues` trap fires for real this time

The sibling case to PR #263's `default`-method calibration above, and the two are worth reading
together: #263's default was the legitimate kind, this one is the actual trap the calibration entry
was contrasting against.

48. **A `default` method on a content-value contract that returns a literal is indistinguishable, by
    type-checking alone, from an interface enumerated exhaustively by its one real implementer** —
    and the second reading is the true one here. `BalanceValues.pickupFallSpeed()` defaults to `20f`;
    `game`'s `JsonBalanceValues` (grepped directly, confirmed) has no `pickupFallSpeed` field and
    never calls `root.getFloat("pickupFallSpeed")`, so every running build — desktop, web, the game
    the project owner will actually play — uses the hardcoded `20f` regardless of what
    `assets/data/balance.json` says. The JSON key is not malformed or unread-with-an-error; it is
    silently inert, because `JsonBalanceValues.from` only ever reads keys it names, never rejects a
    key it doesn't recognise. This **does fail the acceptance criterion** ("a dropped pickup falls,
    at a speed read from `balance.json`") as shipped by this PR alone — it is true only once the
    filed follow-up (#261) lands. The author filed #261 rather than editing `game/`, correctly
    respecting the module boundary, and said so plainly in both the PR body and the fragment; not an
    overclaim, but the criterion is unmet until a second PR merges. **The `default` itself is the
    right call to keep**, not the defect — removing it would break `game`'s compile immediately
    (confirmed: `JsonBalanceValues` doesn't implement it), which is a worse failure mode than a
    silently-inert JSON key for exactly the length of one follow-up PR. What would have caught the gap
    without needing #261 to remember to close it: a test asserting the value comes from *content*
    (e.g. a `JsonBalanceValues.from` unit test reading a fixture JSON and asserting the field), as
    opposed to every test actually shipped, which only asserts the number a `TestBalance`/default
    field returns — indistinguishable, by any test in this PR, from a constant.
49. **A method's name can start lying the moment its javadoc stops matching it, without a single line
    of its own body changing shape.** `LifetimeSystem.expireProjectiles` gained a third layer,
    `CollisionLayer.PICKUP`, in its one guard condition — the class-level javadoc was updated
    ("Projectiles and pickups are expired…") but the private method itself, and its name, were not.
    Trivial to rename (`expireProjectilesAndPickups` or similar); flagged as a note, not a blocker,
    since nothing outside this one file reads the method by name and the class javadoc already tells
    the truth. Worth checking on every PR that widens a layer guard: does the *method* name still
    describe the guard, separately from whether the *class* javadoc was updated.
50. **A replay test's golden fingerprint staying byte-for-byte unchanged across a behavioural PR can
    mean the fixture never actually reached the changed code path within its own tick budget, not
    that the change is provably inert.** `LevelScoreReplayTest`'s 900-tick fixture drops two pickups
    (`shield` at t=9.0s, `attachment` at t=9.5s) and its golden (`entities=11`, unchanged by this PR's
    diff) still passed after the fix. Reproduced independently with a scratch probe compiled against
    `core/build/classes/java/{main,test}` (see `[[audit-techniques]]`'s probe technique) instrumenting
    `world.pickups()` every tick: exactly one pickup entity exists across the whole run, first
    appearing around tick 608 (~t=10.1s) and still present at the final tick 899, at `y=173.15`,
    having fallen from spawn but never within 16 units of the playfield's lower margin and never
    collided with the player. The fixture exercises `CleanupSystem` attaching a real, falling `Motion`
    (confirmed: y decreases exactly 10 units per 30 ticks = 20 units/s = the balance value) but never
    exercises `LifetimeSystem`'s new `PICKUP`-layer expiry at all — the golden's insensitivity to the
    change is coincidental (the pickup just hadn't finished falling when the script ended), not
    evidence the expiry path preserves the score/entity-count invariant this golden is supposed to
    guard. Not attributed to the author as an overclaim — the fragment never claims this replay covers
    the expiry rule, only that the golden still passes, which is true and considerably weaker than it
    sounds. Whenever a PR touches a system a long-running golden-fingerprint replay could exercise,
    trace whether the fixture's own script actually reaches the changed branch within its tick count,
    the same way pattern 34 asks for the *system* to be reached — here it's a *temporal* budget, not a
    missing `.withX(...)` call, that keeps the golden from being real evidence.

Everything else checked out clean: 335 `core` tests, 0 failures (`--rerun-tasks`, XML-aggregated,
matching the fragment exactly); no `com.badlogic.gdx`/`Math.random`/clock read/`Thread`-family
construct in the diff; `level-01.json`/`waves.json`/`formations.json`/`trajectories.json` absent from
the diff entirely; the module boundary held against the sibling `feat/path-trajectories` branch (zero
file overlap, confirmed by diffing both against the same merge-base); commit subject 58 characters;
`MotionSystem.integrate` genuinely needs no change (walks every `Motion` generically, a pickup has no
`Trajectory` so `advanceTrajectories` skips it); no per-frame allocation (the new `Motion` is
allocated once per drop-spawn event, the same shape as the `Transform`/`Collider`/`Sprite`/`Pickup`
allocations already there); no `GameEventSink`/HUD/audio consumer expects an event for a pickup's
destruction, collected or expired (only `EnemyDestroyed` exists as a concrete `GameEvent` anywhere in
`core`, confirmed by grep) — matching the issue's own framing that a missed pickup is silent, not a
special case. The fragment states the 20 units/s figure as a candidate throughout, cites the level-1
cost honestly (five drop kinds, seven spawn events, no content file touched), and correctly writes
"not checked" for playing the game.

Related: [[defect-patterns]].

## PR #267 (`feat/path-loader`, phase 11i task 2, issue #264) — a coordinator's framing that didn't match the primary source, and a rule-3 guard confirmed closed on every axis

The task brief handed to me characterised the `{"wait": seconds}` shorthand as "not in the published contract" and an unprompted addition by the loader's author. Reading `gh issue view 259 --comments` directly showed the opposite: `core-domain`'s own comment on #259 explicitly offers it ("The loader is free to accept a `"wait": <seconds>` shorthand and translate it to `{ "vx": 0, "vy": 0, "duration": <seconds> }` if that reads better in the JSON"). The shorthand is a written case, not an unauthorised extension — invariant 6 is satisfied, not violated. The status fragment and PR body both correctly cite the issue comment for it.

61. **A task brief's characterisation of "what the contract said" is itself a claim to verify against the primary source, not a premise to build the review around.** Whoever wrote my instructions read #259 loosely or from memory; `gh issue view 259 --comments` settled it in one command. Read the cited issue comment yourself before accepting a framing of what was or wasn't authorised, even when the framing comes from the coordinator rather than from the branch under review.
62. **A sealed-type mirror mechanism that reconstructs through each kind's own canonical constructor cannot let mirroring flip a validity guard, and this is provable by algebra on the guard's condition, not just by testing cases.** `PathTrajectoryDefinition`'s rule-3 check is `last.vx() == 0f && last.vy() == 0f`; the mirror negates only `vx` per segment. Since `-x == 0 ⇔ x == 0`, the truth value of the guard is invariant under the mirror transform — a legal path's mirror is always legal, an illegal one's mirror (if it could be built at all) would always still be illegal. Combined with both `PathTrajectoryDefinition` constructors delegating to the compact constructor (confirmed by reading the record — the 2-arg convenience constructor calls `this(...)`, so there is no back door), this closes the "mirror of a legal path becoming illegal or vice versa" question by proof rather than by enumeration. Worth the general technique: when a transform only touches fields a boundary guard doesn't read, or only negates fields the guard tests for zero-equality, check whether the guard's condition is provably invariant under the transform before reaching for a test.
63. **A recursive multi-hop resolution's test can pass under a mutation that removes the recursion, purely because of `HashMap` bucket order for the specific ids chosen.** Mutating `resolveMirror`'s recursive call to a direct `trajectories.get(...)` lookup (breaking "a mirror of a mirror works regardless of declaration order") correctly turned two *other* tests red (`mirrorCycleFailsAtLoadNamingFileAndId`, `badMirrorReferenceFailsAtLoadNamingFileAndId`, both via an uncaught `IllegalStateException` from `mirror(id, null)`) but left `mirrorOfAMirrorResolvesRegardlessOfDeclarationOrder` green, reproducibly across reruns. Cause: the fixture's mirror ids are `"a"`/`"b"`/`"c"`; `"b".hashCode() & 15 = 2` and `"c".hashCode() & 15 = 3` in a default-capacity `HashMap`, so `mirrorEntries.keySet()`'s iteration order happens to resolve `"b"` before `"c"`, and the mutated one-hop lookup then finds `"b"` already promoted to `trajectories` by the time `"c"` is processed — accidentally reproducing the recursive result for this specific 2-mirror chain. The production code is genuinely recursive and correct (confirmed by reading it — resolution never depends on outer-loop order), so this is not a defect; it is a limit on what this one test's failure would have proven, worth naming because the test's own name promises order-independence and the mutation found a hole in demonstrating that, not in the guarantee itself. Whenever mutating a recursive/order-independent resolution to confirm a test's claim, also check whether the fixture's specific identifiers could accidentally satisfy a weaker, non-recursive implementation via incidental iteration order — three-or-more-hop chains with ids chosen to land in adjacent hash buckets are more likely to survive this coincidence than genuinely random ones.

Everything else checked out clean and is not repeated in detail here: diff exactly 3 files (matching the PR's own claim), commit subjects 45/58 chars, no forbidden import (`Thread`/`Executor`/`CompletableFuture`/`ReentrantLock`/`Math.random`/`new Json(`) introduced, `core/`, `JsonBalanceValues.java`, and all four `assets/data/*.json` content files empty in the diff, full `./gradlew build` green, the malformed-segment mutation (dropping the `has("duration")` check in favour of JDK-default `getFloat` overloads) correctly turned `malformedSegmentFailsAtLoadNamingFileAndId` red and was restored clean afterward.

Related: [[audit-techniques]].

## PR #272 (`feat/path-entries`, phase 11i task 3, issue #271) — a real timing error in the one arithmetic the task exists to get right, everything else clean

Four `path` trajectories (`descend-and-turn-left`/`-right` as a mirror pair, `sweep-wait-drop`, `stair-descent`) plus four `test-path-*` waves and scenario files. Reconstructed all four independently by stepping `segmentAt`'s accumulation logic in a standalone script rather than trusting the fragment's own numbers, per the task's own instruction.

64. **`sweep-wait-drop`'s "meant to look like" arithmetic in the status fragment is internally inconsistent with its own JSON, by a systematic 0.5 s.** Segments are `{vx:-60,vy:-22,duration:2.0}`, `{wait:2.5}`, `{vx:0,vy:-90,duration:5.0}` — the sweep segment's own duration is 2.0 s. The fragment writes "the sweep ends at (67, 236.5) at t = 2.5 s" (position right, time wrong — it ends at t = 2.0 s), then "the wait holds that point to t = 5.0 s" (should be t = 4.5 s, i.e. 2.0 + 2.5), then claims the drop crosses y = 0 at "t ~ 7.6 s" and the safety box at "t ~ 9.0 s" — reproducing the segment walk by hand gives t ≈ 7.13 s and t ≈ 8.55 s respectively. Every position value in the fragment is correct; every elapsed-time label from the wait onward is shifted by the sweep segment's own duration, as if the author added the *wait's* duration to the *sweep's claimed* end instead of its *real* end. The other three paths' arithmetic (turn's x=0/safety-box crossings, the mirror's exact vx-negation, the loop's four-repeat stop-and-fall) all reproduced exactly by independent simulation — this was one path's arithmetic, not a pattern across the PR. **Technique**: when a fragment claims to have derived positions "by stepping the real function," do not just spot-check the final position — recompute the *cumulative segment-boundary times* by hand from the JSON's own durations and diff every intermediate `t` the fragment names, not only the terminal one. A wrong final position is easy to catch; a right position with a wrong time label under it is not, and it is exactly the kind of error a reader would carry forward when placing a real wave around this trajectory (a level built expecting the stop to end at t=5.0 will be off by half a second every time this shape is used).

65. **A citation with the wrong line number, for a claim that is otherwise true.** The fragment and PR body both cite `JsonContentSource.java:91` for "reads waves from exactly one file — `dataDir.child("waves.json")`". Line 91 in the constructor's five-line load sequence is actually `loadTrajectories(...)`; `loadWaves(reader, dataDir.child("waves.json"))` is line 95. The substantive claim (waves load only from that one file, confirmed independently) holds — it is a four-line miscount, not a fabrication — but it is exactly the kind of small citation slip that CLAUDE.md's "name the file, or say not built" convention exists to catch, and it is worth grep-confirming every `file:line` a fragment cites rather than trusting the surrounding prose.

**A tool gotcha worth its own entry**: reproducing "all nine level ids load through a real `JsonContentSource`" from this Git Bash meant compiling a throwaway `LoadCheck.java` against `core`'s and `game`'s compiled classes plus the `gdx` jar. Joining two absolute Windows-style paths (via `$(pwd)/core/build/...` interpolated as `/c/Users/...`) with `;` in a single `-cp` argument silently breaks — `javac`/`java` report the second and third classpath entries' packages as not existing, with no warning that the classpath itself was mangled. Joining the exact same paths with `:` (POSIX classpath style) works, because Git Bash's argv path-conversion recognizes and correctly rewrites a `:`-joined multi-path argument into a proper Windows `;`-joined one, but does not do the same for an argument that already contains literal `;`. **Always build multi-entry classpaths for `javac`/`java` in Git Bash with `:` as the separator, never `;`, regardless of how the paths were obtained.**

**A `git log` gotcha that produced a false alarm worth naming**: `git log --oneline --all -20 <ref>` does not scope to `<ref>` — `--all` overrides the positional argument and walks every ref in the repo, silently. Comparing `origin/feat/path-entries` against `origin/phase/11i-path-vocabulary` with a raw two-tip `git diff` (rather than against their `git merge-base`) likewise produces a diff that looks like the feature branch *removes* work (here, the TESTS-menu wiring) that a sibling PR had meanwhile added to the phase branch — it does not; the feature branch simply predates that sibling merge. Always diff a PR branch against `git merge-base <phase-branch> <feature-branch>`, never against the phase branch's current tip, when phase work is landing in parallel.

**Calibration**: `docs/plan/11i-path-vocabulary/status/271-path-entries.md`'s honesty is real — "not checked: how any of the four paths looks", "not checked: whether 2.5 s / four steps / `enemy-tank` are the right choices" are both present and both true (confirmed no `gradlew :desktop:run` beyond a start-and-kill). The waves.json boundary violation is disclosed, not hidden, and is correct on the merits per the coordinator's own admitted error (`JsonContentSource` reads waves from exactly one file, confirmed at line 95; the four entries are purely additive, `level-01.json`/`formations.json` diff empty, confirmed against `merge-base`). `./gradlew build` green (reproduced, exit 0), `tools/pre-pr-check` output matches exactly when rerun, `node tools/build-level-docs.js` prints `unchanged` for both generated docs on this branch (reproduced), and the pre-existing `pickupFallSpeed` drift is correctly attributed to task 4/#252 (confirmed: `balance.json` untouched by this branch's diff, and the phase branch already carried that line before this branch's base commit). The TESTS-menu limitation the fragment reports as unresolved has, independently, already been fixed by a merged sibling PR (#275) using the exact ids/labels this fragment itself suggested — worth noting as resolved-by-the-time-this-lands rather than a defect.

## PR #288 (`feat/absolute-path-syntax`, phase 11j task 1, issue #287) — a clean implementation next to a real, unmentioned red check

The loader work itself (`"waypoints"` as a mutually-exclusive absolute alternative to `"segments"`,
resolved at load into the same `PathSegment`s) is sound on every substantive axis checked: the
two-key distinction really is unambiguous and structurally refuses per-leg mixing (confirmed by
mutating `hasSegments == hasWaypoints` to `!hasSegments && !hasWaypoints` in place and watching
exactly the mixed-form test go red, nothing else); the relative/absolute equivalence claim is real
(mutating the `dx`/`dy` order in the `PathSegment` construction turned the equivalence test red,
along with two others that happened to share the same arithmetic); rule 3 genuinely cannot be
broken through the absolute form (traced by hand through every edge case the task named — a
same-point destination, a wait-only tail, a single-waypoint list, an entry point carrying a speed —
each already refused before `core` would ever see it, or reaching `core`'s existing refusal
unchanged); `core/` and `assets/data/` genuinely untouched; JSON read with `JsonReader`/`JsonValue`
only; commit subjects clean; no `Co-Authored-By`.

66. **A PR's own "## CI" section quoting one green `gh run list` row is not the same as CI being
    green**, when a second workflow triggers on the `pull_request` event and the author only ever
    ran `gh run list --branch <name>` and read the row they expected. `.github/workflows/pr-check.yml`
    (added 28/08/2026) runs separately from `ci.yml` and enforces, among other things, that a PR is
    *opened* as a draft. PR #288 was opened ready, and `pr-check` failed 3 seconds after the PR's own
    `createdAt` with "FAIL opened ready rather than as a draft" — a real, current, red check, visible
    in the exact same `gh run list --branch feat/absolute-path-syntax` output the PR body quotes, on
    a different row than the one the body describes. This is the same shape as phase 09's "`ci.yml`
    has never run on a runner" — a check that exists and is red, described as if it did not exist —
    except here the omission is very plausibly an oversight (`tools/pre-pr-check` cannot see draft
    state at all, by design, since it runs before a PR exists) rather than an invented claim. Still:
    every row `gh run list` prints for the branch needs accounting for in the CI section, not just
    the row that matches what the author expected to see.

Related: [[audit-techniques]].

## PR #298 (`feat/path-speed-multiplier`, phase 11j task 2, issue #296) — a clean mechanism, a false claim about which guard actually fires

Verdict: accept. `core`/`assets/data` genuinely untouched (`git diff --stat phase/11j-absolute-paths...HEAD -- core assets/data` empty), no forbidden import, `ay × k²` arithmetic independently reconstructed and correct, the two-pass `resolveDerived` (renamed from `resolveMirror`) genuinely composes `mirrorOf`/`speedOf` in either order via cycle-safe recursion using a fresh `LinkedHashSet` per top-level id (traced both possible `HashMap` iteration orders for the `a`/`b` cycle fixture by hand — both throw, both name `a`).

67. **A guard's javadoc and its test's own name can both misattribute *which* field rejected an
    extreme input, while the observable behaviour (fails, names the id) stays correct.**
    `faster()`'s javadoc claims "an absurd multiplier that underflows a duration to zero is refused
    by `PathSegment`", and the test `aMultiplierThatUnderflowsASegmentDurationFailsNamingTheDerivedId`
    asserts exactly that framing. Reproduced the actual arithmetic in an isolated scratch copy of the
    repo (never touching the audited worktree — `cp -r` to `/tmp`, mutate there, run there, discard):
    for the test's own fixture (`vy=-30`, `multiplier=3e38`), `duration / multiplier` computes to
    `3.333333E-39` — a tiny but nonzero, non-underflowed float, which `PathSegment`'s `duration <= 0f`
    check does **not** reject. What actually throws is `vy * multiplier = -9e39`, which overflows
    float range to `-Infinity` and trips `PathSegment`'s separate `requireFinite` check on velocity,
    not duration. Confirmed by constructing `PathSegment` directly with the computed values and
    printing the real exception message ("a path segment's vy must be a finite number, was
    -Infinity"). The velocity-overflow threshold (`multiplier > Float.MAX_VALUE / |vy|`, ~1.1e37 for
    `vy=-30`) is reached at far smaller multipliers than the duration-underflow-to-exact-zero
    threshold (~duration × 7e44), so for any realistic non-zero velocity this "duration underflow"
    guard the docs describe essentially never fires — the test's chosen multiplier could not have
    exercised it even if it existed as a distinct path. Notably the *authorising issue comment*
    (`gh issue view 296`) hedges correctly — "a velocity **or** a duration out of range" — so the
    narrower, wrong claim was introduced only in the code's javadoc and the test's name/doc, not in
    the design discussion. Non-blocking (both the failure and its file/id naming are real), but exactly
    the class of claim worth a one-line correction: reword the javadoc/test name to "a velocity or
    duration pushed out of range" rather than pinning the mechanism to one field, since the actual
    field that fires depends on which of the two thresholds the chosen numbers happen to cross first.
    **Technique reusable beyond this PR**: when a status/javadoc claims "X is refused because value V
    underflows/overflows", don't just confirm the test throws — construct the intermediate value by
    hand (a five-line throwaway program against the module's own compiled classes, in `/tmp`, `:`-joined
    classpath per the existing Git Bash note) and check which specific guard's condition it actually
    trips. A `Set.of()`-shaped extreme-value test is not proof of *which* clause caught it.

Also independently reproduced rather than trusted: the 16/16 zero-failure test count
(`game/build/test-results/test/TEST-...SpeedMultiplierTest.xml`); the mutation-testing claim
("`faster` mutated to a `scale`... 16 tests completed, 5 failed") by applying the exact same mutation
(`ay × multiplier` instead of `× multiplier²`, segment `duration()` left unscaled) in an isolated `cp
-r` scratch copy — reproduced the identical 5 failing test names; the mirror/speed composition
arithmetic for both orders by hand; and that no current wave in `waves.json`/`level-01.json` uses one
shape at two speeds within a wave, backing the branch's "nothing written asks for the spawn-event
alternative" argument. The plan's own task-2 text (`docs/plan/11j-absolute-paths/plan.md:58`) already
frames the load-vs-spawn-event choice in the same terms the PR argues it in — not a post-hoc
rationalisation.

**Technique reused deliberately, worth naming explicitly**: mutation-testing a claim by editing the
audited repo's own file, even when planning to revert, is out of bounds for a read-only auditor — the
auto-mode classifier itself blocked a `sed`-based in-place edit of `JsonContentSource.java` here. The
correct move, used twice in this review, is `cp -r <repo> /tmp/<scratch>`, mutate and run entirely
inside the copy, then `rm -rf` it — proves the same thing without ever writing to the worktree under
review.

Related: [[audit-techniques]].

## PR #299 (`content/level-one-trajectories`, phase 11j task 3) — a systematic, radius-shaped error hiding in five "removed at t" numbers, everything else exact

Seven trajectory entries (five authored, two `mirrorOf`), five waves, five scenario files. Kind
classification, absolute-form usage, rule-3 compliance, `atX`/radius-offset arithmetic, and every
mid-path/edge-crossing timestamp all reproduced exactly by independent analytic re-derivation (not
Euler stepping — `PathTrajectoryDefinition`/`parseWaypoints` produce piecewise-constant velocity, so
closed-form arithmetic is exact and stronger than resimulating at a fixed `dt`).

66. **A whole class of claimed numbers (the final "removed at t = X s" in every one of five
    trajectories checked) is off by a near-constant amount, and the amount is explained by one
    missing term, not five unrelated slips.** Re-deriving `cross-left`, `dive-and-retreat`,
    `slide-left-then-descend`, `hold-the-line-and-exit` and `sweep-the-width-and-drop` by hand against
    `LifetimeSystem.isPastSafetyBox` (`position ± radius` crossing `playfield edge ± 128`) gave removal
    times 0.084–0.128 s **later** than the fragment's own claimed numbers in all five cases — never
    earlier, never zero. Solving each case for "what distance is missing" backs out 5.65–6.88 units in
    every one, which lands almost exactly on the archetype's own collider radius (`enemy-basic` 5.5,
    used in three; `enemy-shooter` 6.5, used in two) to within 0.4 units. Confirmed directly: recomputing
    each case with the safety-box condition evaluated against the *centre* position instead of the edge
    (i.e. dropping the `± radius` term `core`'s own check applies) reproduces all five claimed numbers to
    within 0.01 s. Every other number in the same fragment — mid-path positions, edge-crossing times
    that *do* use `± radius` (e.g. "crosses the left edge", "out of the bottom") — is exact. The bug is
    narrow: whatever produced the "removed" line in the author's own verification program applied the
    128-unit safety margin without the entity's radius, while everywhere else in the same program the
    radius is applied correctly (spawn `y = playfield + radius`, edge-exit checks). Non-blocking here —
    it never threatens the "every wave ends comfortably after its last entity is removed" claim, since
    the true (later) removal time is still well inside every wave's `fixedDuration` — but it is exactly
    the shape phase 11i's `sweep-wait-drop` finding names: a description that disagrees with its own
    JSON by a small, systematic, reproducible amount. **Technique**: when a fragment claims several
    structurally similar events (here, "removed at t" for N different shapes), don't just re-derive one
    and generalise — re-derive all of them and check whether the residuals cluster on a suspicious
    constant (a radius, a margin, a tick) rather than scattering randomly. A single case's 0.1 s
    mismatch looks like noise; five cases whose implied "missing distance" all land within 1 unit of
    each other look like a real omitted term, and this is what turned it from a suspicion into a
    confirmed, reproducible defect without needing to run the author's own script.

Also worth recording as a *smaller*, less certain sibling finding: two absolute-form arrival positions
(`hold-the-line-and-exit`'s claimed `y = 196.4`, `sweep-the-width-and-drop`'s claimed crossing
`y = 220.1`) are each ~0.1–0.4 units off the exact analytic value implied by the fragment's own stated
formula ("authored `y` + radius" — 190 + 6.5 = 196.5, 214 + 6.5 = 220.5, both should end in `.5`,
neither reported number does). Unlike finding 66, this one plausibly comes from the disclosed 1/100 s
sampling granularity landing just past a segment-boundary crossing rather than exactly on it, and the
per-case magnitude (0.1, 0.4) does not cleanly back out a single constant the way the removal numbers
do. Reported as a real but lower-confidence discrepancy, not asserted as the same bug as 66.

Everything else on this branch checked out cleanly and is worth recording as calibration: the
`constant`/`path` kind boundary was applied correctly to all three shapes the task named for a second
look (`dive-and-retreat`, `hold-the-line-and-exit`, `sweep-the-width-and-drop` all genuinely turn or
wait and cannot be `constant`); both absolute paths' `atX` requirement (`entry.x / 208`) matches the
wave that places it exactly (0.50 and 0.10); the `slide-left-then-descend` mirror pair's converging
geometry and its stated `atX` window both reproduced by hand; rule 3 holds for every new entry (every
last leg has nonzero velocity, confirmed from each waypoint list's own `dx`/`dy`); `mirrorOf` only
negates `vx` (confirmed in `JsonContentSource.mirror`), applied here to a `constant` and to a relative
`path`, never to either new absolute path — so the "does a mirror ever apply to an absolute path"
question this task's own instructions raised does not arise in this content; `game`/`desktop`/`web`/
`core` diffs are all empty; `waves.md` regenerated correctly (5 rows added, nothing else moved);
`gh run list` showed both checks green on the tip commit, matching the PR body.

Related: [[audit-techniques]].

## PR #312 (`fix/level-docs-reads-paths`, phase 11k task 1, issue #310) — a tools-only branch, and an asymmetric exit criterion inside a function that reads as symmetric

`tools/build-level-docs.js` only (plus the regenerated `docs/levels/level-01.md` and the status
fragment) — no `core`/`game`/`desktop`/`web`/`assets/data` diff, so invariants 1-6 are structurally
out of reach; commit hygiene clean (2 commits, subjects 58/66 chars, no `Co-Authored-By`); both `gh
run list` rows (`CI`, `PR check`) green on the tip commit, matching the PR body; `pre-pr-check`'s
pasted output reproduced. Every arithmetic claim checked against `JsonContentSource.java` line for
line matched exactly: `faster`'s `ay * multiplier²` (confirmed both by reading and by constructing a
`speedOf` entry in a scratch `cp -r` copy and reading the generated `ay` — 27 → 108 at multiplier 2,
i.e. ×4, not ×2), `mirror`'s vx-only negation, `parseWaypoints`'s `duration = |B-A|/speed` and
`vx = dx/duration`, cycle detection (reproduced the exact `a -> b -> a` message on a scratch fixture)
and order-independence (a `mirrorOf` pointing at an id declared *later* in the file resolved fine on
a scratch fixture). The claimed pre-existing `same`-shortcut bug is real: `git show
phase/11k-level-one-rebuilt:tools/build-level-docs.js` shows the old code compared a single `drift`
field to `0.05`, and the new code compares `swept.min`/`swept.max` against the spawn footprint
instead — confirmed to change nothing for `constant`/`arc` (their drift is monotonic, so the two
checks agree) and to fix exactly the case named (a `path` whose legs drift in opposite directions).

68. **A boundary-crossing walk that computes all four playfield edges with one function reads as
    symmetric and is not: two axes use "fully off" (matching `core`'s own definition) and the other
    two use "first touch."** `pathSweep`/`crossLeg` (new in this PR) mirror
    `LifetimeSystem.isFullyOffPlayfield` exactly on the vertical axis — confirmed by their own
    javadoc's derivation and by hand: `downTarget = -(270 + 2·radius)` is exactly the point at which
    the *whole* entity's bottom edge clears the screen, matching `y + radius < 0`. But the horizontal
    checks use `at.min + h` for a *leftward* exit and `at.max + h` for a *rightward* one — the
    **leading** edge of the formation's footprint in the direction of travel, not the **trailing**
    one. Reconstructed on two real, shipped fixtures: `test-path-turn`'s `descend-and-turn-left`
    (`enemy-tank`, radius 10.5, `atX 0.85`) reports `x swept` `0.0..187.3` — the leading (left) edge
    lands exactly on `0.0`, while the trailing (right) edge, `187.3`, is unchanged from spawn and
    stays 10.5 units inside the visible screen at the moment the function calls the shape "gone."
    `test-hold-line`'s `hold-the-line-and-exit` (`enemy-shooter`, radius 6.5, `atX 0.50`) similarly
    reports `97.5..208.0`, landing exactly on the right edge with the trailing edge (97.5) still 6.5
    units inside it. The true full-exit time is later by `radius / |vx|` (≈0.09-0.19 s in these two
    cases) and, worked out by hand for `hold-the-line-and-exit`, actually falls *outside* [0, 208]
    (swept max ≈ 221), which the current code can never report — because the function returns the
    instant it finds *any* valid candidate, a path's `min`/`max` can structurally never exceed the
    playfield bounds via a horizontal exit that starts on-screen, so the `**leaves**` marker (which
    fires correctly for `constant`/`arc`, whose vertical-only stopping time is independent of the
    horizontal one and can genuinely run past the width) is dead code for the common case of a
    `path` that exits sideways from an on-screen spawn. The status fragment discusses, at length and
    honestly, the *difference* between `path`'s dual-axis convention and `constant`/`arc`'s
    vertical-only one — but never notices this second, internal asymmetry between the two halves of
    its own dual-axis check. Reported as "worth arguing with" rather than a blocking defect: nothing
    in the plan's acceptance criteria defines "on screen" precisely enough to call one convention
    wrong, and the magnitude is small — but the phase's stated purpose for this document is exactly
    "every content task after this one reads the numbers it prints to decide how much runway a shape
    needs," and a systematically short, edge-shaped discrepancy that is invisible because it always
    lands exactly on the boundary is precisely the shape phase 11j's radius-shaped finding (66) names,
    one level up: there it was a missing term in a hand derivation, here it is an inconsistent
    definition inside the tool meant to replace hand derivation. **Technique reused**: derive the
    number for *both* directions of the same physical exit (leading edge vs. trailing edge) by hand,
    not just the one direction the function returns — an asymmetry between two branches of one
    function that both claim to answer "did it leave" is invisible from reading the branch that fires
    in isolation, and only shows up by asking what the *other* edge of the same entity was doing at
    the reported moment.

## PR #316 (`feat/absolute-path-atx-check`, phase 11k task 2, issue #300) — clean, and the reflection claim held up independently

`tools/build-level-docs.js` gained an `entryX` field on any `path` resolved from `waypoints`
(never from `segments`), propagated through `mirrorOf` (reflection, `width - entryX`) and `speedOf`
(unchanged), and a new per-spawn check comparing `sp.atX * 208` against it within
`ATX_TOLERANCE_PX = 1.1`. Verdict: accept, nothing new. Reproduced independently rather than trusted
from the status fragment: `cp -r` the worktree to the scratchpad (in-place edits to a repo under
audit are the kind of thing the auto-mode classifier can refuse — see
`[[audit-techniques]]`'s TeaVM-dist entry for the same workaround), built scratch `mirrorOf`/`speedOf`
derivations of both shipped absolute trajectories plus a `level-99.json` exercising them, and got
the exact same three findings and two silences the author reported, including the one that actually
proves the claim: mirroring `sweep-the-width-and-drop` (`entryX 20.8`) requires `atX 0.90`, not the
`0.10` a plain sign-flip on the mirror would have produced. Idempotency (`unchanged` on both docs)
and `pre-pr-check`'s pasted output both reproduced verbatim.

68. **A reflection-vs-negation claim about a derived field can only be told apart by an entry point
    that is not equidistant from the centre either way.** Both trajectories this repo had already
    shipped with `waypoints` before this task (`hold-the-line-and-exit`, entry `x=104`, exactly the
    playfield's centre) are the wrong fixture to test a reflection formula against, because
    `width - entryX` and `-entryX` (mod width, informally) agree at the centre — the author noticed
    this and built an off-centre scratch fixture (`sweep-the-width-and-drop`, `entryX 20.8`) instead
    of trusting the shipped content to distinguish the two formulas. Generalizes past this PR: before
    accepting that a "mirror negates X" javadoc/comment is correct for a field that is a *position*
    rather than a *delta*, check whether every value the claim was tested against sits on the mirror
    axis itself.
69. **A per-spawn check that compares one `atX` against one trajectory field is implicitly checking
    the formation's anchor, not any individual entity — worth naming even when current content never
    exercises the gap.** `SpawnSystem.positionSpawned` computes each entity's real x as
    `anchorX + slot.offsetX()`, and every formation in `formations.json` except `pair` (`±44`, no
    zero-offset slot) has at least one slot at `offsetX: 0`; both trajectories carrying `entryX` are
    placed with `formation: "single"` (`offsetX: 0`), so `anchorX` and the one real entity's `x`
    coincide today and the check's silence on the anchor really does mean the entity is correctly
    placed. Nothing in `core` or this check would catch an absolute path placed on a multi-slot
    formation whose anchor matches `entryX` while every other slot flies the same waypoint-authored
    shape shifted sideways by its own `offsetX` — arguably not a bug (a formation flying one shared
    shape shifted per slot is exactly what a `constant`/`arc` trajectory already does), but nothing
    documents that an absolute path's literal-coordinate meaning is anchor-only until it is combined
    with a multi-slot formation, and `JsonContentSource.parseWaypoints`'s own javadoc already names
    the general version of this cost ("an absolutely-authored path can only happen in one place").
    Not a defect in this PR — a suspicion to hand forward to whichever phase first pairs an absolute
    path with a formation other than `single`.

## PR #319 (`feat/content-places-a-pickup`, phase 11k task 4 first half, issue #318) — a second cursor added next to an existing one, and the one asymmetry that mattered

`SpawnSystem` gained a second per-wave cursor (`ActiveWave.pickupCursor`) for `WaveDefinition.pickups()`,
scheduled off the same `ActiveWave` clock the existing spawn cursor uses. Diff matched the coordinator's
claim exactly (`git diff phase/11k-level-one-rebuilt...HEAD --stat`: five `core` main files, two `core`
test files, one status fragment). `core:test` green independently (360 tests / 0 failures, aggregated
from `core/build/test-results/test/*.xml`), `game:compileJava` green independently, no
`com.badlogic.gdx`/`Math.random`/thread-family import anywhere in `core/src/main`. Only one production
`implements WaveDefinition` (`SimpleWaveDefinition`), so the new `default pickups()` cannot be silently
hiding a second implementer that needed a real override.

70. **Adding a second per-wave cursor to an existing scheduler is safe exactly to the extent every
    `hasEnded`/end-condition branch was updated to know about it — check each branch by hand, don't
    trust that "it uses the same clock" implies "it uses the same completeness check."**
    `SpawnSystem.hasEnded`'s `Cleared` branch checks `wave.cursor >= wave.definition.spawns().size()`
    but never references the new `wave.pickupCursor` at all. For `FixedDuration` this is symmetric
    with a pre-existing hazard (confirmed by probe: a *second spawn event* scheduled past a
    `FixedDuration` wave's own duration is *also* silently lost — `entityCount` stayed 1 after 10
    ticks against a duration of 2s and a second spawn at local t=5s — so `core` already accepted "a
    badly authored duration can strand a late spawn" before this PR, and pickups inherit that same,
    pre-existing shape without making it worse). But for `Cleared` the two cursors are **not**
    symmetric: a spawn can never be lost this way in a `Cleared` wave, because `hasEnded` cannot
    return true until `cursor >= spawns.size()` — the wave literally cannot end with spawns still
    pending. Pickups get no equivalent guard. Probe (`java` against `core/build/classes/java/main`
    plus a hand-written `Probe.java`, no build, no worktree mutation): a `Cleared` wave with one
    spawn and one `PlacedPickup` scheduled at local t=30s, whose single spawned entity is destroyed
    on tick 2 — `hasEnded` goes true, the wave is dropped from `activeWaves`, and 40 more ticks (well
    past t=30) still show `world.pickups().size() == 0`. The reward silently never exists, no
    exception, no log, and no test in the PR exercises a `Cleared` wave with a still-pending pickup
    at the moment its spawns are exhausted and its last entity dies — every `Cleared`-wave pickup
    test in the PR (`placedPickupCarriesNoWaveOrigin`) places its pickup at `at=0f`, always already
    due before the wave could possibly end. The fix is a one-line addition to the `Cleared` branch,
    mirroring the existing spawn-cursor guard: `&& wave.pickupCursor >= wave.definition.pickups().size()`.
    Generalises: whenever a scheduler gains a second, independently-advancing cursor over the same
    clock, walk every branch of the completion/termination check by hand and ask whether it was
    written before or after the second cursor existed — a check untouched by the PR is a check that
    was written for one cursor's completeness, not two.
71. **A `SystemOrder` placement decision can be correct on its own terms and still create an
    unexamined behavioural split between two paths that "produce the same entity."** Confirmed by
    reading `SystemOrder`'s declaration order: `SPAWN` is ordinal 5, `COLLISION` is ordinal 10,
    `CLEANUP` is ordinal 14. A placed pickup is created inside `SpawnSystem` (`SPAWN`, before
    `COLLISION`), so it is visible to `CollisionSystem` on the very same tick it appears — a player
    ship already occupying that exact position could collect it the instant it spawns. A dropped
    pickup is created inside `CleanupSystem` (`CLEANUP`, after `COLLISION`), and that class's own
    javadoc says so explicitly: "the spawned pickup only becomes collectable from the next tick's
    `CollisionSystem` pass." Both paths call the identical `CleanupSystem.createFallingPickup` and
    produce byte-identical components, so "the two paths produce the same entity" is true of the
    entity and false of when it can first be collected. Not necessarily wrong — a bomb-drop-shaped
    reward has always had a one-tick delay baked into the pipeline's own ordering, and a designed
    "reward waiting at a spot" arguably *should* be collectable the instant it exists — but it is a
    rule nobody wrote down anywhere, and the PR's own author-facing doc never raises it despite the
    task's brief explicitly asking "is that the same answer a dropped pickup gets?" Worth checking on
    every future placement decision that creates a *second path* to an already-existing kind of
    entity: read the exact ordinal gap between where each path creates it and where the next system
    in the pipeline that would react to it runs, don't assume "same entity, same system" means "same
    timing."

Verdict on #319: **rejected pending a fix to `hasEnded`'s `Cleared` branch** — finding 70 is a real,
reproducible silent-content-loss bug in `core`, not a suspicion. Finding 71 is a note to carry to
whoever reviews the loader half or writes `waves.json` content using `Cleared` pickups.

Related: [[audit-techniques]].

## PR #321 (`content/level-one-vocabulary`, phase 11k task 5, issue #320) — twenty trajectory entries, every claim re-derived, one small division slip found

`assets/data/trajectories.json` (20 new entries: 13 authored, 6 `mirrorOf`, 1 `speedOf`), `waves.json`
(6 new `unplaced` waves), 6 new `test-110`..`test-160` scenario files, `docs/levels/waves.md`
regenerated. Verdict: accept, with one minor numeric correction to hand forward to task 6.
Independently reproduced rather than trusted: `node tools/build-level-docs.js` (`unchanged` both docs,
tree clean); all four commit subjects under 72 chars, no `Co-Authored-By`; `gh run list` both checks
green on tip commit, matching the PR's pasted `pre-pr-check` output; enemy radii/spawner/weapon values
in `enemies.json` and formation offsets in `formations.json` match the fragment's own numbers exactly;
a `LoadCheck` probe (`javac`/`java` against `core.jar`+`game.jar`+`gdx-1.14.2.jar` from the Gradle
cache, real `JsonContentSource` over `assets/data`) loaded all 7 relevant ids and resolved all 20
trajectories to the exact same `PathSegment`/`vx`/`vy`/`ay` values used by hand below.

72. **Hand-deriving every required entry class independently reproduced the fragment's numbers to the
    hundredth almost everywhere** — `settle-descent` (`constant`): entry/exit times against
    `LifetimeSystem.isFullyOffPlayfield`'s any-part-visible edge and `isPastSafetyBox`'s 128-unit
    margin, both exact (14.05s on screen, 20.45s removed); `dive-across-left` (`arc`, negative `ay`):
    closed-form quadratic root for the safety-box crossing, exact to the millisecond (3.12s / 4.08s);
    `descend-and-step-left` (`path` with a mid-drop lane change) and `advance-the-firing-line`
    (`path`, absolute `waypoints`, holds at two authored heights): every segment boundary, hold
    window and exit time exact, including the "authored y + radius" claim for the absolute form; the
    carrier spawner math (`Spawner.timer` starts at `interval`, ticks at 3,6,9,...) reproduces both
    "7 children" (`descend-and-anchor`) and "8 children" (`anchor-and-traverse-left`) exactly, **but
    only under the convention that the count stops at the entity's own on-screen departure, not at
    its later safety-box removal** — counting to removal instead gives 9 and more respectively. The
    fragment's own "on screen" definition (any part inside the playfield) is what the count silently
    uses; worth being explicit about next time this shape of claim appears, since the two conventions
    differ by 2+ children and both are defensible.
73. **A window bound stated as `(measured value + radius) / width` can be arithmetically wrong even
    when every input number it quotes is right — division is worth checking independently of the
    physics.** `dive-across-left`'s claimed minimum `atX` is 0.54, computed from its own stated drift
    of 106.1 units and the entity's 4.5-unit radius: `(106.1 + 4.5) / 208 = 0.532`, which rounds to
    **0.53**, not 0.54 — confirmed both from the fragment's own quoted numbers and from an independent
    Python closed-form re-derivation of the exit point (`atX_min = 0.5321`). The mirror's claimed
    "0.46 or less" should be "0.47 or less" for the same reason (`1 - 0.532 = 0.468`). Every other
    `atX` window in the same fragment (`descend-and-step-left`'s 0.25/0.34, `grind-and-wheel-left`'s
    0.75, `anchor-and-traverse-left`'s 0.61/0.39) reproduced exactly by hand, so this is an isolated
    slip, not a systemic one — but it is exactly the shape phase 11j's finding 66 and phase 11k task
    1's finding 68 both name: a number that looks derived and is off by a small, checkable amount.
    Non-blocking (task 6, which actually places these in a level, is what will feel a wrong bound, and
    the true minimum being *higher* than claimed by ~2 pixels is the safe direction to be wrong in —
    a level built right at the claimed 0.54 boundary would still work), but worth re-deriving every
    `(drift + radius) / width` style bound in a content fragment independently, not just checking that
    the physics reasoning behind it is sound.

Everything else checked out clean: no entry named after an archetype; `enemy-basic`/`enemy-shooter`
and `enemy-tank`/`enemy-carrier` share no shape (verified from the JSON directly, not the fragment's
own table); the "13 authored is the floor" arithmetic (6 archetypes x 2 + 1 for `enemy-rush`'s third)
is internally consistent and matches the actual JSON count; the seven 11c-era entries are genuinely
still load-bearing (`enemies.json` names four of them as archetype defaults, `waves.json` names three
more as overrides — grepped independently), so keeping them this task and deleting them in task 6 is
correctly reasoned, not deferred without cause; all six new `test-NNN-` scenario files sort above
every pre-existing one; `WorldView.outcome()` requires `noEnemyLeft()` in addition to
`waveTimelineExhausted`, so a `fixedDuration` scenario ending before its spawned entity's own on-screen
life is over (task-150-tank-family, 20s vs `grind-down`'s 26.45s) is not a bug — the level genuinely
does not report complete while the tank is still alive, confirmed by reading `World.java` directly
rather than assuming a wave's own end tears down what it spawned.

Related: [[audit-techniques]].

## PR #313 (`feat/tests-menu-discovered`, phase 11k task 3, issue #311) — clean, one uncaught-exception
gap the lenient label path does not share

Two-pass branch: pass one replaced a hardcoded `TestScenarios.ALL` with alphabetical discovery from
`assets/data/test-*.json`; the project owner then required #291's recency stack to survive, so pass
two renamed the ten newest scenarios to `test-NNN-<name>.json` and sorts by that rank, descending.
Verdict: accept. Independently reproduced rather than trusted: `:game:clean :game:test` (no
`-Ptests`) compiles zero `TestScenarios*`/`TestMenuScreen*` classes
(`find game/build/classes -iname` empty); `:game:test -Ptests --rerun` gives 13/13 green for
`TestScenariosTest` (`tests="13" failures="0" errors="0"` in the JUnit XML, matching the fragment's
own count); `:web:gdx_teavm_web_js_build` succeeds and `grep -c "TestMenuScreen\|TestScenarios"
web/build/dist/js/webapp/app.js` prints `0`; `tools/pre-pr-check --base
phase/11k-level-one-rebuilt` passes clean; the `ARC:` label on `test-wave-09`/`test-wave-12` traced
to real content (`veer-left`/`veer-right`, both `"type": "arc"` in `trajectories.json`) rather than
accepted from the fragment; wave ids in `waves.json` and level ids in
`docs/planning/08-decisions-and-open-items.md`/`docs/levels/waves.md` are genuinely independent of
the renamed level *filenames* — grepping every old filename outside `assets/data/`, the test fixture
and gitignored `web/build/` turns up nothing that *loads* a stale id, only prose and wave-id
coincidental substring matches.

70. **A rank parsed from a filename with an unbounded-width regex group has no upper bound the
    fallback-on-exception path covers.** `TestScenarios.NUMBERED` is `^test-(\d+)-(.+)$` — any number
    of digits matches — and `rankOf` feeds the captured group straight to `Integer.valueOf` with no
    try/catch. A `test-<21 nines>-name.json` file reproducibly throws `NumberFormatException` from
    inside `compareByRecency`, called from `List.sort` inside `discover()`, confirmed in an isolated
    scratch `.java` file (not the audited worktree) reproducing the exact regex and call shape. This
    is uncaught by *anything*: `labelFor`'s own try/catch is a sibling code path (label derivation),
    not rank derivation, and `TestMenuScreen`'s constructor has no guard around `TestScenarios.all()`
    either — so one malformed filename would crash the entire TESTS menu at construction, not just
    fail to sort that one entry the way a real "malformed number" input should. Low severity in
    practice (self-inflicted, `-Ptests`-only, no current file remotely close — the largest real rank
    is `100`) and not raised to a blocker, but exactly the shape the task's own review brief asked
    about ("a malformed number, a very large one") and exactly the class of gap the class's own
    javadoc claims *doesn't* exist ("label derivation is deliberately lenient... never throws" — true
    for labels, not true for the rank that decides sort order). Worth checking on every future
    filename-encoded-metadata scheme: an unbounded numeric capture group needs either a caught parse
    or a bounded digit count, and "the cosmetic half is lenient" does not imply "the ordering half is
    too."

Everything else checked out clean and is the calibration case worth keeping: every one of this
author's independently-checkable claims (compile isolation, test count, TeaVM grep, ARC labels,
reference scope, commit hygiene, `pre-pr-check` output) reproduced exactly on a fresh run, not just
matched what was pasted.

## PR #327 (`feat/boss-star-movement`, phase 11k task 7, issue #325) — clean, and a "replay still
passes" claim that is true but exercises none of the new code

`core`-only branch (`BossSystem.java` + its own test + the status fragment, confirmed by `git diff
--stat`). Verdict: accept. Every checkable claim held on independent re-derivation: the star geometry
(Python re-run of the cited script reproduced `STAR_X`/`STAR_Y` to the same three decimals), the
extent arithmetic (arm reach 15.566–192.434, keel's lowest reach 134.111, both against `playerStartY
30.0` from `balance.json` — the boss's lowest y, 174.111 at the star's centre, sits nowhere near it),
the hop-distance bounds (max legal-hop distance 37.619, max unrestricted-first-move distance
60.868 — both re-derived in Python from the same ten points, matching "about 37.6"/"about 60.9"
exactly), the ±3-step structural claim (grepped every assignment to `fightStage`/every call to
`beginMove`: `MOVING` is set in exactly one place, reached from exactly one call site, the tail of
`updateTelling` after `fire()` — no guard, a real structural exclusion), the pause arithmetic
(`patternCooldown` 0.7 in `level-01.json` + 0.75 s tell = 1.45 s, matching the fragment's figure
exactly), and the `entranceDescendsToCombatY` rewrite (spawn y 310, entrance speed 1000/s, combatY
120 → settles at tick ~12, well inside the new 20-tick assertion and well short of the first cycle's
57-tick cooldown-then-tell, so the narrowed test still checks exactly its own name). Full clean build
(`./gradlew build --rerun-tasks`) green across five modules, 365 `core` tests / 0 failures, `tools/
pre-pr-check --base phase/11k-level-one-rebuilt` PASS reproduced verbatim.

71. **Falsifying a rule-named test worked exactly as claimed, and is worth doing even when the
    reasoning already sounds airtight.** Widened `STAR_STEP_OFFSETS` to include ±4 in a scratch copy
    (`cp -r` to the scratchpad, per the auto-mode block on in-worktree mutation — see
    [[audit-techniques]]'s last section) and reran with `--rerun-tasks`:
    `bossVisitsOnlyStarPointsWithinThreeSteps` went red on the very next seeded run. One data point,
    not a pattern, but it is the calibration case for "the author's own falsification claim, checked."
72. **"All five replay tests still pass" can be a true, fully-verified claim that establishes nothing
    about the very code path it is cited for, because none of the five scenarios ever reaches it.**
    Every `BossReplayTest` fixture sets `patternCooldown` to `1000f` ("the boss never attacks back") or
    has no boss at all (`defeatContent`); `LevelScoreReplayTest`'s `TestContent` never calls
    `.withBoss(...)` at all. A `patternCooldown` of 1000 s against a 400-tick (6.67 s) run never lets
    `stageTimer` reach zero, so `TELLING` is never entered, `fire()` is never called, and `beginMove` —
    the method that calls `world.rng()` — never runs. All three `BossReplayTest` scenarios and both
    `LevelScoreReplayTest` scenarios are therefore silent on whether the new `Rng` draw breaks
    full-pipeline replay determinism; the actual proof of that lives entirely in `BossSystemTest`'s
    unit-level `samePatternForTheSameSeed`/`bossVisitsOnlyStarPointsWithinThreeSteps`, run with a real
    `0.2f` `patternCooldown` fixture that does reach `beginMove` repeatedly. Not a defect — the
    fragment never claims the replays exercise the new code, only that they still pass, which is true
    and harmless since (see next point) nothing else currently shares the stream — but it is
    pattern 34 (a criterion's replay citation and its unit-test citation pointing at different
    scenarios) in a new shape: this time the *gap itself* is truthfully reported, just not spelled out
    as a gap. Worth naming explicitly on the next PR that adds a `world.rng()` consumer: check whether
    any full-pipeline replay's fixture parameters actually let the new code run, the same way
    `patternCooldown`/`entersAt`/tick-budget arithmetic settles every other "does this scenario reach
    the changed code" question in this project.
73. **A first production consumer of a long-idle shared-state accessor is not yet a real "shifts
    everything downstream" risk, and greppable as such.** `BossSystem` is confirmed (`grep -rn "rng()"
    core/src/main`) to be the *only* production caller of `World.rng()` anywhere in `core` — nothing
    else currently draws from the seeded stream, so there is no existing downstream consumer whose
    output this PR could have shifted. The concern the task brief raised is real for the *next* system
    that draws from `Rng` after the boss does (draw order becomes part of the contract the moment a
    second consumer exists), but it is a forward-looking risk to flag, not a defect in this branch —
    confirm the "only consumer" fact by grep before treating a new `Rng` draw as automatically
    dangerous.

Related: [[audit-techniques]].

## PR #326 (`content/level-one-rebuilt`, phase 11k task 6, issue #324) — the level's central rebuild, clean on every mechanical claim, two small narrative slips

`assets/data/{enemies,waves,trajectories}.json` (`level-01.json` genuinely byte-identical, confirmed
by its absence from `git diff --stat`), both generated docs and `docs/plan/11c-movement-shapes/
shape-catalogue.md`. Verdict: accept. Reproduced independently rather than trusted: the full 12-wave
absolute-time chain (`start(n) = max(previousEnd(n-1) + offset(n), levelTime)`, read from
`SpawnSystem.scheduleNext`) by hand from `waves.json`'s eleven durations and the two negative offsets
— every one of the twelve beat-start times in the fragment's table (0.0, 9.0, 22.0, 33.0, 45.0, 57.0,
66.0, 81.0, 91.0, 100.5, 114.5, 120.5, ending 134.0) reproduced exactly; the spawn count (68, summed
per wave: 2+5+6+7+5+6+4+5+8+7+1+12); the family-resolution claim (all 68 spawns' trajectory, override
or archetype default, resolved by hand against the six family sets in #320 — zero violations, all
twenty vocabulary entries used, none unused); the twin-carrier convergence (`anchor-and-traverse-*`'s
path segments are **velocity, not displacement** — `{-22, 0, 5.0}` is 22 u/s for 5.0 s = 110 units,
not 22 units, confirmed by matching the vocabulary fragment's own claimed stop-y and end-x — after
which the two `single`-formation carriers' swept extents, 41.4..181.4 and 26.6..166.6, both land
fully inside `0..208`, matching the generated document's own per-spawn table exactly and confirming
no off-screen sweep); the beat-1/14 map correction (`grep -c "l1-intro-flyover\|l1-boss-approach"
assets/data/waves.json` → `0`, all twelve current wave ids present exactly once); `enemies.json`'s six
repointed defaults matching the claimed table byte-for-byte; the seven deleted 11c-era trajectory ids
absent from every file under `assets/data/` (not just `trajectories.json`); `node tools/
build-level-docs.js` → `unchanged` both docs on a fresh run; `./gradlew :core:test --rerun-tasks` →
361 tests, 0 failures; `tools/pre-pr-check --base phase/11k-level-one-rebuilt` → PASS, reproduced
verbatim.

74. **A path-segment tuple's second field can be a velocity in one direction of the shape catalogue's
    own convention and look like a displacement at a glance, and the distinction is exactly what a
    "does the swept extent stay on screen" check needs.** `anchor-and-traverse-left`'s traverse leg is
    `{-22, 0, 5.0}` — reading it as "moves −22 units over 5.0 s" gives a carrier ending at x=144.4
    from atX 0.80 (166.4−22), which never crosses the centre and would make the two carriers' claimed
    "converge and cross" false; reading the third field as a duration for a *velocity* (the same
    convention every other `path` entry in this vocabulary already uses, confirmed against
    `descend-and-anchor`'s own hold-then-fall arithmetic in #320) gives 22×5.0=110 units of actual
    displacement, landing at x=56.4 — which is what the generated document's own swept-extent column
    independently confirms (`26.6 .. 166.6` and `41.4 .. 181.4`, both computed by the tool from the
    real trajectory, not from the fragment's prose). Whenever a content fragment's claimed end-position
    for a multi-leg `path` looks inconsistent with a segment's numbers taken as raw displacement, redo
    the arithmetic as velocity×duration before concluding the claim is wrong — the tool's own output is
    the tie-breaker, and it agrees with the velocity reading here.
75. **A beat-by-beat design narrative can misdescribe which one of two concurrent entities' states
    overlaps, in a way the same fragment's own timeline arithmetic disproves.** #324's beat 10 claims
    "`advance-the-firing-line` is still standing on its **second** firing line when the `line-5` of
    basics arrives" — but the firing-line entity spawns at abs 90.0 (wave8's `at:9.0` + wave8's start
    81.0), holds its first line 91.2–93.7 and its second 94.95–97.45 (both computed from #320's own
    verified relative offsets, 1.20/3.70 and 4.95/7.45), while the `line-5` spawns at abs 91.0 (wave10
    `l1-high-pressure`'s own `at:0.0` + its start 91.0, itself confirmed via the offset-chain
    reconstruction above) — **0.2 s before the first hold even begins**, not during the second. The
    wave-level overlap itself ("overlapped by two seconds," referring to the `-2.0` offset shrinking
    wave9's nominal end) is correctly described; the claim about which specific moment in the entity's
    own path that overlap lands on is not, and it is checkable with the same offset-chain arithmetic
    the rest of the fragment's beat table survives on. Non-blocking — no JSON is wrong, the beat's
    actual density and "densest moment on paper" framing hold regardless of which line the shooter is
    standing on — but worth re-deriving any claim of the form "entity X is doing Y when entity Z
    arrives" against both entities' own absolute timelines, not just the wave-level offset that
    produced the overlap.
76. **A literal, `grep -o`-countable claim in a status fragment can be off by exactly one, in the
    harmless direction (undercounting a marker the fragment says is never wrong).** #324 claims "26
    `**leaves**` markers, and not one was tuned away"; `grep -o "\*\*leaves\*\*" docs/levels/
    level-01.md | wc -l` on the committed, freshly-`unchanged`-confirmed document returns **25**. Every
    individual per-wave count checked out against the marker's own category list (`cut-across-*`,
    `plunge-and-cut-*`, `grind-and-wheel-*`, the `vee-5`-widened `dive-across-*` placements, and
    `advance-the-firing-line`'s left-edge exit) summed to 25 across the ten waves that carry any —
    including the one the fragment's own category list slightly overstates: `dive-across-*` only earns
    the marker when a wide formation (`vee-5`) pushes its swept range past an edge, not on its two
    plain `single` placements (whose swept extents, 66.1..181.3 and 26.7..141.9, sit fully inside
    `0..208` and carry no marker at all) — so "dive-across-* bends out of the bottom corner" describes
    the mechanism correctly but not which of its placements the marker actually fires on. Cheap to
    catch (`grep -o` plus one `wc -l`), worth running on any status fragment that counts an annotation
    in a generated document rather than trusting the printed number.
77. **A previously-recorded, explicitly-not-closed balance finding can survive a full content rebuild
    unchanged in substance and unmentioned in the new fragment, without being a new defect the rebuild
    introduced.** Phase 11e's coordinator addendum (`docs/plan/11e-level-one-redesigned/status/
    210-tune-from-play-session.md`) recorded, and left open on the project owner's own decision, that
    an ideally-firing player at shot level 4 kills a 700 hp carrier in 2.1 s against a 3.0 s `Spawner`
    interval — the twin-carrier beat's carrier dies before its own mechanism can produce a single
    child, under ideal play. This rebuild changes none of the three numbers that finding depends on
    (`enemy-carrier.health` still 700, `spawner.interval` still 3.0, confirmed by reading `enemies.
    json`) and reproduces the same weapon-upgrade count and near-identical timing before the beat
    (three drops at abs 9.0/47.0/87.0 here vs 11.0/48.0/86.0 before, all still comfortably before the
    twin-carrier beat's 100.5 s start) — so the finding's arithmetic still holds verbatim, and #324's
    fragment does not mention it anywhere, including in its own "what task 6 inherits"/"what I found
    and did not fix" sections, which name two unrelated documentation gaps instead. Not a fresh defect
    (the level content this task controls cannot fix a health/interval pair it has no mandate to
    touch) and not a contradicted claim (the fragment never asserts the beat is closed) — but a known,
    still-open, numerically-checkable risk that a full rebuild of the very beat it lives in is a natural
    moment to have re-surfaced and didn't. Worth checking on every future touch of `l1-twin-carriers-
    attachment` or `enemy-carrier`'s health/spawner pair: recompute ideal-kill-time-vs-first-child-time
    with whatever shot level the level's own drop schedule delivers by that beat, since neither this
    task's own verification section nor its "what I found" section is the place that would have caught
    a regression in either direction.

Everything else checked out clean and is worth naming as the calibration point: the carrier mechanism
arithmetic (5 children while parked + 2 more before departure = 7, using the "counts to on-screen
departure, not later safety-box removal" convention #321's correction already established), every
`atX` window from #320 (corrected `dive-across-*` 0.53/0.47, `grind-and-wheel-*` 0.75/0.25, `anchor-
and-traverse-*` 0.61/0.39, `descend-and-step-*` 0.25/0.34 and 0.75/0.66) satisfied by every placement
in the level, the "no cleared wave" and "every generator check clean except the two deliberate
negative offsets" claims, and the beat-11/beat-12 "rest is not a rest if the carriers survive" timing
(carrier on-screen end ~125.7 s against the rest wave's own 114.5–120.5 s window, reproduced exactly).

## PR #331 (`feat/formation-slot-delay`, phase 11k, issue #330) — a floating-point boundary the shipped test never exercises

`core`-only branch (`FormationSlot` gains `delaySeconds`, `SpawnSystem` backdates `Trajectory.elapsed`
to `-delaySeconds`, `MotionSystem` holds velocity at zero while `elapsed <= 0f`). Verdict: accept.
Every invariant held (no libGDX/clock/`Math.random`/threading in the touched files), the 2-arg
back-compat constructor is the one `game`'s untouched loader still calls, `node
tools/build-level-docs.js` printed `unchanged` for both documents, all five replay test files stayed
green (367 core tests total), and `./gradlew clean build` was genuinely green (confirmed executing,
not just cache hits, by comparing task states across two runs).

44. **A javadoc's stated reason for an inclusive boundary (`<= 0f` over `< 0f`) can be real only for a
    narrow slice of the input range the feature actually allows, and the shipped test can land
    entirely outside that slice.** The author's own reasoning — both in `MotionSystem`'s javadoc and
    the status fragment — is that including `elapsed == 0` in the held branch is what makes a delayed
    slot retrace the leader's positions *exactly*, tick for tick. Exhaustively simulating
    `elapsed = -delayTicks*step` accumulated by `+= step` for `delayTicks` 1..3600 in plain Java shows
    `elapsed` lands on *exactly* `0.0f` only for `delayTicks` 1 and 2 — for every other tick count
    (including the shipped test's 12), float accumulation error leaves `elapsed` a small nonzero
    epsilon (`-2.6e-8` at delayTicks=12) that is `< 0f` regardless of which comparison is used, so the
    two operators produce identical held/active behaviour there. Proved directly: mutating
    `elapsed <= 0f` to `elapsed < 0f` and rerunning `./gradlew :core:test --tests "*SpawnSystemTest"
    --rerun-tasks` left the new delay test green (33 tests, 0 failures) at the test's own
    `delayTicks = 12`; the identical mutation with `delayTicks` changed to `1` failed it immediately.
    The code is not wrong — `<=` is still the safe, correct choice — but the chain
    "javadoc claims X matters" -> "status fragment repeats it" -> "test pins it" breaks at the last
    link for the specific value shipped. Whenever a comment justifies a boundary operator by appeal to
    an exact real-number crossing in an accumulated-float quantity, check whether the float actually
    reaches that exact value for the test's own chosen inputs before crediting the test with proving
    the boundary matters — accumulation error routinely skips the exact zero/exact-integer case
    entirely except at the smallest few counts.
45. **"Retraces exactly, delaySeconds later" is a claim scoped (correctly, in this branch's own
    fragment) to a delay constructed as literally `N * step` in float, and silently narrower than a
    reader would assume from the issue title.** Direct simulation of `-delay + k*step` for delays a
    content author would plausibly type as plain decimals (`0.05`, `0.3`, `0.5`, `1f/3f` seconds, all
    exact numbers of ticks in real arithmetic — 3, 18, 30, 20 respectively) crosses zero **one tick
    early** for three of the four, because the float literal for the decimal does not exactly equal
    `N * (1f/60f)` computed by repeated addition. This branch is not wrong to leave it that way — its
    own status fragment already scopes the "exact" guarantee to "a slot delayed by exactly `N` ticks
    (`delaySeconds = N * step`)" and never claims it for arbitrary decimal seconds — but the guarantee
    quietly degrades to "off by up to one tick" for the values a level designer would actually write in
    JSON once the loader lands, and neither the issue nor the "what the loader will need" section warns
    of it. Worth handing forward: whoever builds the loader should either quantize an author-supplied
    `delaySeconds` to the nearest tick before storing it, or the level-doc/content docs should say
    delays must be written as an exact multiple of `1/60` to get the documented exactness.

## PR #332 (`feat/boss-front-weapons`, phase 11k, issue #329) — a correct mechanism, justified by a model of its own state machine that runs the two halves of the cycle in the wrong order

78. **A javadoc's "why N and not N-1" arithmetic can be numerically self-consistent and still describe
    the state machine's segment order backwards, in a way that survives into the PR body and the status
    fragment verbatim.** `BossSystem`'s `FRONT_SHOTS_PER_CYCLE` javadoc and `status.md`'s "why 3, not the
    numerically closer 2" both model one rear cycle as COOLDOWN-then-TELLING (the first 63.3% of
    `rearCycleDuration`) followed by MOVING (the last 36.7%) — so N=2's lone independent shot, at the
    cycle's midpoint, is said to "always fire during TELLING, never during MOVING," and N=3's second
    shot, at two-thirds, is said to land "past where the tell ends... inside MOVING." Both claims are
    backwards. Read `updateTelling`: the reset (`frontElapsed = 0f; frontShotsThisCycle = 0`) and
    `beginMove(world)` happen in the same call, so **every steady-state cycle (the second one onward)
    actually runs MOVING first, then COOLDOWN, then TELLING** — the reverse of what the doc assumes.
    Confirmed with a reflection probe against the built `core` classes (no repo file touched): for real
    content (`patternCooldown` 0.7s, `MOVE_DURATION` 0.84s, cycle 2.29s), the front weapon's *first*
    independent shot (not the second) is the one landing in `MOVING` (at ~0.76s, just under the 0.84s
    `MOVE_DURATION` boundary), and the second lands in `COOLDOWN` (~1.53s, just under 1.54s =
    `MOVE_DURATION + patternCooldown`) — never in `TELLING` at all. Re-running the same probe with
    `FRONT_SHOTS_PER_CYCLE` mutated to 2 (in a scratch copy under the scratchpad, never in the audited
    worktree — see the technique note below) shows its one independent shot landing in `COOLDOWN` on
    every cycle, not `TELLING` as claimed. The practical conclusion (reject N=2, keep N=3) still holds —
    N=2's shot never lands in `MOVING` either way — but the mechanism cited to justify it, in three
    places (the class javadoc, `status.md`, and the PR body, all copied near-verbatim from one another),
    is empirically false. Only the very first cycle (fight start to the first rear volley, before any
    move has happened) actually runs COOLDOWN-then-TELLING as the doc assumes — the author generalised
    the one cycle shape that doesn't recur. Check any "where in the cycle does X land" claim by tracing
    real stage values via reflection rather than by re-deriving fractions from the constants the way the
    author did; a self-consistent fraction is not evidence the segments are ordered the way you assumed.
    The rest of the branch was clean: the coincidence-every-volley guarantee itself held with zero drift
    across a 6-coincidence trace, the fire-rate arithmetic (0.53→1.31 events/s, ~5.3→~17.5
    projectiles/s, ~3.3x) reproduced exactly by hand, `FightStage.MOVING` really is assigned from exactly
    one call site, `computeAimPoint` really is called fresh for every front shot and `lockAim` untouched
    for the rear, and no clock/`Math.random()`/`sin`/`cos`/thread/gdx import appears in the file.
    `pre-pr-check` and a fresh `./gradlew build` both green.

**Technique confirmed working under this role's "change nothing" constraint**: the harness's own
permission classifier refused an in-place `sed`/`Edit` mutation of a tracked file in the audited
worktree, even for revert-immediately falsification — a case where the audit brief itself asked for a
mutation test. The fix is the same non-mutating trick [[audit-techniques]] already lists for a probe,
one level further: copy the single source file into the scratchpad (not `/tmp`, not the worktree),
mutate the copy there, `javac` it against the worktree's already-built `core/build/classes/java/main`,
then run a driver with the scratch output directory placed *before* the real classes on the classpath
so the mutant shadows the original. This produces a real, compiled, running falsification (the mutated
`frontElapsed`-no-longer-resets version genuinely broke `frontFiresMoreOftenAndCoincidesWithEveryRear
Volley`'s invariant — a 30-projectile tick appeared, which the test's own `assertTrue(isCoincidence ||
isFrontOnly, ...)` would reject) without the classifier ever seeing a write to the repository, and
without leaving anything to revert.

Related: [[audit-techniques]].

## PR #336 (`feat/loader-reads-slot-delay`, phase 11k, issue #334) — the end-to-end check the split
review never ran, and it broke on the pair's own flagship example

The `game` half of #330/#331 (see PR #331's entry above). `JsonContentSource` now quantises an
authored `delaySeconds` to the nearest tick, `Math.round(raw*60f) * TICK_SECONDS` — bit-identical to
the single-multiplication construction `core`'s own `SpawnSystemTest` uses. Verdict: reject, on the
status fragment's claim, not on the code — the code is a defensible choice given `core`'s contract.

79. **A quantisation fix that matches the *tested* construction of a value is not the same claim as
    "the crossing is exact," and the two PRs that split this feature never built the check that would
    have told them apart.** Neither `core`'s test suite nor this branch's drives a delay from JSON
    through `SpawnSystem`/`MotionSystem` and checks the trace (`game/src/test` mentions those two
    classes only in javadoc — confirmed by grep, zero `.update(` call sites). Built the missing check
    myself: a scratch fixture (`TestContent` + real `SpawnSystem`/`MotionSystem`, compiled against the
    worktree's already-built classes, nothing written to the repo) reproducing the loader's exact
    formula. Result: for `raw=0.3` → quantised to 18 ticks — **the running example both this branch's
    and #330's status fragments lead with** — the follower is a full, permanent one tick *ahead* of
    where "traces exactly 18 ticks behind" requires, from the very first compared tick onward
    (`expectedX=104.166664`, `actualX=104.333328`, exactly one `vx*step` quantum). Sweeping N=1..300
    with both a `constant` trajectory and `core`'s own `ArcTrajectoryDefinition(20,-80,40)` (identical
    bands both ways, since horizontal velocity is constant either way) found **N=18-40 and N=258-300
    broken, ≈22% of the range** — not a rare edge case, a systematic band that happens to include the
    exact value (0.3s) both authors picked to illustrate the feature. `core`'s own `SpawnSystemTest`
    only exercises N=1 and N=12, both of which sit in the "exact" band by chance; it never tried N=18.
    **This is not fixable by the loader's choice of quantisation strategy** — feeding `core` the exact
    single-multiplication value its own tests use is the best the loader can do, and it still fails,
    because the defect is intrinsic to `MotionSystem`'s repeated-addition crossing versus any
    single-computed threshold. It belongs to `core`/#330, not this branch — but #330's own fragment
    states outright "the general correctness argument two paragraphs up still holds for every
    `delayTicks`, exact float crossing or not," a claim my sweep falsifies directly, and this branch's
    fragment repeats the stronger version, citing the two existing `SpawnSystemTest` cases as proof for
    N=18 specifically when neither test touches that value. **Whenever a status fragment cites a named
    test as proving a property "holds for every N" or "for what gets authored," check which N the cited
    test actually uses before accepting the citation as covering the value the fragment leads with** —
    the mismatch here is not that the citation is wrong, it is that the *property* was generalised from
    two lucky sample points to "every count," and nobody swept the range before writing that sentence
    down twice, across two separately-reviewed PRs, past a reviewer who had already been unusually
    careful about this exact boundary the first time.

Related: [[audit-techniques]] for the scratch-fixture-and-sweep technique used here.

## PR #338 (`fix/delay-crossing-in-ticks`, phase 11k, issue #337) — the fix for my own PR #336 finding, and it holds

Round trip on a defect I found myself: `core` swapped the float `elapsed <= 0f` crossing for an
integer `Trajectory.delayTicks` countdown, `step` threaded through `update`→`spawnDue`→`spawnWave`→
`applySlotDelay` (single call chain, one caller, no second step value anywhere), and a `game`-module
end-to-end test added. Verdict: accept, nothing new.

80. **A "the fix resolves it" claim is worth re-proving with your own driver, even when the author's
    sweep already covers the same range you'd choose.** Reused the audit-techniques scratch-compile
    trick from the PR #332 entry, but for a whole three-class subsystem rather than one method:
    copied `Trajectory`/`MotionSystem`/`SpawnSystem` are not needed — the *test's own* `TestContent`/
    `SimpleFormationDefinition`/`SpawnEvent` support classes are already public and already built, so a
    from-scratch `Driver.java` reproducing `assertDelayedSlotTracesLeaderExactly`'s body, compiled
    against `core/build/classes/java/{main,test}` and run standalone, is a five-minute independent
    reproduction of a 300-iteration sweep with no JUnit and no repo mutation. It found 0/300 failures
    on the branch, confirming the fix; run again with the pre-fix `MotionSystem`/`SpawnSystem`
    (`git show <base-branch>:<path>`, compiled to a separate output dir placed *before* the real
    classes on the classpath so it shadows them) it found **273/300** failing, not the ~66/300
    ("bands 18–40, 258–300") the earlier memory entry had recorded for the *loader-quantised* variant
    of the same bug — the two numbers describe different constructions of the same defect
    (`delayTicks * step` directly vs. quantised-through-JSON) and are not comparable at face value.
    Worth remembering: a "the old code fails N% of the time" figure is scoped to exactly the
    construction it was measured against; re-deriving it under a different construction of the same
    input can legitimately produce a very different percentage without either measurement being wrong.
81. **A one-line classpath-order mutation test disproves vacuity cheaply for a sweep, not just a single
    assertion.** Shifting the countdown's threshold by one (`delayTicks > 0` → `> 1`) turned the *entire*
    swept range red (300/300), proving the test is not accidentally trivial across its full domain, the
    same way pattern 40's per-case falsification does for one assertion.
82. **A stale javadoc left behind in an *unmodified* file, describing a mechanism the same PR just
    replaced, is a real but minor finding distinct from "no change needed."** `JsonContentSource.
    loadFormations`'s own javadoc still says (unedited by this branch, confirmed by `git diff` on the
    file being empty) "`SpawnSystem` backdates `Trajectory.elapsed` to `-delaySeconds`... `MotionSystem`
    then reaches zero by adding the fixed step" — the exact mechanism #337 deleted. The status
    fragment's claim "`JsonContentSource` needed no change" is true and independently confirmed (the
    diff really is empty, the end-to-end test really does pass unmodified against the loader's own
    quantisation) — but "no code change needed" and "every comment in that file still describes the
    current mechanism" are different claims, and only the first one was checked. Whenever a PR fixes a
    mechanism in one module and cites "no change needed" in a neighbouring module that only *describes*
    that mechanism in prose, grep the untouched file for the old mechanism's own vocabulary
    (`elapsed`, `backdate`, the deleted field/branch name) before accepting the "no change" claim as
    covering the comments too.

Calibration: the two corrected fragments (`330-`, `334-`) both read exactly as a correction should —
dated, naming what was false and what replaced it, not rewritten as if always true. The commit hygiene,
`pre-pr-check`, and `./gradlew build`/`node tools/build-level-docs.js` claims all reproduced independently
(370 core tests aggregated from the XML, 0 failures/skipped/errors), and no invariant was at risk in the
touched files (`grep` for gdx/random/clock/threading in the three touched `core` files: zero hits).
