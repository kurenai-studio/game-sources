# 278 — an oscillating loop: the shape the project owner actually drew

**Branch:** `feat/oscillating-path`. **Closes:** [#278](https://github.com/LuchoC-Dev/little-spaceship/issues/278).
`level-designer`, on `assets/data/` only.

## What shipped

One trajectory entry, one wave, one scenario file. One, not a set — the circuit is the same question
answered twice, and the issue said so.

- `descend-and-oscillate` in `assets/data/trajectories.json`
- wave `test-path-oscillate` in `assets/data/waves.json` (appended; no existing entry touched)
- `assets/data/test-path-oscillate.json`, one placement

```json
{
  "id": "descend-and-oscillate",
  "type": "path",
  "segments": [
    { "vx": 0,   "vy": -55, "duration": 2.0 },
    { "vx": 60,  "vy": 0,   "duration": 0.5 },
    { "vx": -60, "vy": 0,   "duration": 1.0 },
    { "vx": 60,  "vy": 0,   "duration": 1.0 }
  ],
  "loopStart": 2,
  "loopCount": 3
}
```

It rides `enemy-tank`, `formation: single`, exactly like the other four — 200 health, `fragile: false`
and the largest non-boss radius (10.5), so the shape survives being shot at and is easy to follow.
The variable under test is still only the movement.

## What it is meant to look like

Spawn geometry, so this is checkable: `SpawnSystem.positionSpawned` puts a `single` slot at
`y = 270 + radius`, so an `enemy-tank` starts at **y ~ 280.5**, and `x = atX * 208`. The scenario
spawns it at `atX 0.50`, i.e. **x = 104**, dead centre.

**Meant to look like:** it comes straight down the middle for two seconds, stops descending a little
above the middle of the screen, and then **slides side to side at that one height** — right, left,
right, left — six crossings in all, each about a body-and-a-half wide, always returning through the
column it came down. It never gets any lower while it does this. Then, the count spent, it stops
turning back and keeps going right, out through the right-hand edge.

**It leaves sideways, and that is a decision.** A loop range in `PathTrajectoryDefinition` always runs
to the end of the segment list (`loopStart` marks a *trailing* range; nothing can follow it —
`PathTrajectoryDefinition.segmentAt`), so the exit is always the last segment extrapolated. The last
segment of a level oscillation is horizontal by construction: giving it a downward exit would mean a
downward component inside the loop, which is a staircase again and is precisely what this entry exists
not to be. **Exiting through the side is what a non-advancing loop costs, and it is cheap** — the unit
still leaves unattended, in finite time, which is the rule.

### Per-iteration drift: exactly zero, on both axes

One iteration of the loop range is `{-60, 0, 1.0 s}` then `{+60, 0, 1.0 s}`: **-60 + 60 = 0 px
horizontally, 0 px vertically.** Not "near zero" — zero, and zero by the same arithmetic every
repeat, because both legs share one speed and one duration. Compare `stair-descent`, which moves 36
left and 36 down per iteration.

The 0.5 s lead-in leg (`+60` for half a second, i.e. +30) exists to centre the swing: without it the
unit would only ever be left of its spawn column. With it, the oscillation runs between **x0 - 30 and
x0 + 30**, symmetric about the column it descended in.

### Arithmetic, accumulated from the JSON durations

Segment `duration`s, added in order — the mistake the previous fragment made and the coordinator
corrected on 04/09/2026:

| t | what |
|---|---|
| 0.0 – 2.0 | descends at 55/s: y 280.5 → **170.5** |
| 2.0 – 2.5 | lead-in right, +30: x 104 → 134 |
| 2.5 – 4.5 | repeat 1: to x 74, back to x 134 |
| 4.5 – 6.5 | repeat 2: identical |
| 6.5 – 8.5 | repeat 3: identical |
| 8.5 onward | last segment held, `vx = +60`: fully off the right edge (x > 218.5) at **t ~ 9.91**, out of the safety box (x > 336) at **t ~ 11.87** |

y is 170.5 from t = 2.0 to the end and never changes again. The wave's `fixedDuration` is **13.0 s**,
which covers removal with a second to spare.

### Where it may be placed: `atX` 0.20 – 0.80

The swing reaches 30 px either side of the spawn column, and the sprite's radius is 10.5, so keeping
the whole oscillation on screen needs `x0 - 40.5 >= 0` and `x0 + 40.5 <= 208`, i.e.
**x0 in [40.5, 167.5]**, i.e. **`atX` in [0.20, 0.80]**.

**This is the first of the five paths that is a centre shape.** The other four
(`descend-and-turn-left`, its mirror, `sweep-wait-drop`, `stair-descent`) are all authored for one
side and read wrong from the other; this one is authored for the middle and reads wrong from either
edge. Near `atX 0.80` the exit tail is also almost nothing, since it is already at the right edge when
the loop ends — another reason 0.50 is what the scenario uses.

## The TESTS menu entry is still missing

**Scenario id: `test-path-oscillate`.** Suggested label, matching the four already there:

```java
new Scenario("test-path-oscillate", "PATH: OSCILLATE")
```

The list is hardcoded in
`game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestScenarios.java`, which is
`game-presentation`'s file and forbidden to this task. **Until the coordinator adds that line the
content loads and is correct but cannot be reached from the menu** — and reaching it is the entire
point of the task, since only the project owner may watch it.

## Verified

- **Everything loads through the real parser.** A throwaway `OscCheck` main compiled against
  `core.jar`, `game.jar` and `gdx-1.14.2.jar`, constructing a real `JsonContentSource` over
  `assets/data` once per level id, printed:

  ```
  level-01 OK placements=[WavePlacement[waveId=l1-opening-calm, offsetSeconds=0.0], ... ]
  test-wave-04 OK placements=[WavePlacement[waveId=l1-combined-formations, offsetSeconds=0.0]]
  test-wave-09 OK placements=[WavePlacement[waveId=l1-high-pressure, offsetSeconds=0.0]]
  test-wave-12 OK placements=[WavePlacement[waveId=l1-final-escalation, offsetSeconds=0.0]]
  test-boss OK placements=[]
  test-path-turn OK placements=[WavePlacement[waveId=test-path-turn, offsetSeconds=0.0]]
  test-path-mirror OK placements=[WavePlacement[waveId=test-path-mirror, offsetSeconds=0.0]]
  test-path-wait OK placements=[WavePlacement[waveId=test-path-wait, offsetSeconds=0.0]]
  test-path-loop OK placements=[WavePlacement[waveId=test-path-loop, offsetSeconds=0.0]]
  test-path-oscillate OK placements=[WavePlacement[waveId=test-path-oscillate, offsetSeconds=0.0]]
  --- PathTrajectoryDefinition[id=descend-and-oscillate, segments=[PathSegment[vx=0.0, vy=-55.0,
      duration=2.0], PathSegment[vx=60.0, vy=0.0, duration=0.5], PathSegment[vx=-60.0, vy=0.0,
      duration=1.0], PathSegment[vx=60.0, vy=0.0, duration=1.0]], loopStart=2, loopCount=3]
  ```

- **The zero drift is the integrated output, not hand arithmetic.** The same run stepped
  `horizontalVelocityAt`/`verticalVelocityAt` — the exact two methods `MotionSystem` reads — at
  1/100 s and printed the accumulated displacement every quarter second:

  ```
  t=2,00 dx=0,00    dy=-110,00
  t=2,50 dx=30,00   dy=-110,00
  t=3,50 dx=-30,00  dy=-110,00
  t=4,50 dx=30,00   dy=-110,00
  t=5,50 dx=-30,00  dy=-110,00
  t=6,50 dx=30,00   dy=-110,00
  t=7,50 dx=-30,00  dy=-110,00
  t=8,50 dx=30,00   dy=-110,00
  t=9,00 dx=60,00   dy=-110,00
  t=11,50 dx=210,00 dy=-110,00
  ```

  `dy` is -110.00 from t = 2.00 to the end of the run at t = 14.00 — **the loop takes it nowhere
  vertically** — and `dx` returns to +30.00 at 4.50, 6.50 and 8.50, the three repeat boundaries: the
  same value each time, which is the zero drift stated above. From 8.50 `dx` climbs steadily, the
  extrapolated exit. (The decimal comma is the JVM's Spanish locale in `printf`, not a thousands
  separator.)

- **`./gradlew build`** — `BUILD SUCCESSFUL`, full repo.

- **`node tools/build-level-docs.js`** printed `unchanged docs/levels/level-01.md` and
  `updated docs/levels/waves.md`; the regenerated file is committed here. Its whole diff is one row,
  `| test-path-oscillate | 13.0 s | 1 | 1 | enemy-tank | **unplaced** |`, which is accurate — no
  level places it, exactly like the other four scenario waves.

- **Level 1 and the existing entries untouched.** `git status --porcelain` lists neither
  `assets/data/level-01.json` nor `assets/data/formations.json`; the `trajectories.json` and
  `waves.json` diffs are additions only, no existing line changed. `game/` not touched.

- **`./gradlew :desktop:run -Ptests`** launched, reached `> Task :desktop:run`, printed only the known
  LWJGL/JNI and `sun.misc.Unsafe` warnings and no exception, and was then killed with
  `taskkill /F /IM java.exe`. That is "launch once to confirm it starts".

- **Not checked: how the oscillation looks.** It was not played, and it cannot be reached from the
  menu until the line above is added. Every sentence under "What it is meant to look like" is derived
  from the integrated velocities. **A path that reads differently from that description is the finding
  this task exists to make possible**, and only the project owner can make it.

- **Not checked:** whether three repeats is the right count, whether ±30 px is a wide enough swing to
  read as an oscillation rather than a wobble, and whether 55/s is the right descent. All three are
  judgments about how it feels; all three are one number each in the JSON once someone has looked.
