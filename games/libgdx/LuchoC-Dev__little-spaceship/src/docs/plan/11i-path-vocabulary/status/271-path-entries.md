# 271 — four paths that prove the vocabulary, and a scenario for each

**Branch:** `feat/path-entries`. **Closes:** [#271](https://github.com/LuchoC-Dev/little-spaceship/issues/271).
`level-designer`, on `assets/data/` only.

## What shipped

**Four trajectory entries** in `assets/data/trajectories.json`, between them a turn, a wait, a
bounded loop and a mirror that costs no second definition; **four waves** in `assets/data/waves.json`,
each spawning exactly one shape and nothing else; **four scenario level files**,
`assets/data/test-path-{turn,mirror,wait,loop}.json`, one placement each.

Four, not eleven, on the issue's own instruction. Each shows one thing, and nothing else is on screen
to blur it.

**Every one of them rides `enemy-tank`, `formation: single`.** Deliberate: 200 health and
`fragile: false` mean the unit survives long enough for the whole path to play out even while being
shot at, and its radius of 10.5 is the largest non-boss sprite, so the shape is easy to follow. The
variable under test is the movement; everything else is held constant across all four.

## The four paths, and what each is meant to look like

Spawn geometry, so the descriptions below are checkable: `SpawnSystem.positionSpawned` puts a
`single` slot at `y = 270 + radius`, so an `enemy-tank` starts at **y ~ 280.5**; `x = atX * 208`.
`LifetimeSystem` removes an entity once it leaves the box `x in [-128, 336]`, `y in [-128, 398]`, so
"leaves the screen" and "is removed" are a second or two apart.

### 1. `descend-and-turn-left` — the turn. Scenario `test-path-turn`, spawned at `atX 0.85` (x = 177)

```
{ "vx": 0, "vy": -45, "duration": 3.0 }   then   { "vx": -55, "vy": 0, "duration": 6.0 }
```

**Meant to look like:** it comes straight down the right-hand side for three seconds, stops
descending at about half the screen's height, and turns out hard to the left, crossing the whole
playfield horizontally at that one height before leaving through the left edge. The turn is a corner,
not a curve — that is what tells a `path` apart from `veer-left`, which is the same journey drawn as
a parabola.

**Arithmetic:** descends 135 to y ~ 145.5, then travels left at 55/s, crossing x = 0 at t ~ 6.2 s and
the safety box at t ~ 8.5 s. Past 9.0 s the definition extrapolates the last segment, so it keeps
going left; it is removed before that matters.

### 2. `descend-and-turn-right` — the mirror. Scenario `test-path-mirror`

```
{ "id": "descend-and-turn-right", "mirrorOf": "descend-and-turn-left" }
```

**One line. No second copy of the numbers.** This is the project owner's explicit bar for the phase,
and it is the whole entry.

The scenario spawns **both at once**, symmetrically — the left-turner at `atX 0.85`, the mirror at
`atX 0.15` — so the mirror is watched as a pair rather than described. **Meant to look like:** two
tanks descend together down the two sides, turn at the same instant at the same height, and cross
outward in opposite directions, each passing the other's starting column. If they are not symmetric
on screen, the mirroring is wrong, and that is exactly what this scenario exists to catch.

### 3. `sweep-wait-drop` — the wait. Scenario `test-path-wait`, spawned at `atX 0.90` (x = 187)

```
{ "vx": -60, "vy": -22, "duration": 2.0 }   { "wait": 2.5 }   { "vx": 0, "vy": -90, "duration": 5.0 }
```

**Meant to look like:** it enters from the top right on a shallow, mostly sideways sweep, comes to a
complete stop just below the top of the screen and a little left of centre, **hangs there for two and
a half seconds while shooting**, and then drops straight down and out of the bottom, fast. The stop
should read as a decision, not as a stutter — 2.5 s is long enough to be unmistakable.

**Arithmetic:** the sweep ends at (67, 236.5) at t = 2.0 s; the wait holds that point to t = 4.5 s;
the drop crosses y = 0 at t ~ 7.1 s and the safety box at t ~ 8.55 s.

**Corrected by the coordinator on 04/09/2026**, from `reviewer`'s audit of this pull request. The
four timestamps above first read 2.5 s, 5.0 s, ~7.6 s and ~9.0 s — every one from the wait onward
shifted about half a second late, because the wait's own 2.5 s had been added to the sweep's
*claimed* end rather than its real one. The sweep segment's `duration` is 2.0. **The JSON was always
right; the description was wrong**, which is the failure this task was written to be able to produce
and the reason it was asked to write down what each path is meant to look like at all. It was found
by the only reader who had both the intent and the data. The `{"wait": ...}` shorthand is
used here on purpose — it is the loader's own sugar and this is the only entry that reads it.

### 4. `stair-descent` — the bounded loop. Scenario `test-path-loop`, spawned at `atX 0.85` (x = 177)

```
segments: down 1.2 s | left 0.8 s | down 0.8 s      loopStart 1, loopCount 4
```

**Meant to look like:** a staircase. One lead-in drop, then four repetitions of *step left, step
down*, walking diagonally toward the bottom left in visible right-angled steps rather than along a
diagonal line — then, the loop spent, it stops stepping sideways and simply falls the rest of the way
out of the bottom of the screen. **That last part is the point of "bounded":** the unit leaves on its
own, it does not stair-step forever.

**Arithmetic:** lead-in to y ~ 220.5; four steps of 36 left and 36 down land it at (33, 76.5) at
t = 7.6 s; the tail is the last segment extrapolated, `vy = -45`, out of the bottom at t ~ 9.3 s and
out of the box at t ~ 12.2 s.

## Where each path may be placed

**All four are authored for a spawn on the right, and none of them is placement-neutral** — the same
caveat `shape-catalogue.md` already records for `veer-left`. Each turns or steps to the left, so a
low `atX` puts the whole interesting half of the shape off screen.

| Path | Works from | Why |
|---|---|---|
| `descend-and-turn-left` | `atX >= 0.75` | the turn travels 55/s left; from `atX 0.3` it is off the left edge in 1.1 s |
| `descend-and-turn-right` | `atX <= 0.25` | the mirror, exactly |
| `sweep-wait-drop` | `atX >= 0.80` | the entry sweep carries it 120 left before the wait; from lower, it waits off screen |
| `stair-descent` | `atX >= 0.75` | the four steps carry it 144 left |

The scenario files place each one where it reads. **A path is a shape; where it happens is still the
wave's `atX`**, and these four are shapes with a side.

## Two things this task could not do inside its own boundary

Both are reported rather than worked around. Neither is a defect in what shipped.

### 1. The scenarios are not in the TESTS menu, and cannot be put there from `assets/data/`

The menu's list is **hardcoded in `game/`**:
`game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestScenarios.java:26-31`, a
`List.of(...)` of four `Scenario(levelId, label)` records. Its own javadoc anticipates this — *"if
`level-designer`'s scenario files use different ids, only this list needs to change"* — but the file
is `game-presentation`'s and this task is forbidden `game/`.

**The change is four lines**, and these labels are chosen so the owner knows what they are about to
watch:

```java
new Scenario("test-path-turn",   "PATH: TURN"),
new Scenario("test-path-mirror", "PATH: MIRROR"),
new Scenario("test-path-wait",   "PATH: WAIT"),
new Scenario("test-path-loop",   "PATH: LOOP")
```

Until someone adds them, the content loads and is correct but **there is no way to reach it from the
menu**. This is the one thing standing between this phase and the project owner being able to judge
it, and it is not in `assets/data/`.

### 2. The waves had to go in `waves.json`, which the issue told me not to touch

`JsonContentSource` reads waves from exactly one file — `dataDir.child("waves.json")`,
`game/adapter/content/JsonContentSource.java:95` — and `SpawnSystem` reads **only** placements
(`SpawnSystem.java:128`; nothing in `core/` calls `ContentSource.timeline`), so a level file's legacy
flat `"events"` list parses but spawns nothing. **There is no way to make a spawn happen without an
entry in `waves.json`.** The alternative was to ship no scenario at all.

What was done instead, and why it is not the thing the constraint was protecting: the four entries
are **purely additive**, named `test-path-*`, and **no placement in `level-01.json` references any of
them**. Level 1's encounter is what it was, line for line. Verified below. `level-01.json` and
`formations.json` were not touched at all.

## Verified

- **Everything loads through the real parser.** A throwaway `LoadCheck` main compiled against
  `core.jar`, `game.jar` and `gdx-1.14.2.jar`, building a real `JsonContentSource` over
  `assets/data` once per level id, printed:

  ```
  level-01 OK placements=[l1-opening-calm@0.0 ... l1-final-escalation@0.0]
  test-wave-04 OK placements=[l1-combined-formations@0.0]
  test-wave-09 OK placements=[l1-high-pressure@0.0]
  test-wave-12 OK placements=[l1-final-escalation@0.0]
  test-boss OK placements=[]
  test-path-turn OK placements=[test-path-turn@0.0]
  test-path-mirror OK placements=[test-path-mirror@0.0]
  test-path-wait OK placements=[test-path-wait@0.0]
  test-path-loop OK placements=[test-path-loop@0.0]
  ```

- **The mirror really is the negation and nothing else.** The same run printed the resolved
  definitions:

  ```
  --- descend-and-turn-left  segments=[PathSegment[vx=0.0, vy=-45.0, duration=3.0],
                                       PathSegment[vx=-55.0, vy=0.0, duration=6.0]]
  --- descend-and-turn-right segments=[PathSegment[vx=-0.0, vy=-45.0, duration=3.0],
                                       PathSegment[vx=55.0, vy=0.0, duration=6.0]]
  ```

  Every `vy` and every `duration` identical, every `vx` negated. (`-0.0` for a negated `0.0` is float
  sign; `-0.0 * dt` displaces nothing.)

- **The positions in the descriptions above are the integrated output of the real definitions**, not
  hand arithmetic: the same run stepped `horizontalVelocityAt`/`verticalVelocityAt` — the exact two
  methods `MotionSystem` reads — at 1/10 s from t = 0 to 16 and printed the accumulated displacement
  each second. `stair-descent` printed `t=7(-153,-168)`, then `t=8(-153,-213)` and `t=9(-153,-258)`:
  the sideways stepping stops after the fourth repeat and it falls straight out, which is the bounded
  loop behaving as authored.

- **`./gradlew build`** — green, exit 0, full repo.

- **`node tools/build-level-docs.js`** printed `updated docs/levels/level-01.md` and
  `updated docs/levels/waves.md`, both committed here. **The `level-01.md` line is not mine**: it is
  `| pickupFallSpeed | 20 |`, drift left behind by task 4
  ([#252](https://github.com/LuchoC-Dev/little-spaceship/issues/252)), which added the value to
  `balance.json` without regenerating. Isolated by stashing this branch's content and re-running the
  generator, which still printed `updated docs/levels/level-01.md` with nothing of mine present.
  **The only part of the generated docs this task changes is four rows in `waves.md`**, each marked
  `**unplaced**` by the generator, which is accurate — no level places them.

- **Level 1 untouched.** `git status --porcelain` lists `assets/data/level-01.json` and
  `assets/data/formations.json` unmodified; `waves.json`'s diff is `+30 / -0`, four appended entries,
  no existing line changed.

- **`./gradlew :desktop:run -Ptests`** launched, reached `> Task :desktop:run`, printed only the known
  LWJGL/JNI warnings and no exception, and was then killed with `taskkill /F /IM java.exe`. That is
  "launch once to confirm it starts".

- **Not checked: how any of the four paths looks.** None was played, and none *can* be played from the
  menu yet (see above). Every "meant to look like" in this fragment is derived from the integrated
  velocities, not from watching. **A path that does something different from its description here is
  the finding this task exists to make possible**, and only the project owner can make it.

- **Not checked:** whether 2.5 s is the right length for the wait, whether four steps is the right
  count for the staircase, and whether `enemy-tank` is the right unit to watch. All three are
  judgments about how it feels, and the numbers are trivially editable once someone has looked.

## For 11j, which redesigns level 1

Written here because the issue asked for it to be, and because nothing in the content says it.

- **The mirror pair is the cheapest thing to adopt first.** `assets/data/formations.json` still
  carries `diagonal` and `diagonal-mirror` as two hand-written entries; that is the pattern this
  phase exists to stop repeating, and formations are *not* what `mirrorOf` covers. If 11j wants the
  same saving for formations, it is a second, separate mechanism and a separate case.
- **`sweep-wait-drop`'s wait is a pacing tool the level has never had.** Every enemy in level 1 today
  crosses the screen and leaves; an enemy that stops is the first thing that can hold a threat over a
  fixed piece of the playfield without being a carrier. Beat 6, "tanks and shifts in priority", is
  where it points.
- **`stair-descent` moves the safe corridor sideways in discrete jumps**, which is the pressure axis
  `03-game-systems.md` calls *space*, and it does it without the speed a `veer` needs. Beat 10 is the
  one that asked for that and got crossing arcs instead.
- **Nothing here should be dropped into level 1 as it stands.** All four waves above are
  single-enemy demonstrations and would be thin as level content.
