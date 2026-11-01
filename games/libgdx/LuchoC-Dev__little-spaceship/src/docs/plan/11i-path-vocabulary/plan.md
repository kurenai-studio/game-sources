# Phase 11i — A path is a list of segments, and a shape can be mirrored

**Lane:** core + content · **Owner:** `core-domain` for the contract and the evaluation, `game-presentation` for the loader, `level-designer` for the entries · **Depends on:** 11c (the movement shapes and their refusals) and 11h (the test mode, which is how anything here gets looked at)

**Not in `post-mvp-roadmap.md`.** Opened on 03/09/2026 by the project owner, who drew what they wanted level 1's enemies to do and found that the movement vocabulary cannot express any of it.

## Before you start

**Read, in this order:**

1. Your task's issue in full.
2. **`docs/plan/11c-movement-shapes/shape-catalogue.md`, all of it, and its "What is refused" table twice.** This phase reopens two of those eight refusals. Both were right when they were written and the reason they were right is what tells you what to build now.
3. `docs/levels/level-01.md` — generated, and the most accurate picture of the level.
4. `CLAUDE.md`, and `docs/plan/how-to-run-a-phase.md`, in particular **"Running the game is not playing it"**.
5. Your agent memory.

## Goal

**An enemy can follow a drawn path — enter, turn, wait, loop a bounded number of times, leave — and a mirrored version of a shape costs no second definition.**

## What the project owner drew

Eleven sketches, in two batches. Every one of them is a single unit's path across the playfield, and the vocabulary they need is three things and no more:

1. **Segments.** Come down, turn, leave sideways. Enter horizontally, turn, drop. A long diagonal. A curve into an exit. A path stops being one formula and becomes an ordered list.
2. **Waits.** A marked point where the unit stays: some with a number of seconds beside them, some drawn as indefinite.
3. **Loops.** A trailing part of the path, drawn in a second colour, that repeats.

Two of the eleven are mirrors of two others, and two more are mirrors of each other. **The owner asked explicitly that a mirror not cost a second hand-written definition.** `assets/data/formations.json` already carries `diagonal` and `diagonal-mirror` as separate entries, which is the pattern this phase should stop repeating rather than extend.

**The sketches are examples, not a delivery list.** The owner's words: the number of trajectories gets decided once the system is approved. **Ship the mechanism and enough entries to prove it works. Do not try to build eleven.**

## The two decisions the owner took, and what each one bought

**Loops and waits are bounded.** Not "until destroyed" — a count, then the unit leaves. The owner reached this themselves: *"por ahí sería más fácil dejarla que se repita x veces y después que se vaya"*.

**That decision is why this phase is small, and it needs saying out loud.** `shape-catalogue.md` refuses `enterAndHold` with a specific hazard: *"an entity that comes to rest inside the playfield never goes off screen, so `LifetimeSystem` never removes it and a `cleared` wave behind it cannot end unless the player kills it."* A bounded path always ends by leaving, so:

- **The catalogue's rule 3 survives unchanged** — *"must leave the playfield unattended in finite time"*. It is not being rewritten or waived. Every path this phase can express still obeys it, and **a path that does not is a defect, not a feature**.
- `LifetimeSystem` needs no change.
- `Cleared` stays usable as a future design tool instead of being poisoned by shapes that can deadlock it.

An indefinite wait becomes a large number. A permanent loop becomes a large count. To the player, a unit that lingers fifteen seconds and one that lingers forever are the same thing — they killed it or dodged it long before either.

**The representation stays relative, and the authored values are what land on absolute positions.** The owner: relative in code so a shape is reusable; the first entries carry values that put the path where the sketch puts it. A shape is a shape; where it happens is still the wave's `atX`.

## What the code already gives you, and the one thing it does not

**Read this before designing anything.** The contract is already a pure function of elapsed time:

- `core/port/TrajectoryDefinition.java` — `verticalVelocityAt(float elapsedSeconds)`, explicitly *"a pure function of `elapsedSeconds` and this shape's own parameters — reads nothing else"*.
- `core/domain/component/Trajectory.java` holds exactly two fields: `trajectoryId` and `elapsed`. Its javadoc refuses an origin field by name, as an abstraction with no case.

**With bounded segments of known duration, a path is still a pure function of `elapsed`** — walk the list accumulating durations and you know which segment you are in and how far into it. **No new per-entity state is needed.** That matters because it is precisely the cost the catalogue refused waypoints over: *"each costs per-entity path state well beyond the elapsed-time clock"*. Bounding the loops removed that cost. Say so in the design; a reader of the catalogue will otherwise think this phase overrode a refusal it actually dissolved.

**The one thing that must change** is that `TrajectoryDefinition` fixes `vx()` as constant for an entity's whole life — *"Horizontal velocity never varies with time in either kind"*. A path that turns needs the horizontal component to be a function of elapsed time too, symmetrical with the vertical one. That is the real contract change and it is small.

## Tasks

1. **The path contract and its evaluation.** `core-domain`.

   A third kind alongside `constant` and `arc`: an ordered list of bounded segments, each with a duration, plus waits and bounded repeats. `TrajectoryDefinition` is `sealed`; adding a kind is a deliberate act and the sealing is what makes it one. Keep it sealed.

   **Constraints that are not negotiable**: pure function of elapsed time, no clock, no `Math.random()`, no libGDX in `core`, no threads, no per-frame allocation in the evaluation path. A path that cannot leave the playfield in finite time must be impossible to express, or must fail loudly at load — decide which and say why.

   **Mirroring is part of this task's design, not a fourth kind.** Decide where it lives — a flag on a definition, a derived id, something else — and argue it. The bar: adding the mirror of a shape must not mean writing the shape twice.

2. **The loader.** `game-presentation`, on `game/adapter/content/`.

   Read the new kind from `assets/data/trajectories.json`. `JsonContentSource` rejects any key its schema does not name and fails at load with the file and the id named — keep that guarantee; it is the reason a typo is a startup failure instead of a mystery at second 90.

3. **Entries enough to prove it, and a way to look at them.** `level-designer`.

   A handful of paths that exercise every part of the vocabulary — a turn, a wait, a bounded loop, a mirror — and **a test scenario per `assets/data/test-*.json` so the project owner can watch each one without playing to it.** That is what phase 11h built and this is its first real use.

   **Do not touch level 1.** Not in this phase.

4. **[#252](https://github.com/LuchoC-Dev/little-spaceship/issues/252) — a dropped pickup falls.** `core-domain`.

   `CleanupSystem.java:74-79` gives a pickup `Transform`, `Collider`, `Sprite` and `Pickup`, and no `Motion`, so it hangs in the air where its carrier died. The speed is a value in `assets/data/balance.json`, not a constant in code. **This changes level 1's difficulty** — five drops become five drops that can be missed — which is why it is here, in a phase the owner will be playing anyway, and not folded into 11h.

## Acceptance criteria

- **A path with a turn, a bounded wait and a bounded repeat can be written in `assets/data/trajectories.json` and followed by an enemy.**
- **A mirrored shape costs no second definition.**
- **Every expressible path leaves the playfield in finite time**, and there is a test that says so by name.
- **Determinism holds.** `core` reads no clock, calls no `Math.random()`, imports no libGDX, spawns no thread. The existing replay tests still pass.
- **`./gradlew build` green**, and `core`'s suite grows — a rule this size is what its three hundred tests are for.
- **A test scenario exists for each new path**, openable from the TESTS menu.
- **The project owner has watched them.** The mechanism is approved by playing, not by a passing test, and **the number of trajectories is decided after that, not in this phase**.
- **`docs/plan/11c-movement-shapes/shape-catalogue.md` is updated**: the two reopened refusals are struck through and dated, saying what changed and why, in the form the catalogue already uses. **A refusal that silently stops being true is worse than one that was never written.**

## What is out of scope

- **Level 1.** Not one wave, not one number. Its redesign is **11j**, which is what this vocabulary exists for.
- **Formations in time** — a formation following one path in single file, one behind another. That is the owner's other idea and it is **11j**'s, deliberately: it is a change to what a formation is, and it wants the path vocabulary underneath it first.
- **New enemy archetypes.** Refused by the owner on 03/09/2026.
- **Obstacles.** Waiting on the story and the final background.
- **The boss.** The minimum the owner will allow to move.
- **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255)** — placing a power-up without an enemy. Scheduled to the 12 group.
- **Deciding the final set of trajectories.** Explicitly the owner's, after they have seen the system work.

## Risks

**Building a path language instead of a path.** Splines, easing curves, per-segment conditions and a schema nobody can read are all one step past what eleven sketches ask for. **Invariant 6 is the whole guard here**: a case is a written design, and the written design is those sketches. Build what they need.

**Overriding a refusal instead of dissolving it.** Two of 11c's eight refusals are reopened by this phase. Both were correct. One is dissolved by the owner's bounding decision — the cost it named no longer applies — and the other is genuinely reopened by a written case that did not exist. **Write which is which**, or the next reader learns that this project's refusals do not hold.

**A path that never leaves.** The one hazard the catalogue actually predicted. It must be unrepresentable or must fail at load, and there must be a test with that rule in its name.

**Changing level 1 by accident.** Task 4 changes it on purpose, and it is the only thing in this phase allowed to. Everything else stays off `assets/data/level-01.json`, `waves.json` and `formations.json`.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a worktree per parallel worker created by the coordinator, a pull request against `phase/11i-path-vocabulary`, and a status fragment in `status/` before review.

**Tasks 1 and 2 are sequential** — the loader reads a contract that has to exist. **Task 4 is independent** of all of it and runs alongside. **Task 3 waits on both 1 and 2.**

**Name the shared contract in the issue, not in each agent's assumption.** Phase 11h got away with two agents guessing the same four ids by luck; that is not a method.
