# Task 4 — Redesign the boss's attack, not its volume · status

**Issue:** [#200](https://github.com/LuchoC-Dev/little-spaceship/issues/200)
**Branch:** `feat/boss-aimed-attack`
**Module:** `core/` only — `core/src/main/java/dev/luchoc/littlespaceship/core/domain/system/BossSystem.java`
and its test.

## What changed

`BossSystem`'s fan is now aimed at the player instead of at fixed outward/inward angles, and widened
from three rays per part to five, per the suggestion in `plan.md`'s task 4.

- **`FAN_COUNT`** went 3 → 5.
- **`SPREAD_VX_RATIOS`/`SPREAD_VY_RATIO`/`SWEEP_VX_RATIOS`/`SWEEP_VY_RATIO`** — the fixed-angle
  constants the diagnosis names directly — are gone, replaced by **`FAN_SPREAD_RATIOS`**, five
  symmetric perpendicular-offset ratios (`-0.6, -0.3, 0, 0.3, 0.6`) applied around a direction computed
  at fire time, not a fixed one.
- **`lockAim(World)`** is new: called once, at the instant a pattern's tell begins (the `COOLDOWN` →
  `TELLING` transition in `updateCooldown`), it reads `world.playerEntity()`'s `Transform` and freezes
  it into `aimX`/`aimY` for that whole cycle. No player entity falls back to the playfield's horizontal
  centre at `world.content().balance().playerStartY()` — content's own value, not a hardcoded one —
  so the fixtures that omit a player (most of the existing `BossSystemTest` cases) still get a
  plausible direction instead of aiming at `(0, 0)`.
- **`fire`/`fireFan`/`fireFrom`** collapsed into `fireAimedFan`/`fireFrom`: each ray is the unit vector
  from the firing part's current position to the locked aim point, plus a multiple of its perpendicular
  (one `FAN_SPREAD_RATIOS` entry), renormalised to the pattern's fixed speed. Both spread (pods) and
  sweep (arms) now share the same fan-building method — the two patterns differ only in which parts
  fire and at what speed, not in fan shape, since aiming at the player made the previous
  outward-vs-inward asymmetry pointless to keep.

## How the tell survives — the load-bearing decision

The issue and the plan both ask this to be argued, not assumed. **The aim is locked once, at the start
of the 0.75 s tell, not re-read at the fire instant.** Concretely: `lockAim` runs inside
`updateCooldown`, the tick the state machine flips into `TELLING`; nothing reads the player's position
again for that cycle, including at the moment `fire()` actually creates projectiles several ticks
later.

That is what keeps the tell honest under an aimed attack:

- The player gets the **same 0.75 s reaction window** the un-aimed fan already gave — the tell's
  timing (`BEAT_DURATION`, `BEATS`, the sprite-frame stepping) is untouched by this change.
- The player is dodging **where they were when the charge started**, not a shot that keeps re-aiming
  at them in real time. Standing still after the tell begins is exactly as safe or unsafe as it was
  before; moving during the tell is what changes the outcome, which is the definition of a dodge
  rather than a positioning trick solved once.
- The fan is still five rays wide around that locked point, not a single hitscan-style shot, so even a
  player who freezes in place still has the same kind of gap-finding the old fan asked for — the
  difference is the gap is no longer guaranteed to include screen centre for free.

**What this does not do, and is a finding rather than a fix**: nothing in `core` signals *where* the
locked aim point is beyond the existing charge animation (`Sprite#frame` stepping 1→2→3). The tell was
already non-directional before this change — the un-aimed fan's own direction was never drawn as a
preview either — so this is not a regression this task introduces, but an aimed attack makes the
question sharper than a fixed-angle one did. If the play session in task 5 finds the tell unreadable
specifically because the aim direction is invisible, the fix is a rendering change (a telegraph line,
or an aim indicator on the charging pod/arm sprite) and belongs to `game-presentation`, not to this
branch — reported here rather than implemented, per this task's own boundary.

## Determinism

- `lockAim` reads `world.playerEntity()`/`world.transforms()` — a `World` read, explicitly called out
  as legitimate in the issue — through the same fixed step (`BossSystem.update(World, float step,
  InputFrame)`) every other system already runs under. No clock, no direct input.
- The fan geometry uses only addition, multiplication and `Math.sqrt` to renormalise — never
  `Math.sin`/`cos` — for the reason the removed javadoc already stated: a transcendental function is
  not guaranteed to produce the identical float on the JVM and under TeaVM, and a replay cannot afford
  that. `Math.sqrt` is IEEE-754 exact and already used the same way in `MotionSystem`'s velocity cap,
  so it carries no equivalent risk. Not a new precedent, an existing one reused.
- No `Math.random()`, no `Thread`, nothing time-of-day.

## Tests

- `BossSystemTest.volleyFansThreeRaysPerSideAndAlternatesPattern` — the test asserting the *old*
  fixed-angle rule (exact `vx` magnitudes matching `SPREAD_VX_RATIOS`/`SWEEP_VX_RATIOS`) is gone,
  because the rule it asserted no longer holds; this is exactly the "a test changed because a rule
  changed" case both the plan and `CLAUDE.md` ask to be written down here rather than silently edited.
- Replaced with two tests:
  - `volleyFansFiveRaysPerSideAndAlternatesPattern` — asserts a volley is ten projectiles (five per
    firing part) and every ray travels at exactly the pattern's fixed speed (`180f`/`160f` in this
    fixture), since the aimed fan spreads direction, never magnitude.
  - `volleyAimsAtThePlayerLockedAtTellStart` — places a player, lets the tell begin (locking aim at the
    player's position), then moves the player far away *before* the volley actually fires, and asserts
    the fan still points at the frozen position rather than the live one. This is the test that
    actually exercises the "locked, not tracked" decision the tell's honesty rests on.
- Ran `./gradlew :core:test` (full suite, not just this file) — **BUILD SUCCESSFUL**, all existing
  tests green including `DeterminismRulesTest` and the rest of the 11a rule-asserting suite. No other
  test referenced the removed constants or the old fan shape.

## What the plan did not specify, decided here

- **Fan width chosen as exactly five**, per the plan's own "suggested and not mandated" wording — not
  weighed against a different count, since the issue frames five as the concrete number to try and the
  verdict is task 5's.
- **The perpendicular-offset ratios (`-0.6, -0.3, 0, 0.3, 0.6`)** are a new design constant with no
  precedent in content or in the previous fan; chosen for symmetry around the aim point and to keep the
  centre ray exact. Not tuned by play — that is exactly what task 5 is for, and this is flagged there.
- **Both patterns share one fan-building method** rather than keeping spread and sweep as separately
  shaped attacks. This was not asked for explicitly, but follows from aiming at the player: the
  previous asymmetry (spread fans outward from each pod, sweep converges inward from each arm) existed
  only to relate to a *fixed* direction, and there is no fixed direction left to be asymmetric about.
  If task 5's session finds the two patterns now read as too similar — same fan shape, different parts
  and speed — that is worth raising back to `docs/planning/08-decisions-and-open-items.md`, since "two
  alternating patterns" is the decided rule and this change narrows what makes them feel like two.

## For the play session (task 5) — what to look for specifically

Beyond the plan's own question 2 ("does the boss at `patternCooldown 0.7` feel like a boss — and after
task 4's change, is the tell still honest?"):

- Does standing still now actually cost a life, where parking at centre previously never did?
- Does the tell give enough visual warning to move, given the aim point itself is not drawn — see "What
  this does not do" above?
- Do spread and sweep still feel like two different patterns, now that both fan around an aimed
  direction rather than one fanning outward and the other inward?
