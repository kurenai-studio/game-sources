# 325 — the boss moves between the ten vertices of a star

**Branch:** `feat/boss-star-movement`. **Closes:** [#325](https://github.com/LuchoC-Dev/little-spaceship/issues/325).
`core-domain`, `core/` only: `core/src/main/java/.../domain/system/BossSystem.java` and its own test,
`BossSystemTest.java`. Does not touch `#88` (`BossSystem` stays level 1's own boss, not a boss engine).

## What was built

Once the boss settles at `combatY` and after every attack cycle from then on, it travels in a straight
line, at a fixed speed, to the next of ten fixed points arranged as a five-pointed star — never more
than three perimeter steps from the point it is leaving, exactly the owner's rule. A new `FightStage`,
`MOVING`, sits alongside the existing `COOLDOWN`/`TELLING`; `beginMove` is only ever called from the tail
of `updateTelling`, right after `fire` has run, so a move can only start once a volley has fully
resolved — never mid-tell, never mid-flight.

## The ten points, and how they were derived

Computed once, offline, with a five-line Python script — never with `sin`/`cos` inside `BossSystem`,
which is what phase 11j's refusal of curved motion under a measured TeaVM determinism constraint asks
for. The formula: a circle of outer radius 32 and inner radius `32 * sin(18°) / sin(54°) ≈ 12.223` — the
classic pentagram ratio, the one a five-pointed star traces when both kinds of vertex sit 36° apart on
the perimeter — ten vertices 36° apart starting from the top (90°), centred at (104, 200): the
playfield's own horizontal centre and a height chosen, together with the radius, to clear both edges of
the 208×270 playfield with the boss's whole six-collider extent, not merely its centre. The script and
its output:

```python
import math
cx, cy = 104.0, 200.0
R_out = 32.0
R_in = R_out * math.sin(math.radians(18)) / math.sin(math.radians(54))
for i in range(10):
    angle = math.radians(90 - 36 * i)
    r = R_out if i % 2 == 0 else R_in
    print(i, round(cx + r * math.cos(angle), 3), round(cy + r * math.sin(angle), 3))
```

```
0 104.0 232.0      1 111.184 209.889   2 134.434 209.889   3 115.625 196.223   4 122.809 174.111
5 104.0 187.777     6 85.191 174.111    7 92.375 196.223     8 73.566 209.889    9 96.816 209.889
```

The values are written as `BossSystem.STAR_X`/`STAR_Y` literal float arrays, package-visible (not
`private`) purely so `BossSystemTest` can check them by name rather than duplicating them; nothing
outside `core` sees them, and no accessor was added to any port. Odd-numbered points in the owner's
1-to-10 numbering (1, 3, 5, 7, 9 → indices 0, 2, 4, 6, 8) are the star's outer points; even-numbered ones
are the inner valleys — alternating exactly as specified.

**Extent check, against the six colliders, not the centre** (`starPointsKeepTheWholeBossOnScreen`):
the widest part is an arm (`ARM_OFFSET_X + ARM_RADIUS` = 58 either side of `coreX`); the ten points span
core-x from 73.566 to 134.434, so the arms' actual reach is 15.566 to 192.434 — inside `[0, 208]` with
about 15.6 units clear on each side. The lowest part is `core-keel` (`27 + 13` = 40 below `coreY`) and
the highest is the core or a pod (18 above); the ten points span core-y from 174.111 to 232.0, so the
keel's lowest reach is 134.111 — the owner's one hard constraint, "never close to the bottom of the
screen" — and the highest reach is 250.0, inside the 270-tall playfield.

## Selection and pacing

The destination is drawn from `world.rng()`: uniformly over all ten points for the very first move
(the boss is not yet standing on any star point — it is still at the entrance's own landing spot,
`(PLAYFIELD_WIDTH / 2, combatY)`, which the star does not claim as its own), and afterward restricted
to `{-3, -2, -1, 1, 2, 3}` steps from the current index, six legal destinations from anywhere, matching
the plan's own count. `MOVE_SPEED` (45 units/second, a footprint constant hardcoded the same way
`FAN_COUNT` and the part radii already are — not read from `BossDefinition`, since it is not a number
that varies with balancing) makes the longest *legal* hop (about 37.6 units, computed the same way as
the star points) take well under a second, and the longest hop the unrestricted first pick can produce
(about 60.9 units) take under a second and a half.

**The pause at each point is not a separate timer.** It is exactly one full attack cycle —
`patternCooldown` + the fixed 0.75 s tell — because the plan's own description ("the boss arrives,
settles, and that is when an attack begins") already describes the minimal version of this: on arrival,
`stageTimer` is set to `def.patternCooldown()` and the state machine resumes its existing
`COOLDOWN → TELLING → fire` cycle exactly as before movement existed, then calls `beginMove` again
instead of looping back to `COOLDOWN`. No new "stop duration" constant was invented. In real content
(`patternCooldown` 0.7 s) that is a ~1.45 s stand at each point; in the lighter test fixture
(`patternCooldown` 0.2 s) it is ~0.95 s. Both read, subjectively, as "a few seconds," which is the
plan's own bar.

## What happens if an attack is still resolving when a move would begin

**It cannot happen**, by construction of the state machine rather than by a guard that could be
bypassed. `MOVING` is entered from exactly one place — the last line of `updateTelling`, after `fire`
has already run — and `updateCooldown`/`updateTelling`, the only two methods that advance a tell or fire
a volley, are never called while `fightStage == MOVING` (`updateFight`'s `switch` dispatches to exactly
one of the three per tick). So a tell can never begin, continue or resolve concurrently with a move: the
boss finishes firing, then moves, then arrives, and only then starts the next cooldown. `lockAim` is
still called from exactly the same place it always was (the `COOLDOWN → TELLING` transition), so the
fan in `fireAimedFan` always aims from wherever the boss is standing still — a star point after the
first move, `(PLAYFIELD_WIDTH / 2, combatY)` for the very first volley — never from mid-flight.
`firesFromStandstillAfterMoving` in `BossSystemTest` exercises this across an actual move: it drives the
boss through its first volley, its first move, its settle, and its second volley, and asserts the core's
position at the second fire is bit-identical to where it settled, and that the second volley still aims
at the player position locked at that second tell's start rather than wherever the player has since
moved to.

## An existing test had to change, and why

`entranceDescendsToCombatY` drove 600 ticks (10 s) after the boss reached `combatY`, on the reasoning
that "a generous number of ticks... is enough to reach combatY" — true before this task, when nothing
after `combatY` ever changed the boss's position. With movement, 10 s comfortably outlasts the first
full attack cycle (0.95 s in that test's fixture) and the boss would have moved to a star point well
before the assertion runs, so the same assertion (`y == combatY` after entrance) would now be checking a
stale claim about behaviour that movement deliberately changes. Reduced to 20 ticks — enough to clear
the entrance (about 12 ticks at that fixture's `entranceSpeed` of 1000) with margin to spare below the
first cycle's 0.95 s (57 ticks), so the test still checks exactly what its name says: the entrance settles
the boss at `combatY`, nothing more. No other existing `BossSystem` test needed a change; the two
`runToNextVolley` calls in `volleyFansFiveRaysPerSideAndAlternatesPattern` fit the added
move-then-cooldown-then-tell time comfortably inside their existing 200-tick-per-call budget (computed
above: at most ~138 ticks for the slowest realistic case).

## Effect on difficulty, reported rather than compensated for

Before this task, the boss fired a volley every `patternCooldown + 0.75 s`, continuously, forever.
Now a travel segment (0.3 s to 1.4 s, depending on the hop drawn) is inserted between one volley and the
next, so **volleys fire strictly less often than before** — this is very slightly easier, not harder,
which is the direction the owner asked for if it moves at all ("sin exagerar la dificultad"). No number
in `BossDefinition` or any JSON was touched to compensate; the plan says explicitly not to.

## Acceptance criteria

- [x] Position over time is a pure function of the boss's own elapsed time and the seeded `Rng`,
  asserted by tracing it — `bossVisitsOnlyStarPointsWithinThreeSteps` and `samePatternForTheSameSeed`
  read the actual `Transform` over thousands of ticks rather than a setter.
- [x] The boss visits only the ten points, and every transition is within three perimeter steps —
  `bossVisitsOnlyStarPointsWithinThreeSteps`, which would fail if the offset table were widened to
  include ±4 or ±5.
- [x] The same seed produces the same sequence of points — `samePatternForTheSameSeed`.
- [x] The ten points and the boss's whole six-collider extent stay inside the playfield, clear of the
  bottom — `starPointsKeepTheWholeBossOnScreen`.
- [x] An attack begins from a standstill and the fan still aims at the frozen player position, including
  after a move — `firesFromStandstillAfterMoving`, plus the pre-existing
  `volleyAimsAtThePlayerLockedAtTellStart` (unmodified, still passing: it exercises only the first,
  pre-movement volley).
- [x] The existing boss tests and all five replays still pass, one test's tick budget corrected as
  described above. `./gradlew build` green.
- [x] `core` still has no libGDX on its classpath, reads no clock, calls no `Math.random()` — no new
  import was added anywhere in this change; `grep -rn "com.badlogic.gdx\|Math.random" core/src/main`
  prints nothing new.
- [ ] Whether the movement reads as dynamic rather than as harder, whether the pause length is right,
  whether the star is legible as a shape — the project owner's, not checked by this task.

## Commands run

- `./gradlew :core:test --tests "dev.luchoc.littlespaceship.core.domain.system.BossSystemTest"` — green,
  all 14 tests (10 pre-existing, one of them corrected as described above, plus 4 new).
- `./gradlew :core:test --tests "*ReplayTest"` — green, all five replay tests including
  `BossReplayTest`'s three.
- `./gradlew build` — green across every module (`core`, `game`, `web`, `desktop`, `rngparity`).

## Added by the coordinator after review, before merge

`reviewer` accepted this branch with no blocking finding. One thing is recorded here because the next
reader would otherwise assume it, and this file does not claim it either way.

**The five replay tests pass, and none of them reaches the new code.** All three `BossReplayTest`
fixtures set `patternCooldown: 1000f` — "the boss never attacks back" — or configure no boss at all,
and `LevelScoreReplayTest`'s content never calls `.withBoss(...)`. A 1000-second cooldown against a
400-tick run never lets the boss enter `TELLING`, so `fire()` and `beginMove()` never execute in any
full-pipeline replay. **Their green is true and it is not evidence about this change.**

The determinism proof lives entirely in `BossSystemTest`, whose fixture uses a real
`patternCooldown` of 0.2 s and reaches `beginMove` repeatedly — `samePatternForTheSameSeed` and
`bossVisitsOnlyStarPointsWithinThreeSteps`. `reviewer` falsified the second by widening
`STAR_STEP_OFFSETS` to include ±4 and watching it go red, so it asserts its rule rather than
observing the boss move.

**And the reason the shared `Rng` did not shift anything downstream: `BossSystem` is currently the
only production caller of `World.rng()` in `core`**, confirmed by grep. That is what makes this
branch safe, and it is also the thing that stops being true the moment a second system draws from the
stream. Whoever adds that second caller inherits this, and the replays as they stand will not catch
it.
