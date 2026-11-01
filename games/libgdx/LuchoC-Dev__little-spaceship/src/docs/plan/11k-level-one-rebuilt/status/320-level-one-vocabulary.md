# 320 — the trajectory vocabulary level 1 is rebuilt from

**Branch:** `content/level-one-vocabulary`. **Closes:** [#320](https://github.com/LuchoC-Dev/little-spaceship/issues/320).
`level-designer`, on `assets/data/` only, plus the generated `docs/levels/waves.md` and this fragment.

## What shipped

**Twenty entries** appended to `assets/data/trajectories.json`: **thirteen authored shapes**, **six
`mirrorOf` lines** and **one `speedOf`**. **Six waves** appended to `assets/data/waves.json`, all
`test-` prefixed and therefore `unplaced`. **Six scenario files**,
`assets/data/test-110-basic-family.json` through `test-160-carrier-family.json`, numbered above every
existing scenario (the highest was `test-100-cross`) so they sort to the top of the TESTS menu, which
now ranks by that number descending.

**Nothing was deleted, `level-01.json` was not touched, and `enemies.json` was not touched.**
`node tools/build-level-docs.js` prints `unchanged docs/levels/level-01.md`, which is the mechanical
proof: the generator reads the level against `waves.json`, `trajectories.json`, `enemies.json`,
`formations.json`, `attachments.json` and `balance.json`, and every number it printed for level 1 came
out identical. Only `docs/levels/waves.md` changed, by six added rows.

## The vocabulary, per archetype

**Thirteen authored shapes is the floor, not a choice.** Six archetypes × (one simple base + one
complex) is twelve, `enemy-rush` takes the third the issue allots it, and the two forbidden pairs
(`basic`/`shooter`, `tank`/`carrier`) remove the sharing that would have brought the count under it.
The issue's "nine or ten authored" assumed sharing that its own rules disallow; twenty entries is
what the rules produce, and mirrors are free by the owner's decision.

**No entry is named after an archetype.** Per `02-mvp-functional-spec.md:192` the family is *how a
shape is used in level 1*, not a property of the shape — every one of the thirteen is a shape
statement (`grind-and-wheel-left`, `descend-and-anchor`) and every one is flyable by anything.
The one that comes closest to being single-archetype is `descend-and-anchor`, whose fourteen-second
stop only pays for itself on a unit that does something while stopped — a carrier's spawner or a
shooter's rate of fire. It is not restricted; it is just wasted on a basic.

| Archetype | Movements | What makes them a family |
|---|---|---|
| `enemy-basic` | `settle-descent`; `descend-and-step-left` + mirror | **It falls.** Nothing above 32 u/s, no stop, no reversal, no curve. The complex one is the simple one with a single lane change bolted into the middle — the player reads it as "the same enemy, dodging once". |
| `enemy-light` | `cut-across-left` + mirror; `dive-across-left` + mirror | **It crosses and it never stops.** Both are one continuous motion diagonally across the screen; one is a straight line at constant speed, the other bends steeper as it accelerates. Neither ever turns a corner. |
| `enemy-shooter` | `descend-hold-descend`; `advance-the-firing-line` | **It stops to shoot.** Every shooter shape contains a stationary hold, which is the one thing no basic shape does — this is where the roster's "same as the basic, but a higher rate of fire" is cashed out in movement. The complex one holds twice, at two authored heights. |
| `enemy-rush` | `plunge` (+ `plunge-harder`, the same movement sooner); `plunge-and-cut-left` + mirror; `strike-and-withdraw` | **It commits, fast and straight.** All three enter vertically at 115–130 u/s and never slow down inside the playfield; they differ only in which edge they leave by — the bottom, the side, or back out of the top. |
| `enemy-tank` | `grind-down`; `grind-and-wheel-left` + mirror | **It grinds.** Nothing above 26 u/s, no stop, and at most one slow turn. A tank is space the player cannot use, and both shapes are about how long that space stays occupied. |
| `enemy-carrier` | `descend-and-anchor`; `anchor-and-traverse-left` + mirror | **It arrives and parks.** Both shapes stop dead over the playfield for long enough that the factory is the point and the movement is not; the complex one parks, slides slowly sideways, and parks again. Nothing the carrier does is ever fast. |

`enemy-basic` and `enemy-shooter` share no shape. `enemy-tank` and `enemy-carrier` share no shape.
Checked by reading the table above against the six test waves, which is the only place any of these
is placed.

**All the carrier and tank shapes are relative (`segments`), deliberately.** An absolutely-authored
path only lands where it was written at one `atX`, and `l1-twin-carriers-attachment` places carriers
in the `pair` formation, whose two slots sit at `atX * 208 ± 44` — at most one of them could ever
match an absolute entry point. **An absolute path and a multi-slot formation are mutually exclusive**,
which is worth knowing before task 6 places one.

## What each one is meant to look like

Every number below is the output of a program that constructed the real `JsonContentSource` over
`assets/data` and integrated `horizontalVelocityAt`/`verticalVelocityAt` at 1/400 s from the real
spawn point — not from what was meant. Spawn geometry: `x = atX * 208`, `y = 270 + radius`.
"Removed at" applies `LifetimeSystem.isPastSafetyBox`'s real condition, which tests the entity's
**edge** (`x + radius < -128`, `y + radius < -128`, `y - radius > 398`), so it is one radius later
than the centre crossing. "On screen" is the time any part of the sprite is inside `0..208 × 0..270`.

### `enemy-basic` — the falling family

**1. `settle-descent` — `constant`, `vx 0`, `vy -20`.** A straight vertical fall at a speed the player
can outrun sideways without hurrying. On `enemy-basic` (radius 5.5, spawn `(104, 275.5)` at
`atX 0.50`): fully visible for **14.05 s**, past the bottom edge and removed at **20.45 s**. It never
moves horizontally, so its `atX` window is the whole playfield minus the formation's own width.

**2. `descend-and-step-left` — `path`, `[{0, -32, 2.5}, {-38, 0, 1.2}, {0, -32, 8.0}]`.**
The same fall, half again as fast, interrupted once: it drops for two and a half seconds, slides
**45.6 units left in 1.2 s without descending at all**, and then resumes the identical fall. From
`atX 0.80` (x 166.4): the sidestep happens at **y = 195.5**, between **t = 2.50 s and t = 3.70 s**,
carrying it from x 166.4 to **x 120.8**; on screen **9.98 s**, removed at **13.98 s**. The step is
what makes a column of them stop being a column.

**Its `atX` window:** the drift is 45.6 left, so with `formation: single` it needs
`atX >= (45.6 + 5.5) / 208 = 0.25`; with `line-3` (widest left offset 20) **0.34 or more**.

**3. `descend-and-step-right` — `{ "mirrorOf": "descend-and-step-left" }`.** The reflection, verified:
from `atX 0.20` (x 41.6) it steps to **x 87.2** across the same 2.50–3.70 s window, same 9.98 s on
screen. Window is the reflection: **0.75 or less** for `single`, 0.66 or less for `line-3`.

### `enemy-light` — the crossing family

**4. `cut-across-left` — `constant`, `vx -48`, `vy -46`.** A straight, slightly-past-45-degree line
across the whole width. On `enemy-light` (radius 4.5, spawn `(197.6, 274.5)` at `atX 0.95`): it
sweeps the **entire playfield width, 197.5 down to -4.5**, in **4.21 s** on screen, and is removed at
**6.88 s** having left through the left edge at about **y = 85**, not at the bottom corner. It is
traffic crossing the lane, not something coming at the player.

**5. `cut-across-right` — `{ "mirrorOf": "cut-across-left" }`.** From `atX 0.05` it is the exact
reflection — 10.5 up to 212.5 in playfield, 4.21 s on screen, removed at 6.88 s. Placed together they
cross in the middle of the screen; that is what the scenario shows.

**6. `dive-across-left` — `arc`, `vx -34`, `vy -55`, `ay -22`.** The only shape in the file with a
**negative** `ay`: it does not pull out, it **accelerates downward**, so it enters on a shallow slant
and steepens into a dive as it goes. Vertical speed runs from 55 to **about 124 u/s** by the time it
leaves. From `atX 0.85` (x 176.8): on screen **3.12 s**, crossing from x 176.7 to **x 70.6** inside the
playfield, removed at **4.08 s**, out of the bottom. It is the fastest thing in the vocabulary at the
moment it leaves, and it never stops being one motion.

**Its `atX` window:** the in-playfield drift is 106.1, so `single` needs
`atX >= (106.1 + 4.5) / 208 = 0.53`. The mirror's is **0.47 or less**.

**7. `dive-across-right` — `{ "mirrorOf": "dive-across-left" }`.** From `atX 0.15`: 31.3 to 137.4,
3.12 s on screen, removed at 4.08 s.

### `enemy-shooter` — the firing-position family

**8. `descend-hold-descend` — `path`, `[{0, -40, 2.0}, {wait 3.0}, {0, -45, 8.0}]`.** The simple
version of "stop and shoot": it comes down two seconds, **stands still for three**, then falls out.
On `enemy-shooter` (radius 6.5, spawn `(52, 276.5)` at `atX 0.25`): stationary at **y = 196.5, from
t = 2.00 s to t = 5.00 s**, on screen **9.51 s**, removed at **12.36 s**. Its `firstShotDelay` is 0.7
and its rate 1.8, so it fires roughly twice standing still. It is relative, so it works at any `atX`
and in any formation — a `line-3` of them is a firing line without a single absolute coordinate.

**9. `advance-the-firing-line` — `path`, absolute `waypoints`. Requires `atX 0.50`.**

```
[ {x:104,y:270}, {x:104,y:210,speed:50}, {wait:2.5}, {x:104,y:160,speed:40}, {wait:2.5}, {x:0,y:160,speed:70} ]
```

It descends the centre, **holds a first firing line, drops to a second one fifty units lower, holds
again, and only then leaves sideways** — the shooter walking its line forward, which is the thing a
relative path cannot promise because its heights would depend on how long the descent leg was.
On `enemy-shooter`: first hold at **y = 216.5, t = 1.20 s to 3.70 s**; second hold at **y = 166.5,
t = 4.95 s to 7.45 s**; then left at 70 u/s, off the left edge and removed at **10.86 s**, 9.03 s on
screen and **5.0 of them motionless**.

**The 216.5 and 166.5 are the radius offset, not an error** — the waypoints say 210 and 160, and the
shooter is born 6.5 above the top edge, so every authored `y` is flown at `y + radius`. On a different
archetype the same entry holds at different heights; that is the documented limit of what "absolute"
means here.

**`atX 0.50` is required**, from `entryX 104 / 208`. Task 2's check (#300) agrees: it is placed at
`atX 0.50` in `test-shooter-family` and the generator reports no finding.

### `enemy-rush` — the committed-strike family

**10. `plunge` — `constant`, `vx 0`, `vy -130`.** Straight down, faster than anything else in the
file, gone before it can be aimed at twice. On `enemy-rush` (radius 4, spawn `(62.4, 274)` at
`atX 0.30`): **2.14 s** on screen, removed at **3.13 s**.

**11. `plunge-harder` — `{ "speedOf": "plunge", "multiplier": 1.35 }`.** *Not a fourth movement* —
`speedOf` is the same geometry walked sooner, so this is `plunge` at 175.5 u/s: **1.58 s** on screen,
removed at **2.32 s**. It exists so a late beat can raise pressure without adding a shape the player
has to learn, which is exactly what the form is for.

**12. `plunge-and-cut-left` — `path`, `[{0, -120, 1.6}, {-105, -10, 3.0}]`.** A plunge that changes
its mind: straight down at 120 for 1.6 s, then a near-right-angle **hard left at 105 u/s** that takes
it off the side rather than out of the bottom. From `atX 0.75` (x 156): the corner is at
**(156, 82)** at **t = 1.60 s**; it crosses the whole remaining width and is removed at **4.35 s**,
3.12 s on screen. The turn happens level with the player, which is what makes it read as a strike
rather than a fall.

**13. `plunge-and-cut-right` — `{ "mirrorOf": "plunge-and-cut-left" }`.** From `atX 0.25`: corner at
(52, 82) at t = 1.60 s, removed at 4.35 s.

**Their `atX` window:** the sideways leg is longer than the screen, so the only constraint is that
there is screen left to cross — the left-cutting one wants **`atX >= 0.5`** and its mirror
**`atX <= 0.5`**, or the turn is off screen almost immediately.

**14. `strike-and-withdraw` — `path`, `[{0, -115, 2.0}, {wait 0.6}, {0, 85, 5.0}]`.** The one shape in
the vocabulary that **leaves through the top**: it dives nearly to the player's own height, stops for
six tenths of a second, and climbs back out the way it came. From `atX 0.50`: bottoms out at
**y = 44.0** at **t = 2.00 s**, holds that exact height until **t = 2.60 s**, climbs at 85 u/s and is
removed through the top at **6.81 s**, 5.31 s on screen. The wait is what makes the reversal read as a
decision rather than a glitch, and the retreat is slower than the dive so it stays shootable on the
way out. `x` never changes, so it works at any `atX`.

### `enemy-tank` — the grinding family

**15. `grind-down` — `constant`, `vx 0`, `vy -11`.** A wall descending at walking pace. On
`enemy-tank` (radius 10.5, spawn `(104, 280.5)` at `atX 0.50`): **26.45 s** on screen, removed at
**38.09 s**. **This outlives any wave that places it** — a tank at `grind-down` will still be on
screen two or three waves later unless it is killed, and that is the point of it and a real pacing
consequence for task 6.

**16. `grind-and-wheel-left` — `path`, `[{0, -14, 4.0}, {-26, -4, 9.0}]`.** It comes straight down for
four seconds, then **wheels into a shallow leftward drift** it never leaves: from `atX 0.85`
(x 176.8) the turn is at **y = 224.5** at **t = 4.00 s**, and it crosses the full width almost level,
descending only 4 u/s while it does — on screen **11.20 s**, removed at **16.13 s**, having dropped no
lower than **y = 176**. It is a moving ceiling: it never comes near the player and it takes half the
top of the screen away for eleven seconds.

**17. `grind-and-wheel-right` — `{ "mirrorOf": "grind-and-wheel-left" }`.** From `atX 0.15`: turn at
(31.2, 224.5), sweeping right to x 218.5, removed at 16.13 s.

**Their `atX` window:** the wheel crosses more than the screen's width, so it must **spawn on the side
it wheels away from** — `grind-and-wheel-left` at **`atX >= 0.75`**, its mirror at **`atX <= 0.25`** —
the same rule the veers have, for the same reason.

### `enemy-carrier` — the arrive-and-park family

The one arithmetic constraint in this file that is not taste: `enemy-carrier`'s `spawner` has
`interval 3.0` and `Spawner`'s timer starts at `interval`, so the **first** child arrives 3.0 s after
the carrier spawns and one every 3.0 s after that. Both shapes below are built to that number.

**18. `descend-and-anchor` — `path`, `[{0, -38, 2.2}, {wait 14.0}, {0, -30, 10.0}]`.** It comes in,
**stops, and stays**. On `enemy-carrier` (radius 15, spawn `(104, 285)` at `atX 0.50`): motionless at
**y = 201.4 from t = 2.20 s to t = 16.20 s**, then falls out; **23.41 s** on screen, removed at
**27.68 s**. **Five children arrive while it is parked** (t = 3, 6, 9, 12, 15) and two more before it
leaves — its mechanism happens seven times over, against the one child a four-second shape would give.
**Counted to the moment it leaves the playfield, not to its later safety-box removal**; counting to
removal gives nine. The distinction matters because only the first is time the player can act on.

**19. `anchor-and-traverse-left` — `path`,
`[{0, -34, 2.4}, {wait 6.0}, {-22, 0, 5.0}, {wait 4.0}, {0, -28, 10.0}]`.** Park, **traverse, park
again**, then leave. From `atX 0.80` (x 166.4): stops at **y = 203.4 at t = 2.40 s**; slides left at
22 u/s from **t = 8.40 s to t = 13.40 s**, ending at **x = 56.4**; stands still again until
**t = 17.40 s**; falls out, removed at **29.77 s**, **25.20 s** on screen. The traverse is slow enough
to be a repositioning rather than a movement, and it changes which column the children fall into
halfway through — eight children over its life.

**20. `anchor-and-traverse-right` — `{ "mirrorOf": "anchor-and-traverse-left" }`.** From `atX 0.20`:
parks at (41.6, 203.4), traverses to **x = 151.6**, removed at 29.77 s.

**Their `atX` window:** the traverse is 110 units, so `single` needs `atX >= (110 + 15)/208 = 0.61`
for the left version and `<= 0.39` for the mirror. `descend-and-anchor` has no horizontal component
and no window beyond the formation's own width.

## What happens to the old entries — kept, and why

**The seven entries from 11c stay in the file, unchanged, in this task.** Deleting them here would
break the game: `assets/data/enemies.json` names `slow-descent`, `swoop`, `dive` and `crawl` as four
archetypes' default `motion.trajectory`, and `waves.json`'s level-1 waves name `strike-run`,
`veer-left` and `veer-right` in seven `trajectory` overrides. This task is required to change nothing
the player currently plays, and `docs/levels/level-01.md` is `unchanged` because of it.

**They should be deleted in task 6, not kept**, once level 1 no longer references them and
`enemies.json`'s defaults have been repointed at the new vocabulary. Keeping seven shapes nothing
flies would leave a file where a designer cannot tell the language from its history — and the phase's
own stated failure mode is a bigger file rather than a better level. Task 6 must also update
`docs/plan/11c-movement-shapes/shape-catalogue.md`, which names all seven by hand.

**The twelve from 11i and 11j stay permanently.** They are test material by the owner's decision, ten
scenarios point at them, and they cost nothing.

## The scenarios

One per archetype family — **six, not twenty** — because the claim this task makes is a claim about
families, and a family can only be looked at with its members side by side. Every one of the twenty
entries appears in exactly one scenario, and each mirror appears in the same scenario as its original,
per 11i's rule.

| Level file | Wave | What it shows |
|---|---|---|
| `test-110-basic-family.json` | `test-basic-family` | `settle-descent` centre, `descend-and-step-left`/`-right` either side — the step, and that it mirrors |
| `test-120-light-family.json` | `test-light-family` | `cut-across-left`/`-right` crossing in the middle, then `dive-across-left`/`-right` steepening |
| `test-130-shooter-family.json` | `test-shooter-family` | `descend-hold-descend` at `atX 0.25` beside `advance-the-firing-line` at `atX 0.50` — one hold against two |
| `test-140-rush-family.json` | `test-rush-family` | `plunge` beside `plunge-harder`, then both cuts, then `strike-and-withdraw` leaving through the top |
| `test-150-tank-family.json` | `test-tank-family` | `grind-down` centre with both wheels turning away from it |
| `test-160-carrier-family.json` | `test-carrier-family` | all three carrier shapes parked at once, children falling — 30 s, long enough to see the traverse |

**Every wave is `fixedDuration`, so no scenario depends on whether the shape was shot down.** The
durations are sized to show the shape, not to outlast every entity: `test-150-tank-family` runs 20 s
against a `grind-down` that is on screen for 26.45, deliberately — a tank's screen time is the thing
being demonstrated and waiting 38 s for it to be removed shows nothing more.

**The numbering:** 110 to 160, above `test-100-cross`, because `TestScenarios.rankOf` sorts by the
`NNN` in the filename descending and a new scenario must come out on top.

## Nothing here needed a fourth kind of trajectory

Every shape wanted was sayable with `constant`, `arc` and `path`. Two things were checked against and
did not bite: [#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280) (a loop is always a
path's tail) was never reached, because no shape in this vocabulary repeats — the carrier's
park-traverse-park is three distinct legs, not a loop, and writing it as one would have required the
exit to be inside the repeated range. And no shape wanted a curve `arc` cannot give: the only curved
entry, `dive-across-left`, is an `arc` with a negative `ay`, which is the same closed form used in the
one direction the file had never used it.

## Verification

- **Every entry loads through the real loader.** A throwaway `main` constructed
  `new JsonContentSource(new FileHandle(new File("assets/data")), id)` for `level-01` and for all six
  new scenario ids in one run; all seven loaded — `level-01` reporting its 12 placements and each
  scenario 1 — and the same program then resolved all twenty new entries by id through
  `source.trajectory(...)` and integrated them at 1/400 s from their real spawn points. Every number
  in "What each one is meant to look like" is that program's output.
- **`node tools/build-level-docs.js` run and its output committed.** It printed
  `unchanged docs/levels/level-01.md` and `updated docs/levels/waves.md`, and reported **no findings**
  — including task 2's new absolute-`atX` check, which is the one that would fire on
  `advance-the-firing-line`. Note that the generator's geometry checks run inside `buildLevel` and so
  only cover waves a `level-NN.json` places; the six new waves are `unplaced` and are **not** checked
  by it. The `atX` windows above are this task's own arithmetic and task 6 is what will put them under
  the generator.
- **`./gradlew build`** — see the pull request.
- **CI** — `gh run list` checked on this branch before review; see the pull request.
- **Whether the shapes read right on screen: not checked, and the project owner's.** The game was not
  launched for this task. What is worth opening from the TESTS menu, in order: **CARRIER FAMILY**
  (does a parked carrier read as a factory or as a stalled enemy?), **TANK FAMILY** (`grind-and-wheel`
  takes the top of the screen away for eleven seconds — is that oppressive or boring?), and **RUSH
  FAMILY** (`strike-and-withdraw` leaves through the top; does the 0.6 s stop read as a decision?).

## What task 6 inherits from this

- Delete the seven 11c entries and repoint `enemies.json`'s four defaults; update the catalogue's
  "What points at what".
- **An absolute path cannot be placed in a multi-slot formation.** `advance-the-firing-line` is
  `atX 0.50`, `formation: single`, once.
- **`grind-down` outlives its wave by a wide margin** (26 s on screen). Two of them in one wave is a
  decision about the next wave, not about that one.
- The `atX` windows above are per shape and per formation; the widest constraints are
  `grind-and-wheel-*` (spawn on the side it wheels away from) and `dive-across-*` (0.53 / 0.47).

## Corrected by the coordinator after review, before merge

`reviewer` accepted this branch and found one arithmetic slip. The correction is the coordinator's
because the worker was already closed. **Prose only — no JSON changed, and no claim about a family,
a kind or a rule is affected.**

**`dive-across-left`'s `atX` window was rounded the wrong way.** With this file's own drift (106.1)
and radius (4.5), `(106.1 + 4.5) / 208 = 0.5317`, so the minimum is **0.53**, not 0.54, and the
mirror's is **0.47 or less**, not 0.46. `reviewer` re-derived it independently by closed-form
root-finding and got `atX_min = 0.5321`. Corrected in both places it appears.

**Every other `atX` window in this file reproduced exactly** — `descend-and-step-left` 0.25/0.34,
`grind-and-wheel-left` 0.75, `anchor-and-traverse-left` 0.61/0.39 — so the slip is isolated rather
than a systematic error in how the windows were derived.

**The carrier's child count now states which clock it counts against.** Seven and eight are counted
to the moment the carrier leaves the playfield, not to its later safety-box removal, which would give
nine and more. `reviewer` reproduced both numbers exactly under that convention and could not under
the other, and the convention was not written down for this claim. It is the right one — a child that
arrives after its parent is off screen is not pressure the player experiences — but task 6 will read
these numbers and needed it said.
