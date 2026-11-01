# Level 1 content mechanics — what the format actually does

Written while replacing the `level-01.json` test fixture with the real level (phase 07, feat/boss).
Everything here is behaviour of the existing pipeline that a level's pacing depends on and that is
not stated in `docs/planning/`.

## Where a formation actually lands

`SpawnSystem.spawnWave` places the whole wave off-screen by measuring only the slot with the
**lowest** `offsetY` — that slot sits tangent to the top edge at `270 + its own collider radius`, and
every other slot ends up higher by the difference. Consequences worth designing around:

- A slot's `offsetY` is not a delay in seconds, it is a head start in pixels. The gap in seconds
  between two slots of a column is `offsetY difference / trajectory vy`. A `column-3` with 22 px
  spacing arrives 1.2 s apart on `slow-descent` (-18) and 0.27 s apart on `dive` (-80). The same
  formation is a stream or a burst depending purely on which archetype uses it.
- `offsetY` **positive** means "enters later", because positive is upward.
- Horizontal footprint is `atX * 208 + offsetX ± radius`, with no clamping anywhere. Nothing stops a
  wave being written half off-screen; it just spawns there. Check every `atX` against the widest slot
  of its formation and the archetype's own radius.

## Motion is archetype data, with a per-spawn override since 11c

**Corrected 31/08/2026.** The paragraph below was true until phase 11c: a spawn entry now takes an
optional `"trajectory"` key that replaces the archetype's default
(`JsonContentSource.parseSpawnEvent`, `SpawnSystem.spawnWave` via `SpawnEvent.hasTrajectoryOverride`).
So "the same archetype enters differently at second 30 and at second 200" is content, not a code
change. `grep -c trajectory assets/data/waves.json` returned 0 on 31/08/2026 — the lever exists and
nothing uses it yet.

### What was true before 11c

`enemies.json` binds one trajectory per archetype. "A tank on the rush's trajectory is a data change"
is true only in the sense that it means editing `enemies.json` — there is no per-event trajectory
override on `SpawnEvent`. With four trajectories and six archetypes, the levers a level actually has
are formation, `atX`, timing and simultaneity. Plan the curve around those.

## Enemies despawn now, and an escaping one gives nothing

**Corrected 31/08/2026.** `LifetimeSystem` removes enemies as well as projectiles: an optional
per-archetype `Lifetime` (no archetype in `enemies.json` carries one) plus a fixed safety box 128
units past every playfield edge, and neither ever removes an enemy still visible. An escaping enemy
has its `ScoreValue`, `Drop` and `Collider` stripped before destruction, by the project owner's
decision of 28/08/2026 — so **a drop on a fast fragile archetype is lost outright if the player misses
it**, which is a real pacing lever and a real trap. The screen-time arithmetic below is unchanged and
is still the pacing lever it was.

### What was true before that

`LifetimeSystem` only expires the two projectile layers. An enemy that reaches the bottom keeps
existing and keeps moving down forever. Harmless for correctness, but it means a slow archetype's
real screen time is `(270 + radius) / |vy|` — a `crawl` enemy (-9) occupies the playfield for about
30 s. That is a pacing lever: one tank at `crawl` is still present three waves later, which is what
makes "priority shift" work without any new behaviour.

## The carrier's spawner

`Spawner.timer` starts at `interval`, so the first child appears one full interval after the carrier
does, never on spawn. Children are placed at the carrier's *current* position plus the offset, so
they can appear off-screen if the carrier is still entering — with `crawl` and a 4 s interval the
first child is comfortably visible.

Two carriers spawned by the same `SpawnEvent` share a tick, so their timers stay in lockstep for the
whole encounter: children arrive in synchronised pairs. To stagger them, they have to be two separate
events, which costs the two-slot formation and the `dropSlot` guarantee.

## The boss's geometry is decided by `combatY`

`BossSystem` bakes the spread and sweep angles as fixed ratios (spread 0.45/-0.90 outward from the
pods, sweep 0.75/-0.65 inward from the arms). Both are shallower than 45°, so every projectile leaves
through a **side** edge, never the bottom. How low it leaves is a pure function of `combatY`: a
spread shot exits the side 134 units below the core, a sweep shot 128 units below it. Set `combatY`
so those numbers land in the band the player flies in, or the boss cannot hit anything.

The core spawns at y 310 and descends to `combatY` at `entranceSpeed`, so the entrance duration is
`(310 - combatY) / entranceSpeed` — budget it inside the level's length.

The fight ends when the core dies, and `core-keel` carries the core's own health independently, so
the practical health of the "kill target" is `2 * coreHealth`, while the health bar shows the sum
across all six parts. Killing pods and arms shortens the bar without shortening the fight.

## Where the player actually is, when aiming anything at them

`balance.json` puts the player at `playerStartX 104`, `playerStartY 30`, at `playerSpeed 140` in a
270-tall playfield. In practice the band that matters is roughly `y 20-70`: high enough that anything
whose lowest point sits above ~80 never really threatens, low enough that a shape bottoming out at
~50 lands on top of the player without overrunning them. Worth checking a number against this before
proposing it — it is the same check `combatY` needs for the boss, from the other end of the screen.

## Unknown JSON keys are rejected now, not ignored

**Corrected 31/08/2026.** `JsonContentSource.requireOnlyKeys` rejects any key a block's schema does
not name, for the level file, the boss block, a wave, a wave's end condition, a spawn entry, a
placement and a trajectory entry. The "content lands ahead of its parser and loads silently wrong"
failure below is closed for those blocks — it fails loudly instead. It is **not** closed for
`enemies.json` components: `JsonComponentSpecs.parse` passes every field through to
`ComponentFactoryRegistry`, so an unknown field there still depends on that registry to complain.
The practical consequence for a designer is the opposite of before: a new content field cannot be
landed ahead of the parser at all, so a format change is never content-only.

### What was true before that

As of this pass, `JsonContentSource.loadLevel` reads five fields and uses `SpawnEvent`'s
five-argument constructor, so `dropSlot` silently defaults to 0, and no code reads a `"boss"` object
at all. Unknown JSON keys are ignored, not rejected — content can therefore look correct, load clean
and do something else. Re-check both before trusting a drop placement or a boss's numbers.

**This is a recurring shape of failure here, not one incident.** Every loader in `JsonContentSource`
reads a fixed list of keys and ignores the rest, so *any* new field added to content ahead of the
parser that understands it is invisible rather than rejected. Checked again on 29/08/2026 for phase
11c: `loadTrajectories` (`JsonContentSource.java:157-166`) reads exactly `id`, `vx`, `vy`, so a
trajectory entry carrying a new `"type"`/`"ay"` would have loaded and flown as a plain constant
vector with no error anywhere. Rule of thumb: never land content for a field in an earlier pull
request than the parser — grep the matching `load*` method first, it is always a dozen lines.

## `EnemyWeapon`'s `firstShotDelay` vs. an archetype's screen time (25/08/2026)

`"rate"` (cooldown) alone was silently double-duty before this: an enemy without a `firstShotDelay`
had to survive one whole cooldown before firing once. For a fragile, no-`Health` archetype (basic,
light, rush all have no `Health` component), that reads as "never fires" even with a correct rate,
because one player projectile kills it well before its first cooldown elapses. `firstShotDelay` is now
a separate, shorter field for exactly this — set it to something an inattentive player still leaves
alone for, not to `rate` itself.

When picking `firstShotDelay`/`rate` for a fast trajectory, check it against the archetype's own
screen time (`(270 + radius) / |vy|`, from the note above) rather than against the player's weapon
cooldown: `enemy-rush` on `dive` (vy -80) is only on screen for ~3 s, so a `rate` of 4.0 s reliably
caps it at one shot per spawn — that is what makes "shoots little" a property of the number, not a
hope. A slower archetype's `rate` can safely be longer than its own screen time too; it just means
some spawns of it never get a second shot, which is fine for a "weak" archetype but would defeat the
purpose for one whose whole point is rate of fire (`enemy-shooter`).

## Verifying enemy fire visually needs the player off the enemy's column

Spawning a test enemy at the player's own starting `x` (`atX 0.5`, player start `x=104` of 208) on a
non-drifting trajectory (`slow-descent`, `vx 0`) rams the player almost immediately — game over at
score 0 before any projectile is visible, indistinguishable on screen from "the weapon never fired."
Spawn verification enemies off-center (e.g. `atX 0.2`/`0.8`) so the ram doesn't pre-empt the shot. A
tank on `crawl` (vx 0 as well) has the same problem if spawned centred on the player's spawn — it
rammed and ended the run within a few seconds during the tank-weapon verification, 25/08/2026.

## `Health` below `weaponProjectileDamage` is a content no-op (25/08/2026)

`DamageSystem.resolveEnemyHit` subtracts a flat `BalanceValues.weaponProjectileDamage()` — `10` today
— from an enemy's `Health` per hit, and this number does not scale with the player's weapon level
(only shot *count* does). An enemy with no `Health` is already treated as having exactly one point.
So giving a fragile archetype a small `Health` (2-3, floated once as a way to make `enemy-basic`'s
slower rate of fire visible next to `enemy-shooter`'s faster one) changes nothing observable: any
`Health` at or under `10` still dies to the very first player projectile, identically to having no
`Health` component at all. Before recommending a small `Health` value to make an archetype "survive a
hit," check it against `balance.json`'s `weaponProjectileDamage` first — the value needs to clear that
number, not just be nonzero, or the change is invisible in play. Full reasoning recorded in
`docs/plan/07-boss/status.md`'s 25/08/2026 tank-weapon entry.
