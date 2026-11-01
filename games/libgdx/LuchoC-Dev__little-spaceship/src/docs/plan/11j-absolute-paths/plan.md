# Phase 11j — Paths written where they happen, and a speed that does not resize them

**Lane:** content + presentation · **Owner:** `game-presentation` for the loader, `core-domain` for the speed multiplier if it needs a contract, `level-designer` for the trajectories · **Depends on:** 11i (the path vocabulary) and 11h (the test mode, which is how any of it gets looked at)

**Not in `post-mvp-roadmap.md`.** Opened on 04/09/2026. **Its agenda came out of the project owner playing phase 11i**, not out of a plan — which is the second time this group's next phase has been written by a play session.

## Before you start

**Read, in this order:**

1. Your task's issue in full.
2. `docs/plan/11i-path-vocabulary/status.md`, all of it — what the vocabulary is, what it cost, and the seven defects it found. Its "Notes for whoever comes next" is this plan's source.
3. `docs/plan/11c-movement-shapes/shape-catalogue.md`, including the two refusals struck through and dated 04/09/2026.
4. `docs/planning/08-decisions-and-open-items.md`, "Paths, and what scaling a shape costs, 04/09/2026".
5. `CLAUDE.md`, and `docs/plan/how-to-run-a-phase.md`, in particular **"Running the game is not playing it"**.
6. Your agent memory.

## Goal

**A path can be written where it happens rather than as a velocity, the same path can run faster without changing size, and level 1 has the trajectories it will be rebuilt from.**

## The three decisions already taken

**1. An absolute authoring syntax, and it costs nothing in `core`.** The project owner's framing: *relative underneath, absolute on top*. "Entry point, exit point, speed" is a reparameterization — `direction = normalize(B − A)`, `duration = |B − A| / speed` — and the loader hands `core` the same `PathSegment(vx, vy, duration)` it already takes. The same category as `mirrorOf` and the `wait` shorthand: **authoring sugar resolved at load, with no new `core` API.**

**The cost, accepted knowingly: an absolutely-authored path can only happen in one place.** A wave's `atX` decides where a relative shape occurs, which is why `descend-and-turn-left` works from any column. A segment that says "go to x = 104" makes `atX` meaningless for that path. **Two kinds of path with different properties, and mixing them silently is how the library becomes unreadable.**

**2. "Faster" means the same shape at the same size, traversed sooner.** Decided by the project owner on 04/09/2026: velocities up **and** durations down, together. **Not** the other meaning — raising velocities alone scales the shape, which is what happens today and stays an authoring consequence rather than becoming a named knob. **Do not build a `scale`**: nothing written asks for one, and invariant 6 says a case is a written design, not an expectation.

**3. Level 1 gets new trajectories, and `level-designer` decides how many.** The project owner's call, and their reasoning: the path system should be how movement is authored from here, *"al menos que sean movimientos simples"*.

## What "replace the old system" does and does not mean

**The three kinds do not substitute for one another, and this is the fact that shapes task 3.**

| Kind | What it produces | Superseded by `path`? |
|---|---|---|
| `constant` | a straight line at fixed velocity | **No.** It is the simple case the owner exempted |
| `arc` | a **smooth curve** — constant vertical acceleration | **It cannot be.** A `path` is piecewise-constant velocity: it turns in angles, it does not curve |
| `path` | segments, waits, bounded loops | the new one |

`strike-run`, `veer-left` and `veer-right` are `arc`, and they are **the only curved motion in the game**. A `path` imitating one produces a polygon — more angular, not smoother.

So the policy is **`path` for what turns, waits or repeats; `constant` for what is straight; `arc` for what curves** — and `arc` is also the closest thing this project has to the curves deferred out of this phase.

**Nothing is deleted in this phase.** Every entry level 1 uses today stays until the redesign replaces it, which is **11k**. Removing a trajectory in use breaks the level the project owner approved.

## Tasks

1. **The absolute syntax.** `game-presentation`, in `game/adapter/content/`.

   A segment may be written as a destination and a speed instead of a velocity and a duration. Decide the syntax and argue it; whatever it is, **a path must be readable as one thing or the other, not as a puzzle** — say how a reader can tell at a glance which kind of path they are looking at, and whether mixing the two forms inside one path is allowed or refused.

   **Every failure still names the file and the id**, as 11i's loader does: a destination outside the playfield, a zero or negative speed, a destination equal to the start (which is a wait written confusingly, or a divide by zero).

   **Rule 3 still holds.** `PathTrajectoryDefinition` refuses a path whose last segment is at rest. If the absolute form can express something `core` cannot bound, that is a defect.

2. **The speed multiplier.** `core-domain` if it needs a contract, `game-presentation` if it resolves at load — **decide which, and argue it.** The load-time answer is the cheaper one and matches how `mirrorOf` works; a spawn-event answer would let one shape run at two speeds in the same wave, which is a different capability. Say what each buys.

   The semantics are decided: **velocities up and durations down, so the geometry is identical and only the traversal time changes.**

3. **The trajectories level 1 will be rebuilt from.** `level-designer`, on `assets/data/`, **with a test scenario for each**.

   **How many is yours to decide** — the project owner delegated it explicitly. Decide it against the fourteen beats in `docs/planning/04-campaign-and-levels.md` and the level as it stands in `docs/levels/level-01.md`, and **say what the number is for**: a vocabulary the redesign draws on, not a set that fills every slot.

   **Which kind each one is, is the design work.** Use the table above. A path that could be a `constant` should be one.

   **Say what each is meant to look like**, as 11i's task 3 did. That instruction is why 11i caught a description that disagreed with its own JSON, and it is the only thing the project owner can check what they see against.

## Acceptance criteria

- **A path can be authored by destination and speed**, and the loader turns it into the same `PathSegment` `core` already takes — no new `core` API for this.
- **A reader can tell which kind of path they are looking at**, and the answer is written down.
- **The same trajectory can be run faster without changing size**, and there is a test asserting the geometry is unchanged — that is the whole claim.
- **Every new failure names the file and the id.**
- **Every expressible path leaves the playfield in finite time**, and the test that carries that rule in its name still passes.
- **A test scenario per new trajectory**, openable from the TESTS menu. **The menu list is hardcoded in `game/`** and has cost three round trips; the coordinator wires it, and the content task names its ids in its fragment.
- **`node tools/build-level-docs.js` is run and its output committed.** CI checks it and was red for four runs in 11i because a task changed content and did not regenerate.
- `./gradlew build` green, and **CI green — check `gh run list`, not only the local build.** The doc check exists only in CI.
- **The project owner has watched the new trajectories.** The mechanism is approved by playing, not by a passing test.

## What is out of scope

- **Level 1 itself.** Not one wave, not one number, and **nothing deleted from `assets/data/trajectories.json`**. The redesign is **11k**, and this phase exists to give it something to build with.
- **Curves.** A semicircle out of constant-velocity segments is a polygon; real circular motion needs a rotating velocity, i.e. sin/cos, and `BossSystem` was deliberately built from vector arithmetic and `Math.sqrt` instead *"so that determinism survives TeaVM"*. **Its own decision, with a constraint already measured, and no sketch asks for it yet.**
- **A `scale` multiplier.** The other meaning of "faster". Not asked for; invariant 6.
- **[#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280)** — a loop is always a path's tail. Recorded as a limit; no drawn shape needs the fix.
- **New enemy archetypes**, obstacles, and the boss. All still refused or deferred by the project owner.
- **Making the TESTS list discoverable.** Named twice, measured at three round trips, and still not decided. **If this phase adds many scenarios, say whether that changed.**

## Risks

**Two ways to say the same thing, and no way to tell them apart.** The absolute form and the relative form produce identical `PathSegment`s, so a reader of `trajectories.json` will not be able to tell which they are looking at unless the syntax makes it obvious. That is the single biggest thing this phase can get wrong, and it gets worse with every entry added afterwards.

**Building a path language.** Splines, easing, per-segment conditions. The written design is the project owner's sketches and this plan; nothing else is a case.

**Deleting something level 1 uses.** The level was approved across sessions and is not this phase's.

**Trusting a local green build.** 11i spent four CI runs red while `./gradlew build` passed every time.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a worktree per parallel worker created by the coordinator, a pull request against `phase/11j-absolute-paths`, and a status fragment in `status/` before review.

**Tasks 1 and 2 can run in parallel**; both touch `game/adapter/content/`, so they need explicit per-file boundaries in their prompts. **Task 3 waits on task 1**, because it is what proves the syntax: if "enter at the top centre and leave to the right" is easy to write and comes out right, the syntax is right.

**Name the shared contract in the issue.** 11i published its JSON shape in a comment and it worked; 11h let two agents guess and they matched by luck.

## What comes after

**Phase 11k — level 1 rebuilt on these trajectories**, which is what the project owner wanted from the start and what all of 11h, 11i and 11j were built to make possible.
