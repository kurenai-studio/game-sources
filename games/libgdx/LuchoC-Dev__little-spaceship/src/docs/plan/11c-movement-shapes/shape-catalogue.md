# The movement shape catalogue

**Decides:** which movement shapes exist, and refuses the rest — task 2 of
[phase 11c](plan.md), [#162](https://github.com/LuchoC-Dev/little-spaceship/issues/162).
**Owner:** `level-designer`. **Written:** 29/08/2026.

**Nothing in this document is built.** It is a decision that
[#163](https://github.com/LuchoC-Dev/little-spaceship/issues/163) turns into a contract and a loader
and [#164](https://github.com/LuchoC-Dev/little-spaceship/issues/164) puts on a `SpawnEvent`. The only
part of it that exists today is the `constant` kind, as
`core/port/TrajectoryDefinition.java` and the four entries in `assets/data/trajectories.json` — and
those four stay valid, unedited, as the first four rows of this catalogue.

---

## What a shape is, and the four rules it obeys

A shape is a **function from the entity's own elapsed time to its velocity**. Nothing else goes in.

1. **A shape reads its own elapsed time and its spawn state, and nothing else.** No player position,
   no world queries, no other entity. A shape that reads the player is a homing behaviour: a
   different thing, a game rule nobody has decided, and out of bounds for this phase by the issue's
   own words. If a beat asks for one, stop and ask.
2. **A shape carries no randomness.** `World.rng()` exists (`core/domain/World.java:400`) and nothing
   here needs it. Determinism is not the reason — a seeded draw would replay fine — the reason is
   that a level designer cannot place what they cannot predict.
3. **Every shape leaves the playfield unattended, in finite time.** This is load-bearing twice: a
   `cleared` wave (`core/port/WaveEndCondition.java`) only ends when everything it spawned is gone,
   and `LifetimeSystem` removes an enemy *only once it is off screen*
   (`core/domain/system/LifetimeSystem.java`, safety box `x ∈ [-128, 336]`, `y ∈ [-128, 398]`, per
   `docs/planning/08-decisions-and-open-items.md`). A shape that comes to rest inside the playfield
   would let a `cleared` wave deadlock behind an enemy the player is not obliged to kill. Every entry
   below is checked against this and the exit time is stated.
4. **Units.** Logical units and seconds; `y` is positive upward, so a descending enemy has negative
   `vy` — the sign convention the four existing entries already use. The playfield is 208 wide and
   270 tall, and `SpawnSystem.positionSpawned` puts a formation's lowest slot at `270 + radius`.

---

## The two kinds that exist

### 1. `constant` — a fixed velocity

| Parameter | Meaning |
|---|---|
| `vx` | horizontal velocity, units/second |
| `vy` | vertical velocity, units/second (negative descends) |

`velocity(t) = (vx, vy)`. This is what ships today, and **a constant velocity is a shape** — the four
entries in `assets/data/trajectories.json` are `constant` shapes and need no change.

**The roadmap's "straight 30° diagonal" is this kind, not a new one.** It is `constant` with
`vx = |vy| · tan 30° `; `swoop` (`-10, -40`) is already the same idea at 14°. Naming a separate
`diagonal` kind would be a second name for arithmetic the designer does in their head once.

### 2. `arc` — a constant velocity with a constant vertical acceleration

| Parameter | Meaning |
|---|---|
| `vx` | horizontal velocity, constant for the whole life, units/second |
| `vy` | vertical velocity **at spawn**, units/second |
| `ay` | vertical acceleration, units/second² |

`velocity(t) = (vx, vy + ay · t)`.

Three numbers, and it is the **U-shaped attack run the roadmap names**: enter descending fast, slow,
bottom out, climb away. It is a parabola, so the turn is smooth rather than a bounce — a piecewise
"descend then reverse" would read as a ricochet, and that is why the acceleration form was chosen over
a segment list.

Two derived quantities a designer needs, and the reason this kind is worth having as data rather than
as three hand-tuned constants:

- **it turns at** `t = -vy / ay`
- **its apex sits** `vy² / (2·ay)` **below where it spawned**

Set the apex where the player flies (`playerStartY` is 30, `assets/data/balance.json`) and the archetype
threatens and withdraws instead of falling past. `ay = 0` degenerates to `constant`; that is a
coincidence of the maths, not a licence to delete `constant`, whose four entries are already written
and whose javadoc-level simplicity is worth keeping.

**No `ax`.** Horizontal acceleration has no beat pointing at it. See the refusals.

---

## The entries

The four that exist, unchanged, plus three new ones. An entry is content — a named instance of a kind
— exactly as `slow-descent` is today.

| id | kind | parameters | turn | apex | reads as |
|---|---|---|---|---|---|
| `slow-descent` | `constant` | `vx 0, vy -18` | — | — | the default descent |
| `swoop` | `constant` | `vx -10, vy -40` | — | — | a shallow drifting descent |
| `dive` | `constant` | `vx 0, vy -80` | — | — | straight down, fast |
| `crawl` | `constant` | `vx 0, vy -9` | — | — | a heavy that stays ~30 s |
| `strike-run` | `arc` | `vx 0, vy -110, ay 27` | 4.07 s | 224 below spawn | drops onto the player's line, hangs there a moment, climbs back out |
| `veer-left` | `arc` | `vx -32, vy -95, ay 20` | 4.75 s | 226 below spawn | crosses right-to-left while diving, then leaves up and left |
| `veer-right` | `arc` | `vx 32, vy -95, ay 20` | 4.75 s | 226 below spawn | the mirror |

**Checked, entry by entry, against rule 3 and against the playfield:**

- `strike-run` on `enemy-rush` (radius 4, spawn `y = 274`): apex `y ≈ 50`, which is 20 units above
  `playerStartY`. Back at spawn height at 8.15 s, through the safety box's `y = 398` at 9.15 s. It
  always leaves.
- `veer-left` on `enemy-light` (radius 4.5, spawn `y = 274.5`): apex `y ≈ 49`, 152 units to the left
  of where it spawned. **It must be spawned on the side it veers away from** — `atX ≥ 0.75`, or it
  crosses the left edge before reaching its apex and the whole shape happens off screen. At
  `atX 0.9` (`x = 187`) the apex sits at `x ≈ 35`, inside the playfield; it crosses `x = 0` at 5.85 s
  and the safety box at 9.85 s. `veer-right` mirrors, `atX ≤ 0.25`.

---

## What points at what

Level 1's fourteen beats, from `docs/planning/04-campaign-and-levels.md` → "Provisional sequence",
against the waves in `assets/data/waves.json` that carry them today. **This is a map of what asks for
a shape, not a level edit** — level 1 was last rebuilt in
[11k](../11k-level-one-rebuilt/plan.md).

| # | Beat | Wave today | Shape it points at |
|---|---|---|---|
| 1 | audiovisual introduction | *(no wave)* | not built; nothing in `waves.json` carries it |
| 2 | initial calm | `l1-opening-calm` | `settle-descent` — one basic at a time, slow enough to outrun sideways |
| 3 | first isolated basics | `l1-first-basics` | `settle-descent`, then **`descend-and-step-left`/`-right`** — the same fall with one lane change in it |
| 4 | light/fast | `l1-light-and-fast` | `cut-across-left`/`-right`, then **`dive-across-left`/`-right`** — the straight crossing before the steepening one |
| 5 | combined formations | `l1-combined-formations` | `settle-descent` and both step shapes under crossing lights |
| 6 | tanks and shifts in priority | `l1-tanks-and-priority` | `grind-down`, then **`grind-and-wheel-left`** — the shift in priority *is* the screen time |
| 7 | super-fast | `l1-super-fast` | `plunge`, then **`plunge-and-cut-left`/`-right`** and **`strike-and-withdraw`** |
| 8 | one or two heavy carriers | `l1-heavy-carrier` | `descend-and-anchor` — one carrier parked for fourteen seconds, five children while parked |
| 9 | evolved basics/shooters | `l1-evolved-shooters` | `descend-hold-descend`, then **`advance-the-firing-line`** (absolute, `atX 0.50`) |
| 10 | high-pressure combinations | `l1-high-pressure` | `dive-across-*` and `plunge-and-cut-*` across descending basics and a shooter line |
| 11 | difficult encounter → attachment | `l1-twin-carriers-attachment` | **`anchor-and-traverse-left`/`-right`** carriers crossing over each other, with rush cuts under them |
| 12 | brief rest | `l1-brief-rest` | `settle-descent` |
| 13 | final escalation | `l1-final-escalation` | everything, both `grind-and-wheel`s and `plunge-harder` included |
| 14 | boss | *(no wave)* | `BossSystem`'s, entering at 134.5 s over no wave ([#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88)) |

**Updated 06/09/2026, in phase 11k ([#324](https://github.com/LuchoC-Dev/little-spaceship/issues/324)).**
The "Shape it points at" column was replaced entirely: the seven shapes 11c authored —
`slow-descent`, `swoop`, `dive`, `crawl`, `strike-run`, `veer-left`, `veer-right` — were **deleted
from `assets/data/trajectories.json`** by that task, and every beat now points at the vocabulary
[#320](https://github.com/LuchoC-Dev/little-spaceship/issues/320) wrote per archetype. The twelve
wave ids did not move.

**Beats 1 and 14 were already wrong before this edit**, and that is the finding this update also
carries: the row for beat 1 named `l1-intro-flyover` and beat 14 named `l1-boss-approach`, and
`grep -c "l1-intro-flyover\|l1-boss-approach" assets/data/waves.json` prints `0`. They were removed
when 11e's fourteen waves became twelve, and **nothing failed** — exactly what
[#208](https://github.com/LuchoC-Dev/little-spaceship/issues/208) is about. Both rows now say
*(no wave)* rather than naming an id that does not exist.

**Updated 01/09/2026, in phase 11e.** Every wave id in the table above was replaced when
[#198](https://github.com/LuchoC-Dev/little-spaceship/issues/198) rebuilt level 1 as fourteen waves.
The table as 11c wrote it named `l1-basic-intro`, `l1-tank-solo`, `l1-carrier-pair` and nine others,
and **not one of them still existed** the day after the phase that blessed this pointer closed.

That this table needs a dated correction at all is the finding, and it is recorded as **C8** in
`docs/plan/11d-per-level-document/document-contract.md`. `docs/levels/level-01.md` is generated and
CI refuses to let it drift; it sends the reader here for the one thing it cannot generate, and here
is hand-written, so this is the single place in the chain where a level document can be wrong.

**The prose below argues the three `arc` entries 11c shipped, and level 1 no longer flies any of
them.** It is kept, unedited, as the record of why they were built and what beat asked for each —
the beats did not move, and the argument is what the next shape has to beat. `strike-run` is
answered today by `strike-and-withdraw` and `plunge-and-cut-*` on `enemy-rush`; the veers by
`dive-across-left`/`-right` on `enemy-light`, which is the only entry in the current vocabulary that
is still an `arc`.

Beat by beat, why each new entry ships:

- **`strike-run` — beats 7, 11 and 13.** Beat 7 is where the phase's own goal sentence lands: *the
  same archetype enters differently at second 30 and at second 200*. `enemy-rush` on `dive` crosses
  the screen in about 3.4 s and is a falling object; the only levers a designer has over it today are
  `atX` and timing. On `strike-run` the same archetype commits to the player's own band and then
  leaves, which is a threat the player has to answer rather than avoid by standing still. Beat 11 is
  the one the campaign document calls *a difficult encounter*, and
  `docs/planning/01-vision-and-scope.md:89` refuses to let difficulty rest on health — *"Difficulty
  must not depend only on raising health and damage. It can increase through density, speed,
  combinations, **entrances**, patterns, obstacles, available space and simultaneous pressure"*, and an
  entrance is exactly what a shape is. `strike-run` rushes around the two `crawl` carriers make that
  encounter about movement instead of about the carriers' 80 hit points.
- **`veer-left` / `veer-right` — beats 10 and 13.** `03-game-systems.md` lists **space** as a pressure
  axis, and a diagonal attack run crossing under descending formations is the one thing in this
  catalogue that moves the safe corridor rather than filling it. They also answer the roadmap's own
  sentence for N6 — *enters from one direction with one movement early, from another direction with a
  different movement at the midpoint* — which is written design, not a hunch. Two entries rather than
  one because level 1's content is symmetric everywhere else (`diagonal` / `diagonal-mirror` already
  exist as a pair in `assets/data/formations.json`).

**Phase 12's levels 2 and 3 justify nothing here, and that is a finding rather than an omission.**
They have no beat list: `docs/plan/post-mvp-roadmap.md` → "Phase 12" says what those levels are *for*
(the first honest measurement of whether waves and shapes made level-building cheap), and
`04-campaign-and-levels.md` gives stage 1 only an evolution sentence — *"It begins with simple alien
units and small formations. Coordination, variety and pressure increase as the stage advances."* That
is not a beat, and a shape built on it would be a shape built on expectation. **Every entry above is
pointed at by a beat of level 1.** When level 2 is designed and names something this catalogue cannot
express, that is the case that adds the next kind.

---

## What is refused

Invariant 6 in the form the assessment's Part 3 applies it: a case is a written design, never a
"levels will obviously want it". Refusing is a result.

| Refused | Why |
|---|---|
| A `diagonal` kind, the roadmap's 30° | It is `constant` with a chosen `vx`. A second name for one multiplication. |
| A `logarithmic` / decelerating-entry kind | What the roadmap wanted from it — enter fast, settle, stay a threat — is `arc` with `ay` opposing `vy`. The beat that might have justified a *stopping* version, beat 9's shooters, is not strained: `enemy-shooter` on `slow-descent` already has `(270 + 6.5) / 18 ≈ 15 s` of screen time against a `rate` of 1.8 and a `firstShotDelay` of 0.7 (`assets/data/enemies.json`). It dwells plenty. |
| A `sine` / weaving kind | Nothing written points at one. It is the **first candidate to revisit** if 11e plays beat 10 and finds that crossing arcs do not move the safe corridor enough. Named here so the next person does not have to re-derive it. |
| ~~`enterAndHold` / station-keeping~~ | ~~No beat asks, and it is the one shape that can break something: an entity that comes to rest inside the playfield never goes off screen, so `LifetimeSystem` never removes it and a `cleared` wave behind it cannot end unless the player kills it. If it is ever built it must be hold-*then*-resume, with the resume in the data, not optional.~~ **Reopened, 04/09/2026, phase 11i.** The hazard was correctly identified and still holds for the *unbounded* case; what changed is a written case that did not exist here — the project owner's own path sketches, which want a wait mid-path and a trailing loop. Phase 11i answers by **bounding**: every wait is a segment with a finite duration (an "indefinite" one is simply a very large number), every loop repeats a fixed, counted number of times, and `PathTrajectoryDefinition`'s constructor refuses outright any path whose *last* segment would hold still — the one shape that could still reproduce this hazard. See `core/port/PathTrajectoryDefinition.java` and its test `everyPathMustLeaveThePlayfield_pathThatEndsAtRestIsUnconstructible`. This refusal was right when written for the unbounded case it named; it does not generalize to a bounded one, which is why it needed reopening rather than silently ceasing to apply. |
| Horizontal acceleration (`ax`) on `arc` | No beat asks for a curve that flattens or sharpens sideways. `vx` constant is what the three entries above need. |
| ~~Waypoints, splines, segment lists~~ | ~~No case, and each costs per-entity path state well beyond the elapsed-time clock #161 is building.~~ **Dissolved, not overridden, 04/09/2026, phase 11i.** The cost this refusal named — "per-entity path state well beyond the elapsed-time clock" — stopped applying the moment phase 11i bounded every segment's duration and every loop's repeat count: with those fixed at content-load time, which segment is active at a given `elapsedSeconds` is arithmetic on the definition's own parameters, exactly like `arc`'s closed form, and `Trajectory` still needs only `trajectoryId` and `elapsed`. No waypoint index, no repeat counter, nothing cached on the entity. Splines and per-segment conditions remain refused: nothing bounds them the way a fixed segment list is bounded, and no beat asks for either. |
| Formation-relative shapes (rotating or orbiting a formation's centre) | No case. Formations are placement, and `08-decisions-and-open-items.md` says formations and the layer above them "do not blur". |
| Anything reading the player | Out of bounds by #162 itself. It is homing, it is a game rule nobody has decided, and the answer is to ask. |

---

## For [#163](https://github.com/LuchoC-Dev/little-spaceship/issues/163), which builds the contract and the loader

The schema this document fixes. The file, the key and the contract's name are `core-domain`'s call in
the end; this is the shape that costs the least churn.

```json
{
  "trajectories": [
    { "id": "slow-descent", "vx": 0, "vy": -18 },
    { "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 },
    { "id": "veer-left",  "type": "arc", "vx": -32, "vy": -95, "ay": 20 },
    { "id": "veer-right", "type": "arc", "vx": 32,  "vy": -95, "ay": 20 }
  ]
}
```

- **`type` is optional and defaults to `"constant"`**, which is what keeps the four existing entries
  valid without being touched — the criterion #162 was given.
- **Stay in `assets/data/trajectories.json`, under the `trajectories` key.** Renaming the file, the
  key and `enemies.json`'s `"trajectory"` field to "movement" would be more honest vocabulary and
  costs a rename across content, `JsonContentSource`, `TrajectoryDefinition` and
  `ComponentFactoryRegistry` for no behaviour. Not worth it inside this phase; say so once rather than
  half-doing it.
- **In a wave's spawn entry the override key should be `"trajectory"` too**, beside `"spawn"` and
  `"formation"`, so there is one vocabulary rather than two.
- **Adding these entries before the loader understands them would be silently wrong**, which is why
  this pull request adds no content. `JsonContentSource.loadTrajectories:157-166` reads exactly
  `id`, `vx`, `vy` and ignores unknown keys, so an `arc` entry written today would load, resolve and
  fly as a `constant` with nobody told. The entries land in the same pull request as the parser that
  reads them.
- **One integration detail worth deciding rather than inheriting.** `MotionSystem.integrate` is Euler
  (`MotionSystem.java:81-94`). Evaluating `arc`'s velocity once per tick and letting Euler integrate
  it gives a position that trails the closed form by `½ · ay · dt · t` — about 0.9 units after 4 s at
  `ay = 27`, invisible on screen and perfectly deterministic either way. Pick one deliberately and let
  the test assert that one; do not let it be an accident of where the evaluation sits in the tick.

## For [#164](https://github.com/LuchoC-Dev/little-spaceship/issues/164), which needs one archetype with two shapes

**`enemy-rush`**, and it is one archetype in `assets/data/enemies.json`. Beat 7 spawns it on `dive`,
its archetype default; beat 13 spawns it on `strike-run` through the spawn event's override. That is
the phase's acceptance criterion and the roadmap's example sentence, in the same archetype.
