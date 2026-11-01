# Phase 11k — Level 1 rebuilt on a vocabulary written for it · status

**State:** **done, and on `dev`.** Merged in [#341](https://github.com/LuchoC-Dev/little-spaceship/pull/341)
on 06/09/2026, with the project owner's direct approval. Seventeen pull requests merged into
`phase/11k-level-one-rebuilt`, CI green, no defect of this phase left open. **The project owner
played the level and the boss across three sessions**, approved both, and every verdict this phase
turned on is theirs.
**Updated:** 06/09/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the
phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by
whoever did that task on its own branch. Fifteen fragments.

## Why this phase existed

**Three phases built for it and none of them used it.** 11h built a test mode so a wave could be
looked at without playing to it, 11i made a movement shape an ordered list of bounded segments with
waits, repeats and mirroring, and 11j let a path be written where it happens and run faster without
changing size. Each ended with level 1 deliberately untouched, and the project owner asked at the end
of 11j why nothing new appears while playing. Nothing did, by design. This is the phase where it does.

## What the project owner decided, and when

**Before any work began, on 05/09/2026**, asked in one pass: the whole level changes; the beats may
move, be added or removed; **"simple movements" is a rule per archetype** — two or three that
resemble each other, mirrors free; **the vocabulary is written new**, the seven entries from 11c
change and the twelve from 11i/11j are test material that is never placed; ~2.5 minutes is the right
length; the boss keeps its difficulty, health and shots and gains movement; #255 is in scope; the
TESTS list gets discovered; #300 is a first task; and the play session gates the phase.

**After playing the rebuilt level, on 06/09/2026**, they approved it and asked for three things: more
formations moving as a whole along a trajectory, a **single-file column** where each ship traces the
path of the one ahead, and — the boss having become too easy — **front weapons on their own clock**.
They also designed the boss's movement themselves: a five-pointed star used as ten waypoints, with
every hop constrained to three perimeter steps.

**After playing the boss with its new weapons**, they found it too hard and lowered the front
cadence; then, playing again, called the gameplay perfect and **deferred the formation content to
future levels**.

## Done

| # | Task | Issue | PR |
|---|---|---|---|
| 1 | The generator understands a `path` trajectory | [#310](https://github.com/LuchoC-Dev/little-spaceship/issues/310) | [#312](https://github.com/LuchoC-Dev/little-spaceship/pull/312) |
| — | A path's sideways exit measured from the trailing edge | [#314](https://github.com/LuchoC-Dev/little-spaceship/issues/314) | [#315](https://github.com/LuchoC-Dev/little-spaceship/pull/315) |
| 2 | An absolute path checked against its `atX` | [#300](https://github.com/LuchoC-Dev/little-spaceship/issues/300) | [#316](https://github.com/LuchoC-Dev/little-spaceship/pull/316) |
| 3 | The TESTS list discovered from `assets/data/test-*.json` | [#311](https://github.com/LuchoC-Dev/little-spaceship/issues/311) | [#313](https://github.com/LuchoC-Dev/little-spaceship/pull/313) |
| 4a | `core` can place a pickup no enemy carries | [#318](https://github.com/LuchoC-Dev/little-spaceship/issues/318) | [#319](https://github.com/LuchoC-Dev/little-spaceship/pull/319) |
| 5 | The trajectory vocabulary level 1 is rebuilt from | [#320](https://github.com/LuchoC-Dev/little-spaceship/issues/320) | [#321](https://github.com/LuchoC-Dev/little-spaceship/pull/321) |
| — | An `arc` with a negative `ay` | [#322](https://github.com/LuchoC-Dev/little-spaceship/issues/322) | [#323](https://github.com/LuchoC-Dev/little-spaceship/pull/323) |
| 6 | Level 1 rebuilt on it | [#324](https://github.com/LuchoC-Dev/little-spaceship/issues/324) | [#326](https://github.com/LuchoC-Dev/little-spaceship/pull/326) |
| 7 | The boss moves between the ten vertices of a star | [#325](https://github.com/LuchoC-Dev/little-spaceship/issues/325) | [#327](https://github.com/LuchoC-Dev/little-spaceship/pull/327) |
| — | The boss's front weapons, and a fixed move duration | [#329](https://github.com/LuchoC-Dev/little-spaceship/issues/329) | [#332](https://github.com/LuchoC-Dev/little-spaceship/pull/332) |
| — | The front cadence lowered after play | [#333](https://github.com/LuchoC-Dev/little-spaceship/issues/333) | [#335](https://github.com/LuchoC-Dev/little-spaceship/pull/335) |
| — | A formation slot delayed in time (`core`) | [#330](https://github.com/LuchoC-Dev/little-spaceship/issues/330) | [#331](https://github.com/LuchoC-Dev/little-spaceship/pull/331) |
| — | The loader reads a slot's delay | [#334](https://github.com/LuchoC-Dev/little-spaceship/issues/334) | [#336](https://github.com/LuchoC-Dev/little-spaceship/pull/336) |
| — | The delayed crossing counted in ticks | [#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337) | [#338](https://github.com/LuchoC-Dev/little-spaceship/pull/338) |
| — | Advice about trajectories that no longer exist | [#328](https://github.com/LuchoC-Dev/little-spaceship/issues/328) | [#339](https://github.com/LuchoC-Dev/little-spaceship/pull/339) |
| — | Opening the phase | — | [#309](https://github.com/LuchoC-Dev/little-spaceship/pull/309) |

**Seven planned tasks and eight defects found while the phase ran.** `reviewer` audited nine
branches; two were rejected and both rejections were real, reproduced defects.

## What the phase built

**A vocabulary written for this level.** Thirteen authored shapes, six `mirrorOf` and one `speedOf`,
replacing the seven entries 11c wrote. Its shape is **per archetype**: `enemy-basic` falls,
`enemy-light` crosses and never stops, `enemy-shooter`'s every shape contains a stationary hold,
`enemy-rush` commits at 115–130 u/s and differs only in which edge it leaves by, `enemy-tank` never
exceeds 26 u/s, `enemy-carrier` arrives and parks. **`basic` and `shooter` share nothing, and neither
do `tank` and `carrier`** — before this phase each pair flew the same shape and was indistinguishable
in movement.

**Level 1 rebuilt on it.** Twelve placements, 68 spawns, waves ending at 134.0 s and the boss entering
at 134.5 s. **Every archetype's default is now the simple base of its family**, so a spawn with no
`trajectory` key is the shape the player has already learned and a spawn with one is the
complication — the progression is readable in the JSON. **`level-01.json` came out byte-identical**:
the entire redesign lives in `waves.json`, which is 11b's split paying off rather than an oversight.

**A boss that moves.** Ten vertices of a five-pointed star, every hop within three perimeter steps,
chosen from the seeded `Rng`, the points derived offline and written as literals because 11j refused
runtime trigonometry on a measured determinism constraint. A move takes a **fixed duration**
regardless of distance — the owner's own solution to a synchronisation problem the coordinator raised
— so the boss crawls on a short hop and accelerates across a long one, and the cycle length is a
constant.

**Front weapons on their own clock.** The pods keep the charged shot and stay tied to the standstill;
the arms fire on a period of the cycle divided by an integer, so they coincide with every rear volley
by arithmetic rather than by correction. **~5.3 projectiles/s before, ~13.1 after**, after the owner
played it at ~17.5 and asked for less.

**Three capabilities built and deliberately unused.** They are recorded here so nobody later mistakes
them for something broken:

- **A single-file column.** A formation slot can carry a delay and the follower traces the leader's
  path exactly, through the loader and the engine. **No content uses it** — the owner deferred the
  formation work to future levels after deciding the gameplay was already right.
- **A pickup content can place** without an enemy dying. `core` can do it; **the loader half was
  never built**, on the owner's instruction, so content still cannot ask for it. [#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255)
  stays open and half of it is now done.
- **The `speedOf` and absolute forms** are in the vocabulary but thinly used.

**A generator that can read what the content says.** It began the phase blind to half the movement
vocabulary — `grep` for `path`, `segments`, `waypoints`, `mirrorOf` or `speedOf` returned only Node's
own `path` module — and a level placing one crashed it. It now resolves every kind, measures a
sideways exit from the trailing edge, handles a steepening arc, checks that an absolutely-authored
path sits at the `atX` it was written for, and no longer gives advice about shapes that were deleted.

**A TESTS menu that maintains itself.** Discovered from `assets/data/test-*.json`, ordered by a rank
in the filename so the newest is first, and tested for the first time. It closes the three costs 11j
measured: a content task no longer needs a round trip through `game/` to list its own scenario.

## The result worth keeping

**Five times in this phase the code was right and the prose was wrong, and every one was found by
someone re-deriving rather than reading.**

- A javadoc naming a guard that never fires (carried in from 11j).
- Five removal times short by exactly one collider radius (11j).
- An `atX` window rounded the wrong way — 0.53 written as 0.54.
- The boss's cycle order documented backwards, generalising the first cycle onto every cycle after it.
- The loader's javadoc still explaining a crossing mechanism that had just been deleted.

**No check found any of them.** They were found by `reviewer` re-deriving numbers from the JSON, by
tracing the real compiled classes with a reflection probe, and by the coordinator recomputing an
integration by hand. The instruction that makes it possible is the one 11j introduced and this phase
kept: **a task that authors content must write down what it should look like, with the numbers
derived from the real files.** That instruction has now produced a finding in three consecutive
phases.

**And once, a test asserted nothing.** The replacement for a deleted boss test bounded a delta from
one side only — `deltaSeconds > MOVE_DURATION` — while the failure it claimed to catch makes the
delta *larger*. It passed in both worlds. Caught by the coordinator reading the assertion against the
behaviour it named, then fixed and falsified: with the front clock paused the observed delta was
1.7333 s against 0.895 expected.

## The defect that hid between two modules

**[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337) is the phase's most instructive
failure.** A delayed formation slot activated one tick early — for about 22% of tick counts when the
delay came through the loader, and for 273 of 300 when constructed directly. The cause was that
`MotionSystem` reached the crossing by **repeated addition** of `1f/60f` while the delay itself was
formed by a **single multiplication**, and those two do not agree in float.

**Both halves were well tested and the property was untested.** `core`'s test exercised N = 1 and
N = 12 — both outside the failing bands, by luck. The loader's tests stopped at parsing and never ran
a simulation. **The guarantee the feature exists for is an end-to-end one, and nothing crossed the
seam.** `reviewer` found it by building that check when auditing the loader, and the fix replaced the
float comparison with an integer countdown, verified by a sweep of 1..300 and by a test that drives a
real `JsonContentSource` into a real `SpawnSystem`/`MotionSystem` run.

**Two fragments had asserted the guarantee held in general, citing a test that measured two values.**
Both were corrected with dated notices rather than quietly rewritten.

## Numbers

| | before | after |
|---|---|---|
| `core` tests | 351 | **370** |
| `game` tests | 44 | **50** |
| trajectories in `trajectories.json` | 19 | **32** |
| distinct shapes level 1 flies | 7 | **20** |
| archetypes flying only one shape | 4 of 6 | **0 of 6** |
| boss projectiles per second | ~5.3 | **~13.1** |
| TESTS scenarios | 14 | **20** |

## Coordinator errors, recorded rather than corrected quietly

- **A pull request was merged with its `build` check still pending** ([#336](https://github.com/LuchoC-Dev/little-spaceship/pull/336)).
  CI came out green on the phase branch and the local build passed, so nothing was harmed — but the
  order was wrong, and it is the same shape as 11f's merge with `pre-pr-check` red.
- **A launch prompt stated a rule backwards.** It told the task building the `atX` check that
  `mirrorOf` "negates horizontal components", which is true for velocities and false for an absolute
  entry position, where the mirror **reflects** across the playfield centre. The agent verified it
  rather than believing it, and built an off-centre fixture to prove reflection from negation — the
  two shipped absolute trajectories could not tell them apart, because one of them sits exactly on
  the reflection axis.
- **A launch prompt said "the ten shipped scenarios" when there were fourteen.** The agent chose the
  ten the plan called test material and left phase 11h's four unnumbered, which turned out to give the
  unmatched-convention rule a real case instead of a synthetic one.
- **An acceptance criterion outlived the owner's own tuning.** The requirement that a front shot fire
  during `MOVING` was the coordinator's hardening of "the front weapons are not gated by the
  movement". When the owner lowered the cadence, that criterion became unsatisfiable, and a test
  asserting it had to be replaced. Recorded because it is the second phase running in which a
  coordinator's wording, not an agent's work, created the conflict.

## What is open

- **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255)** — content still cannot place
  a pickup. The `core` half is built; the loader half was not, on the owner's instruction.
- **[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337)** is fixed, but the lesson is
  not closed: **nothing in the repository routinely tests a property across the `core`/`game` seam.**
  The one test that does now exists because a defect forced it.
- **[#317](https://github.com/LuchoC-Dev/little-spaceship/issues/317)** — the `atX` check validates a
  formation's anchor, not each slot, so an absolute path on a multi-slot formation is unchecked. Two
  agents reached this limit independently from opposite directions.
- **[#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280)** — a loop is always a path's
  tail. The redesign never needed it.
- **[#289](https://github.com/LuchoC-Dev/little-spaceship/issues/289)** — the playfield's size is
  written in five places, and `TICK_SECONDS` is now a sixth instance of the same pattern.
- **[#216](https://github.com/LuchoC-Dev/little-spaceship/issues/216)** — level 1 has no timer.
- **`JsonBalanceValues`'s other twenty fields**, carried since 11i.
- **Whether `tools/pre-pr-check` should run the document generator.** Carried since 11i. It did not
  bite this phase, because every content task regenerated.
- **The formation content the owner deferred** — more formations moving as a whole along a
  trajectory, and the single-file column — for future levels.

## Verified by the project owner

**Played on 06/09/2026, in three sessions, and approved.** The level was played and called good, with
enough trajectory variety to make the gameplay interactive; the boss's movement and charged-shot
system were called perfect; the front weapons were tuned down once after play and then accepted, with
the final verdict *"la jugabilidad es perfecta"*.

**Every judgement this phase turned on is theirs.** No agent launched the game except to confirm it
starts, and the three criteria the plan reserved — whether the movement reads as dynamic rather than
harder, whether the pause length is right, whether the star is legible — were never attempted by one.

## What comes after

**Phase 12** — levels 2 and 3, which the roadmap calls the first honest measurement of whether this
group made level-building cheap. It inherits a vocabulary written per archetype, a single-file column
nothing uses yet, and a generated document that can now read everything the content can say.
