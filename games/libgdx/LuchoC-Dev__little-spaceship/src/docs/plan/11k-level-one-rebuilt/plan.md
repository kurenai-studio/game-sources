# Phase 11k — Level 1 rebuilt on a vocabulary written for it

**Branch:** `phase/11k-level-one-rebuilt`, from `dev` at `9edd44c`.
**Opened:** 05/09/2026.

This is what phases 11h, 11i and 11j were built to make possible. Each of them ended with level 1
deliberately untouched: 11h built a test mode so a wave can be looked at without playing to it, 11i
made a movement shape an ordered list of bounded segments with waits, repeats and mirroring, and 11j
let a path be written where it happens and run faster without changing size. **None of it is in
level 1.** The project owner noticed at the end of 11j and asked why, and the answer is this phase.

## Before you start

Read these, in this order. They are short and specific on purpose.

1. `CLAUDE.md` — all of it, and its invariants.
2. `docs/plan/how-to-run-a-phase.md`, including **"Running the game is not playing it"** and its
   subsection **"And the half that is the coordinator's"**.
3. `docs/levels/level-01.md` — the generated document for the level as it stands. It is the only
   accurate description of what this phase replaces.
4. `docs/plan/11j-absolute-paths/status/297-level-one-trajectories.md` — the seven trajectories 11j
   authored, what each is meant to look like, and **the constraints its author measured**: the `atX`
   an absolute path requires, the collider-radius offset in `y`, and the `atX` window a drifting
   relative path needs.
5. `docs/planning/04-campaign-and-levels.md` → "Level 1 design" — the beats.
6. `docs/plan/11e-level-one-redesigned/plan.md` — the last time level 1 was redesigned, and where
   **"the candidate is not the deliverable"** comes from.
7. Your own agent memory, in the directory `tools/agent-memory-path <your name>` prints.

## What the project owner decided, on 05/09/2026

Asked before any work began, and answered in one pass. **These are decisions, not suggestions, and
this phase does not reopen them.**

- **The whole level changes.** All twelve placements, not a selective pass over the beats a new
  shape happens to suit.
- **The beats may be modified, added or removed.** The fourteen-beat sequence in
  `04-campaign-and-levels.md` is the design intent, not a fixed script — its own text calls it
  provisional and says it will be adjusted through the intensity curve and playtesting.
- **"Simple movements" is a rule about archetypes, not about waves.** Each enemy type gets **two or
  three movements at most, and they resemble each other**; a mirror does not count as another one.
  `enemy-basic` gets simple downward falls and perhaps one complex shape. The point is that a player
  learns what an archetype does by seeing it, and an archetype that flies five unrelated shapes
  teaches nothing.
- **The trajectory vocabulary is written new, for this level.** The seven entries 11c authored, which
  level 1 uses today, **will change**. The twelve from 11i and 11j are **test material and are not
  placed in the level** — they exist to exercise the path system from the TESTS menu and that is all
  they were for.
- **Roughly 2.5 minutes is the right length** for the first level. The level ends at 134.5 s today
  and that is close enough to keep as the target; it is not a number to hit exactly.
- **The boss's difficulty, health and shots are approved and stay.** What the owner would like is
  **movement**, for dynamism — *"sin exagerar la dificultad del nivel"*. Not a harder fight.
- **The play session gates the phase**, as in 11e: agents build a candidate, the owner plays it, the
  phase tunes from what they report, and **the candidate is not the deliverable**.

## What this phase is not

- **It is not a rebalancing of the enemy archetypes.** Health, damage and fire rates in
  `assets/data/enemies.json` and `balance.json` were tuned by play in 11e and confirmed. A shape
  changes how an encounter reads without touching a number, and that is the lever this phase has.
- **It is not new `core` capability for movement.** 11i and 11j built the vocabulary and both proved
  it needs no new `core` API. If a shape this phase wants cannot be said, **say so and stop** — that
  is a finding, and inventing a fourth kind of trajectory is not this phase's call. Curves beyond
  `arc` were refused in 11j with a measured determinism constraint behind the refusal.
- **It is not a second level.** Levels 2 and 3 are phase 12.

## The tasks

Eight, in three groups. **The first group is tooling and must land before any content is
authored**, because it is what lets the content be checked at all.

### Group A — the checks the content will need

#### Task 1 — `tools/build-level-docs.js` understands a `path` trajectory

**The generator is blind to half the vocabulary, and this phase is what wakes it.** Verified on
05/09/2026: `grep -n "path\|segments\|waypoints\|mirrorOf\|speedOf" tools/build-level-docs.js`
returns only Node's own `path` module. `sweptExtent` (`:197`) reads `traj.vx`, `screenTime` (`:241`)
reads `traj.vy`, and the shapes table (`:618`) prints `vx`, `vy` and `ay` — none of which a `path`
entry has at the top level. That geometry runs only inside `buildLevel`, so only for
`level-01.json`, which today places no `path`; `waves.md` never touches geometry, which is why the
ten test scenarios pass through unnoticed.

The moment this phase places its first `path` in level 1, the swept-extent check, the
`cleared`-wave check and the shapes table are all wrong or silent.

**What it must do:** resolve a trajectory of every kind the content can express — `constant`, `arc`,
`path` in both its `segments` and `waypoints` forms, `mirrorOf` and `speedOf` — and produce, for a
`path`, the same two things the other kinds already give: **the horizontal extent it actually
sweeps** and **how long it is on screen**. The arithmetic is in
`game/adapter/content/JsonContentSource.java`, which already resolves all of it into
`PathSegment(vx, vy, duration)`; reproduce that resolution, do not invent a second definition of it.
The shapes table needs a row a `path` can fill — `vx`/`vy`/`ay` do not describe one.

**Acceptance criteria** — all of them readable from the code or a run, none needing the game:

- `node tools/build-level-docs.js` prints `unchanged` for both documents on content that has not
  changed. This is the whole mechanism and it must survive.
- A level file placing a `path` trajectory generates a document with a correct swept extent and a
  correct screen time for it, each derived from the resolved segments.
- `mirrorOf` and `speedOf` resolve, in either order, as `JsonContentSource` resolves them.
- An unknown or unresolvable trajectory kind **dies naming the file and the id**, as `resolve` and
  `die` already do — it does not print `undefined`.
- Demonstrated the way #177 was: a case that would have been silently wrong before, shown wrong on
  the old code and right on the new.

#### Task 2 — an absolutely-authored path is checked against the `atX` it was placed at

[#300](https://github.com/LuchoC-Dev/little-spaceship/issues/300). Raised by 11j's task 1, which
argued it and deliberately did not build it, and answered by its task 3, which hit it in practice.

`SpawnSystem.positionSpawned` puts the slot at `x = atX * 208` and an absolute path only ever adds
deltas to that, so the entry waypoint's coordinates are the **authoring** origin and not a position
the engine reads. `hold-the-line-and-exit` has an entry `x` of 104 and therefore requires
`atX 0.50`; anything else and every coordinate in it is a lie by the same constant. **Nothing checks
this today**, and it cost nothing in 11j only because the same task wrote the paths and placed them.
**This phase is exactly where one agent writes them and another places them.**

It belongs in `tools/build-level-docs.js`, which already reads waves and trajectories together and
already fails a pull request on a bad swept extent. It does **not** belong in `JsonContentSource`,
which parses the two files independently with no cross-reference anywhere in the class.

**Acceptance criteria:**

- A spawn whose trajectory is absolute and whose `atX * 208` is not the entry waypoint's `x` is
  reported as a finding, naming the wave, the spawn, the trajectory, the `atX` it has and the `atX`
  it needs.
- It appears in the document's **"What was checked"** list, so a designer can tell it is caught
  rather than still theirs to verify.
- The tolerance is stated and justified, not left implicit. `atX` is authored to two decimals and
  `atX * 208` will rarely be exact.
- The check fires on a deliberately mis-placed fixture and stays quiet on the two absolute
  trajectories as 11j placed them.

Tasks 1 and 2 are the same file and cannot run in parallel. **Task 1 first**, task 2 on top of it.

#### Task 3 — the TESTS list is discovered from `assets/data/test-*.json`

Measured across three phases and decided by the project owner on 05/09/2026: *"sí, es hora de
cubrirlos"*. `game/src/tests/.../TestScenarios.java` holds a hardcoded list that went from nine
entries to fourteen in 11j; a content task shipped five scenarios it could not list, needing
[#301](https://github.com/LuchoC-Dev/little-spaceship/issues/301) — a whole issue, branch and pull
request in a second module to finish work already done. **This phase adds scenarios again.** And no
test can cover the list as it stands, because `TestScenarios` lives only in the `-Ptests` source
set, which `game`'s test source set is not compiled against.

**The open design question, and this task must answer it rather than assume:** a label. #301 decided
that a label's prefix names the authoring form — `LINE:` for a `constant`, `PATH:` for relative
segments, `ABS:` for absolute waypoints — and that decision is worth keeping, because it is what the
project owner reads while choosing what to open. A filename cannot say it. Two ways out:

- **derive the label from the file**, which needs the level schema to accept a new optional key, and
  `JsonContentSource.requireOnlyKeys` (`:349`) accepts only `boss`, `events` and `waves` today;
- **derive it from the trajectory the scenario places**, which the loader already knows, so the
  prefix comes out right by construction and no schema changes.

The second looks cheaper and truer, and it is a recommendation and not an instruction. **Whichever
is chosen, say why in the status fragment.**

**Acceptance criteria:**

- Adding a scenario file under `assets/data/` and nothing else puts it in the TESTS menu.
- The stack order #291 decided survives: newest first. Say what "newest" is derived from now that a
  hand-ordered list is gone, and make it deterministic — **an ordering that depends on the
  filesystem's directory order is not deterministic** and would violate this project's own rule.
- The order the list comes out in **is read from the code or asserted by a test**, not by launching
  the game. What the menu looks like on screen is the project owner's.
- The `-Ptests` build still compiles, and the shipped build still contains none of it — proven the
  way 11h proved it, by the real TeaVM compile `:web:gdx_teavm_web_js_build` and a grep of the
  emitted `app.js`. `:web:build` reports `compileTeavmJava NO-SOURCE` and proves nothing.

#### Task 4 — content can place a pickup that no enemy carries

[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255). A pickup can only exist by an
enemy dying; there is no standalone placement. Every drop in level 1 hangs off an enemy today. The
owner put this in scope on 05/09/2026, so the redesign may use a placed pickup as a beat of its own
— a reward the player flies to rather than one that falls out of something they shot.

Related and **not** in this task: [#252](https://github.com/LuchoC-Dev/little-spaceship/issues/252),
pickups hanging in the air instead of falling. Read it before starting; if a standalone pickup makes
it worse or makes it trivial to fix, say so.

**Acceptance criteria:**

- A level file can place a pickup at a time and a position, in the same shape as a spawn.
- It is refused at load with a message naming file and id when the kind is not one of the six.
- The rule is asserted by a test named after it, not by a setter test.
- `docs/levels/level-01.md`'s generator reports it — a placed pickup nothing prints is a lever a
  designer cannot see.

### Group B — the level

#### Task 5 — the trajectory vocabulary level 1 is rebuilt from

**Written new, per the owner's decision.** Not the twelve from 11i and 11j, which are test material,
and not the seven from 11c, which change.

The rule that shapes it: **two or three movements per archetype, and they resemble each other**;
mirrors are free and do not count. `enemy-basic` gets simple downward falls and perhaps one complex
shape. Six archetypes exist (`enemy-basic`, `enemy-light`, `enemy-tank`, `enemy-rush`,
`enemy-carrier`, `enemy-shooter`), so the vocabulary is roughly twelve to eighteen entries and its
shape is **per archetype**, not per beat. Write down, for each archetype, what its movements are and
what makes them a family — that sentence is the deliverable as much as the JSON is.

Use every form the vocabulary has where it earns its place: `constant` for what is straight, `arc`
for what curves, `path` for what turns, waits or repeats, `waypoints` where a fixed position on
screen is the point, `mirrorOf` for symmetry and `speedOf` for the same shape sooner. **A path that
could be a `constant` should be one** — 11j's rule, and it is what keeps the file's `path` entries
meaningful.

**What happens to the old entries is part of this task**, and it must be decided rather than left:
the seven from 11c stop being used by level 1, and nothing else in the repository uses them except
the test waves. Deleting them and keeping them are both defensible. Say which and why.

**Every entry gets a written description of what it is meant to look like, with the numbers derived
by integrating the real JSON** — the instruction that has now produced a finding in two consecutive
phases, with the JSON right and the prose wrong each time. Apply the collider radius to the spawn
height, to every edge crossing **and** to `isPastSafetyBox`, which tests `transform.x + radius`.

**Acceptance criteria:**

- Every entry loads through the real loader, demonstrated the way 11j's task 3 demonstrated it.
- Each archetype's movements are two or three and are described as a family.
- Every absolute entry states the `atX` it requires, and task 2's check agrees.
- A test scenario per new capability, following 11i's rule that a mirror shares its original's.
- `node tools/build-level-docs.js` run and its output committed.
- **Whether they read right on screen: not checked, and the project owner's.**

#### Task 6 — level 1 rebuilt on it

All twelve placements, beats free to move, add or be removed, ~2.5 minutes, the curve deliberate.

The document the level generates is the argument: the pacing table, the curve, the checks. Write the
beat map by hand where it cannot be generated, and **update
`docs/plan/11c-movement-shapes/shape-catalogue.md`'s "What points at what"** — it is the single
hand-written link in a chain that is otherwise generated and CI-checked, it needed a dated
correction after 11e for exactly this reason, and [#208](https://github.com/LuchoC-Dev/little-spaceship/issues/208)
exists because nothing fails when it names a wave that no longer exists.

**Acceptance criteria:**

- Twelve placements or however many the beats need, every wave `fixedDuration` unless a `cleared`
  wave is argued for, and the level ends near 134.5 s with the boss entering after it.
- Every archetype flies only the movements task 5 gave it. This is checkable by reading the JSON and
  it is the phase's own rule.
- `node tools/build-level-docs.js` reports **Checks clean**, including task 1's and task 2's new
  ones, and its output is committed. **CI is checked with `gh run list`, not only the local build** —
  phase 11i sat red for four consecutive runs on exactly this.
- **Whether the level is any good: not checked, and the project owner's.** The generated document
  says so itself, in the one sentence it refuses to generate.

### Group C — the boss, and the session

#### Task 7 — the boss moves

The owner's words: the difficulty, the health and the shots are right; they would add **movement for
dynamism**, *"sin exagerar la dificultad del nivel"*.

This is `core/domain/system/BossSystem.java` and therefore `core-domain`'s, not content's. It is also
where [#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88) lives — *`BossSystem` is level
1's boss, not a boss engine* — and **this task does not fix that**. Adding movement is not a licence
to generalise a boss engine; invariant 6 refuses an abstraction without a case, and there is one
boss.

**Determinism is the constraint that decides the shape of this.** The boss already locks the player's
position at the instant a tell begins and fans five rays at that frozen point, by vector arithmetic
and `Math.sqrt`, so it holds under TeaVM. Movement must hold to the same standard: a function of the
boss's own elapsed time, no clock, no `Math.random()`, and nothing that needs `sin`/`cos` — 11j
refused curves for a measured determinism reason and that reason has not changed.

**Acceptance criteria:**

- The boss's position over time is a pure function of its elapsed time and the seeded `Rng`, asserted
  by a test that traces it rather than one that checks a setter.
- The existing boss tests still pass, and the five-ray fan still aims at the frozen player position —
  **a moving boss changes where those rays start from**, which is the thing most likely to break
  quietly. Say what happens to a fan fired mid-movement.
- The replays still reproduce. `./gradlew build` green.
- **Whether it reads as dynamic rather than harder: the project owner's.**

#### Task 8 — the play session, and the tuning that follows

Not an agent's task. The owner plays the candidate, and the phase tunes from what they report.

**This is the acceptance criterion the phase cannot close without**, and it is the one 11e was built
to establish: a balance verdict comes from a play session and from nothing else. Level 1 as it stands
was approved across sessions; replacing it means it has to be approved again. Nothing merges into
`dev` until it is.

## Sequencing

```
task 1 ──▶ task 2 ──────────────┐
                                 ├──▶ task 5 ──▶ task 6 ──▶ task 8
task 3 ─────────────────────────┤              (play, then tune)
task 4 ─────────────────────────┘
task 7 ─────────────────────────────────────────▶
```

Tasks 1 and 2 share a file and run in sequence. Tasks 3, 4 and 7 touch different modules and may run
beside them. **Tasks 5 and 6 wait for group A**, because being checkable is the point of group A.
Task 7 is independent of everything except the play session.

Two agents of the same kind never run at once without explicit per-file prohibitions in both
directions. **The coordinator creates every worktree and every branch; an agent never runs
`git worktree add`.**

## Which agent

| Task | Agent | Note |
|---|---|---|
| 1, 2 | `game-presentation` | **Scope exception.** `tools/` belongs to no module — the precedent is phase 01's build scaffolding — and its limit here is exactly `tools/build-level-docs.js`. No `game/` source, no content. |
| 3 | `game-presentation` | `game/src/tests/`, plus `JsonContentSource` only if the label decision needs it |
| 4 | `core-domain` | the contract and the system; the loader half may need a second branch |
| 5, 6 | `level-designer` | `assets/data/` only, plus the generated documents and the catalogue's beat map |
| 7 | `core-domain` | `BossSystem`; **not** #88 |

**Task 7 is judgement rather than execution** — what a boss's movement should be is a design call the
plan deliberately does not make, and it sits against a determinism constraint that has already
refused one thing in this project. `agent-prompts.md` asks the coordinator to say so rather than
decide alone: **the project owner chooses the model for it.**

## What this phase is most likely to get wrong

- **Authoring a vocabulary that is a list of tricks rather than a language.** The owner's rule exists
  against exactly this: two or three movements per archetype, resembling each other, so a player
  learns an enemy by watching it. Nineteen entries already exist and only seven are used; the failure
  mode here is a bigger file, not a better level.
- **Placing an absolute path at the wrong `atX`.** It fails silently and produces a shape that is
  merely in the wrong place, which is the hardest kind of content bug to see. Task 2 exists for it
  and must land first.
- **Trusting the generated document while the generator cannot read half the content.** Task 1.
- **Writing an acceptance criterion that cannot be met without playing.** 11j broke this twice and
  the second time the cause was the coordinator's wording. Every criterion above is split: what the
  code says is an agent's; what the screen shows is the owner's.
- **Regenerating the documents and forgetting to commit the output.** `tools/pre-pr-check` does not
  run the generator and neither does `./gradlew build`. Phase 11i sat red for four consecutive runs
  on this, and whether `pre-pr-check` should run it is still open.

## Open items this phase inherits and does not close

Recorded so nobody rediscovers them as new.

- The absolute form is absolute in `y` only **modulo the collider radius**: a slot is born at
  `270 + radius`, so a waypoint written `y: 190` is flown at 196.5 on `enemy-shooter`. Measured,
  documented, unchecked by anything. Task 5 must write coordinates knowing it.
- [#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280) — a loop is always a path's tail,
  so "circle three times and then dive" is unsayable. No drawn shape has needed it. **A redesign
  might be the first**; if task 5 wants it, that is a finding worth reporting rather than working
  around.
- [#216](https://github.com/LuchoC-Dev/little-spaceship/issues/216) — level 1 has no timer and
  nothing tells the player how far through a level they are.
- [#289](https://github.com/LuchoC-Dev/little-spaceship/issues/289) — the playfield's size is written
  in five places across two modules.
- `JsonBalanceValues`'s other twenty fields are unverified against a parsed fixture. Carried since
  11i.
- Whether `tools/pre-pr-check` should run the document generator. Carried since 11i, and this phase
  is one where it would bite.
