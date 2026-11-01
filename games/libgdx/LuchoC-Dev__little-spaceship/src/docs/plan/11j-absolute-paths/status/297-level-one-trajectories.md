# 297 — the trajectories level 1 will be rebuilt from

**Branch:** `content/level-one-trajectories`. **Closes:** [#297](https://github.com/LuchoC-Dev/little-spaceship/issues/297).
`level-designer`, on `assets/data/` only, plus the generated `docs/levels/waves.md` and this fragment.

## What shipped

**Seven entries** appended to `assets/data/trajectories.json` — five authored shapes and two
`mirrorOf` lines. **Five waves** appended to `assets/data/waves.json`, all `test-` prefixed and
therefore `unplaced`. **Five scenario level files**, `assets/data/test-{cross,slide-descend,dive-retreat,hold-line,sweep-width}.json`.

**Nothing was deleted and level 1 was not touched.** `node tools/build-level-docs.js` reports
`unchanged docs/levels/level-01.md`, which is the mechanical proof of it: the generator reads
`level-01.json`, `waves.json`, `trajectories.json`, `enemies.json`, `formations.json`,
`attachments.json` and `balance.json`, and every number it prints for level 1 came out identical.
Only `docs/levels/waves.md` changed, by five added rows in the library table.

## Why seven, and what the number is for

**One entry per capability the existing twelve cannot express — not one per beat.** 11k picks from
this; it is a vocabulary, and a vocabulary is judged by what it can say, not by how many words it has.
The twelve entries already cover descent at four speeds, three curves, a corner turn and its mirror,
a wait, a staircase and an oscillation. Reading the fourteen beats in
`docs/planning/04-campaign-and-levels.md` against them, five things had no way to be said:

| # | The capability that was missing | Beat it serves | Entry | Kind |
|---|---|---|---|---|
| 1 | a **straight full-width diagonal** — `swoop` is `-10/-40`, barely off vertical; nothing crosses the screen in a line | combined formations; final escalation | `cross-left` + `cross-right` | `constant` |
| 2 | **come in from a side, then straighten into a column** — the reverse order of `descend-and-turn-*`, which is what makes a mirrored pair converge instead of diverge | combined formations; tanks and shifts in priority | `slide-left-then-descend` + `slide-right-then-descend` | `path` |
| 3 | **leaving through the top** — a retreat. No shape in the game has ever exited anywhere but down or sideways | super-fast ones; high-pressure combinations | `dive-and-retreat` | `path` |
| 4 | **holding a fixed firing line and then leaving it** — an absolute height, not a height that depends on how long the descent leg happened to be | evolved basics/shooters; the difficult encounter | `hold-the-line-and-exit` | `path`, **absolute** |
| 5 | **crossing the full width at a fixed height and then dropping** — the absolute form's whole reason to exist | high-pressure combinations; final escalation | `sweep-the-width-and-drop` | `path`, **absolute** |

**Two of the five are `constant`, not `path`.** The issue's rule is that a path which could be a
`constant` should be one, and a straight diagonal is exactly that: `cross-left` is two numbers, and
writing it as a one-segment `path` would buy nothing and would make the file's `path` entries mean
less. **No new `arc`.** The three that exist are the only curved motion in the game and nothing in the
beats asked for a fourth curve; a `path` imitating one would come out a polygon.

**Nothing here is placed in a level.** That is deliberate and is what 11k is for. A trajectory no wave
outside the test scenarios selects still loads and resolves — it is not dead content, it is the
material the redesign draws on.

## Which are absolute, and what a wave placing one must do

**Two of the seven are absolute:** `hold-the-line-and-exit` and `sweep-the-width-and-drop`. The other
five are relative and work from any column, subject to the `atX` windows below.

A wave placing an absolute entry must do two things, and **nothing enforces either today**:

1. **Use `atX` equal to the first waypoint's `x` divided by 208.** `SpawnSystem.positionSpawned` puts
   the slot at `x = atX * 208` and the path only ever adds deltas to that; the entry waypoint's
   coordinates are the *authoring* origin, not a position the engine reads. So
   `hold-the-line-and-exit` (entry `x: 104`) needs `atX 0.50`, and `sweep-the-width-and-drop`
   (entry `x: 20.8`) needs `atX 0.10`. Anything else and every written coordinate is a lie by the
   same constant.
2. **Read every authored `y` as "plus the archetype's collider radius".** The same method places the
   slot at `y = 270 + radius`, so a waypoint written `y: 190` is flown at `y = 190 + radius`.
   Measured, not assumed: `hold-the-line-and-exit` on `enemy-shooter` (radius 6.5) holds at
   **y = 196.5** in the integration below, and the sweep crosses at **y = 220.5**, not 214. It is a
   small, predictable offset — but it means the absolute form is absolute in `x` and absolute
   *modulo the radius* in `y`, and whoever authors 11k should know that before writing a coordinate
   they expect to line up with something else on screen.

**I think this needs a real check, and I did not build one.** #287 argued the check and left the call
here; my answer is that a written convention is not enough — condition 1 fails silently and produces a
shape that is merely in the wrong place, which is the hardest kind of content bug to see. But the
check does not belong in `JsonContentSource`, which parses `trajectories.json` and `waves.json`
independently and has no cross-reference between them anywhere in the class. It belongs in
`tools/build-level-docs.js`, which **already reads both together** and already fails a pull request
when a spawn's swept extent leaves the playfield. Adding "a spawn whose trajectory is absolute and
whose `atX * 208` is not its entry waypoint's `x`" is the same shape of check in the same place.
`tools/` is not mine to edit. **Recommended as an issue, not built here.**

## What each one is meant to look like

Derived from the JSON by integrating `horizontalVelocityAt`/`verticalVelocityAt` at 1/100 s from the
real spawn point, not from what I meant — the numbers below are the program's output. Spawn geometry:
`x = atX * 208`, `y = 270 + radius`; `LifetimeSystem` removes an entity once it is past
`x in [-128, 336]`, `y in [-128, 398]`, so "leaves the playfield" and "is removed" are a second or two
apart. `enemy-basic` has radius 5.5, `enemy-shooter` 6.5.

### 1. `cross-left` — the straight diagonal. `constant`, `vx -45`, `vy -45`

**Meant to look like:** a single unbroken 45-degree line from the top-right corner to the left edge.
It never turns and never changes speed. From `atX 0.95` (x = 197.6, y = 275.5) it passes the middle of
the screen at **t = 2.0 s, (107, 185)**, crosses the left edge at **t = 4.51 s**, at about **y = 72** —
a quarter of the way up from the bottom, not the bottom corner. Removed at **t = 7.23 s**.

The point of it is that it is *not* a descent: it spends its whole life travelling, and a wave of them
reads as traffic crossing the lane rather than as something coming at the player.

### 2. `cross-right` — `{ "mirrorOf": "cross-left" }`

One line, `vx +45`. From `atX 0.05` (x = 10.4) it is the exact reflection: middle of the screen at
**t = 2.0 s, (101, 185)**, right edge at **t = 4.51 s**, removed at **t = 7.36 s**.

`test-cross` spawns both at once, so the two lines **cross at the centre of the screen at about
t = 2.1 s** and separate again. If they do not meet in the middle, the mirroring is wrong — that is
what the scenario is for.

### 3. `slide-left-then-descend` — the converging half. `path`

```
{ "vx": -40, "vy": -30, "duration": 2.5 }   then   { "vx": 0, "vy": -55, "duration": 8.0 }
```

**Meant to look like:** it enters near the right edge on a shallow slant, moving left much faster than
it drops, and after two and a half seconds it **snaps to vertical at a corner** and falls straight
down the rest of the way. From `atX 0.80` (x = 166.4) it reaches **(66.4, 200)** at **t = 2.5 s** — it
has moved 100 left and only 75 down — then holds x = 66.4 exactly, crossing the bottom edge at
**t = 6.24 s** and removed at **t = 8.57 s**.

It is the reverse of `descend-and-turn-left`, and that reversal is the whole reason it exists: two
mirrored copies **converge** into two parallel columns, where two mirrored `descend-and-turn-*` fly
apart. `test-slide-descend` places the pair at `atX 0.80` and `atX 0.20`; they start 125 apart and
end up falling in columns **75 apart**, at x = 66.4 and x = 141.6.

**Its `atX` window:** the leftward drift is 100, so with `formation: single` it needs
`atX >= (100 + radius)/208`, i.e. **0.51 or more** for a 5.5-radius archetype. The mirror's window is
the reflection, **0.49 or less**.

### 4. `dive-and-retreat` — the only shape that leaves through the top. `path`

```
{ "vx": 0, "vy": -95, "duration": 2.2 }   { "wait": 0.8 }   { "vx": 0, "vy": 70, "duration": 6.0 }
```

**Meant to look like:** it drops fast and straight, nearly to the player's own height, stops dead for
most of a second, and then **climbs back out the way it came** and is gone. It gives the player one
pass and one only; ignore it and it takes itself away.

From `atX 0.50` (x = 104, y = 275.5) it bottoms out at **y = 66.5** at **t = 2.2 s**, holds that exact
height until **t = 3.0 s**, then climbs at 70/s: back through its spawn height at **t = 6.0 s**, past
the top edge, removed at **t = 7.81 s**. The `x` never changes.

The wait is what makes it readable — without it the reversal looks like a rendering glitch rather
than a decision. Note the asymmetry: it goes down at 95 and up at 70, so the retreat is visibly the
slower half and stays shootable on the way out.

### 5. `hold-the-line-and-exit` — **absolute**. Requires `atX 0.50`

```
[ {x:104, y:270}, {x:104, y:190, speed:45}, {"wait":2.5}, {x:208, y:190, speed:70} ]
```

**Meant to look like:** it comes down the centre, **stops at a fixed height near the top of the
screen**, sits there long enough to be a threat rather than a passer-by, and then slides off sideways
at a noticeably higher speed than it arrived at. The height is the same every time it is used, which
is the property a relative path cannot give.

On `enemy-shooter` (radius 6.5, spawn y = 276.5): straight down 80 units at 45/s, arriving at
**y = 196.5** at **t = 1.78 s**; motionless until **t = 4.28 s**; then right at 70/s, past the right
edge at **t = 5.85 s** and removed at **t = 7.68 s**. Total 5.8 s on screen, 2.5 of them stationary.

**The 196.5 is the radius offset, not an error** — the waypoint says 190 and the shooter is born 6.5
above the top edge. See "Which are absolute" above.

### 6. `sweep-the-width-and-drop` — **absolute**. Requires `atX 0.10`

```
[ {x:20.8, y:270}, {x:20.8, y:214, speed:60}, {x:187.2, y:214, speed:55}, {x:187.2, y:0, speed:80} ]
```

**Meant to look like:** it drops just inside the left edge, turns and **crosses the entire width of
the screen at one constant height**, then turns again and drops straight out of the bottom on the far
side. Three legs, two right-angle corners, and the middle one is a wall the player has to get under or
around. It is the shape that most needs the absolute form: the crossing height is a number the
designer chose, not the by-product of a duration.

On `enemy-shooter` (spawn y = 276.5): down to **y = 220.5** at **t = 0.93 s**; right across at 55/s,
reaching x = 187.2 at **t = 3.96 s**; then straight down at 80/s, out of the bottom at **t = 6.79 s**,
removed at **t = 8.40 s**. It is on screen 6.8 seconds, three of them spent sideways.

## The scenarios, for the coordinator to wire

**Five scenarios, not seven**, and this is a deliberate reading of "a test scenario per new
trajectory": every one of the seven entries appears in a scenario, and the two mirrors appear **in the
same scenario as their originals**, because a mirror is only worth looking at beside the shape it
mirrors — that is what shows whether it is symmetric, and it is exactly what 11i's `test-path-mirror`
did. Say so if the coordinator wants seven; splitting them is two more files and two more menu rows.

| Level id | Suggested label | What it shows |
|---|---|---|
| `test-cross` | `PATH: CROSS` | `cross-left` and `cross-right` together, crossing in the middle |
| `test-slide-descend` | `PATH: SLIDE + DESCEND` | `slide-left-then-descend` and its mirror, converging into two columns |
| `test-dive-retreat` | `PATH: DIVE + RETREAT` | `dive-and-retreat`, alone, at the centre |
| `test-hold-line` | `PATH: HOLD LINE` | `hold-the-line-and-exit`, absolute, at `atX 0.50` |
| `test-sweep-width` | `PATH: SWEEP WIDTH` | `sweep-the-width-and-drop`, absolute, at `atX 0.10` |

The labels are guesses at the house style of the nine already in `TestScenarios.java`; the coordinator
should shorten them to whatever fits.

**Every wave ends comfortably after its last entity is removed:** `test-cross` 9.0 s against 7.73,
`test-slide-descend` 10.0 against 8.97, `test-dive-retreat` 12.0 against 8.23, `test-hold-line` 10.0
against 8.09, `test-sweep-width` 11.0 against 8.81. All `fixedDuration`, none `cleared`, so a scenario
never depends on whether the shape was shot down.

**The archetypes are chosen, not defaults.** `enemy-basic` (radius 5.5, 20 health) for the three
relative shapes, because they are fast and the shape is the thing being watched; `enemy-shooter`
(radius 6.5, 30 health) for the two absolute ones, because both of them exist to establish a firing
position and a shooter is what would actually be flown on them. All `formation: single` — one unit,
one shape, nothing else on screen.

### This does change the TESTS-menu arithmetic

The list is a hardcoded stack in `game/`, it held nine entries, and this task adds five: **fourteen**,
on a screen that needed a scroll fix at nine ([#276](https://github.com/LuchoC-Dev/little-spaceship/issues/276))
and another one at its first entry ([#293](https://github.com/LuchoC-Dev/little-spaceship/issues/293)).
The three-round-trip cost measured in 11i now applies to a batch that is bigger than the list was.
**My read: discovery from `assets/data/test-*.json` is now cheaper than the alternative**, because the
alternative is that every content task keeps paying a `game/` round trip and the list keeps growing.
Not mine to build, and not mine to decide — recorded here because the issue asked whether the
arithmetic changed, and it did.

## Verification

- **Every file loads through the real loader.** A throwaway `main` constructed
  `new JsonContentSource(new FileHandle(new File("assets/data")), id)` for `level-01` and for all five
  scenario ids in one run; all six loaded, `level-01` reporting its 12 placements and each scenario 1.
  The same program then integrated all seven new shapes at 1/100 s from their real spawn points — that
  is where every timestamp in the descriptions above comes from.
- **`node tools/build-level-docs.js` run and its output committed.** It printed
  `unchanged docs/levels/level-01.md` and `updated docs/levels/waves.md`.
- **`./gradlew build`** green.
- **CI** — see the pull request; `gh run list` checked on this branch before review.
- **Whether the shapes read right on screen: not checked.** That is the project owner's verdict, per
  `docs/plan/how-to-run-a-phase.md`. The game was not launched for this task.

## Recommended follow-ups, none built here

- **An absolute path placed at the wrong `atX` should fail loudly.** The check belongs in
  `tools/build-level-docs.js`, which already reads waves and trajectories together. Argued above.
- **The TESTS list discovered from `assets/data/test-*.json`.** The arithmetic changed; see above.

## Corrected by the coordinator after review, before merge

`reviewer` accepted this branch and found seven numbers wrong in this file. The correction is the
coordinator's because the worker was already closed. **Prose only — no JSON changed, and every claim
about kind, rule 3, coverage and the absolute form's semantics survived unaltered.**

**Five "removed at t" times were early by exactly one collider radius.** `LifetimeSystem.isPastSafetyBox`
tests `transform.x + radius < -SAFETY_MARGIN`, so an entity is removed once its *edge* clears the box —
`radius` further out than its centre. The integration that produced this file applied the radius
correctly everywhere else (the spawn `y`, every edge-of-playfield crossing) and dropped it here.
`cross-left` is the clearest case: from `atX 0.95` at 45/s the centre reaches −128 at 7.236 s and the
edge reaches it at 7.358 s, and the difference times the speed is 5.5 — the radius, exactly.

| | was | now |
|---|---|---|
| `cross-left` / `cross-right` | 7.23 s | **7.36 s** |
| `slide-left-then-descend` / `-right-` | 8.47 s | **8.57 s** |
| `dive-and-retreat` | 7.73 s | **7.81 s** |
| `hold-the-line-and-exit` | 7.59 s | **7.68 s** |
| `sweep-the-width-and-drop` | 8.31 s | **8.40 s** |

**Two absolute arrival heights were short by a rounding artifact.** `hold-the-line-and-exit` arrives at
`190 + 6.5 = 196.5`, not 196.4, and the sweep crosses at `214 + 6.5 = 220.5`, not 220.1 — the file's own
stated rule ("authored `y` plus the archetype's radius") gives both, and the 1/100 s sampling landed just
short of the segment boundary. Corrected to the exact values the rule produces.

**Every corrected number is later than the one it replaces**, so the claim that each wave's
`fixedDuration` outlasts its last entity is not weakened — it had more slack than this file said, not
less.

Verified two ways: `reviewer` by closed-form algebra, and the coordinator by integrating the real
`trajectories.json`, `waves.json` and `enemies.json` at the game's own 1/60 step against
`isPastSafetyBox`'s actual condition — 7.37 / 8.58 / 7.87 / 7.70 / 8.42, agreeing with the algebra to
within a frame or two and disagreeing with every original number in the same direction.

**Why this matters more than its size**: these are precisely the numbers a level author reads to decide
how much runway a shape needs, and 11k is the phase that will read them.
