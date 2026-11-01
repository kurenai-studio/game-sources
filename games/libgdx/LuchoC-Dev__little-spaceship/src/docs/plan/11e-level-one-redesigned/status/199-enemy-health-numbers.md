# 199 — Give the enemies real numbers, against `weaponProjectileDamage` 10

**Task 3 of phase 11e** · branch `feat/enemy-health-numbers` · closes [#199](https://github.com/LuchoC-Dev/little-spaceship/issues/199)

**This is a candidate, not a result.** The verdict is task 5's and it comes from the project owner's
play session ([#201](https://github.com/LuchoC-Dev/little-spaceship/issues/201)). Every number below
is written as a proposal with the reasoning that produced it, so the session can confirm it or move
it without re-deriving anything.

## What changed

`assets/data/enemies.json` only. `level-01.json` and `waves.json` were not touched — the fourteen-wave
rebuild ([#198](https://github.com/LuchoC-Dev/little-spaceship/issues/198)) owns those.

| archetype | was | now | projectiles to kill |
|---|---|---|---|
| `enemy-rush` | none | none | 1 |
| `enemy-light` | none | 20 | 2 |
| `enemy-basic` | none | 30 | 3 |
| `enemy-shooter` | none | 40 | 4 |
| `enemy-tank` | 40 | 300 | 30 |
| `enemy-carrier` | 80 | 1000 | 100 |

The reasoning for each one is in `docs/planning/10-mvp-initial-values.md`, "Enemy health against the
level's own pacing", which this branch rewrote from an open item into a recorded candidate. It is not
repeated here.

**The two numbers the task named explicitly**, both above 10 so they are not the no-op the issue warns
about: `enemy-basic` 30 and `enemy-light` 20.

**`enemy-shooter` was raised even though the task did not name it.** Leaving it at one hit while the
basic took three would have inverted the contrast the spec asks for — the bigger, faster-firing
archetype dying before the basic it is supposed to be told apart from.

**`enemy-carrier` 1000 addresses the 1.2 s problem the plan states.** At 80 hp the carrier died in
about 1.2 s against a `spawner` interval of 4.0 s, so it never produced one child and its designed
mechanism never happened at all. 1000 is not a new number: it is the order of magnitude this
repository had already derived in `10-mvp-initial-values.md` for "roughly 15 s of sustained fire" at
67 damage per second.

## What was verified, and how

**`fragile` is orthogonal to weapon damage — health on a fragile archetype is honoured.** I read the
code rather than assuming:

- `core/domain/system/DamageSystem.java:93` resolves a player projectile hitting an enemy through
  `HealthDamage.apply(world, enemy, balance.weaponProjectileDamage())`, and never consults
  `Collider#fragile` on that branch.
- `core/domain/system/HealthDamage.java:35` subtracts from `Health` and destroys at zero; an entity
  with no `Health` is destroyed by any positive amount.
- `fragile` is read in exactly two places, and both are whole-body impact, not sustained fire:
  `DamageSystem.java:149` (the enemy's body is destroyed when it rams the player) and
  `BombSystem.java:115` (a detonation destroys it outright whatever `Health` says).

**So no rule in `core/` had to change, and none did.** The health ladder now happens to mirror the
`fragile` flag — the four fragile archetypes are 1 to 4 projectiles, the two non-fragile ones are 30
and 100 — which is the cliff between "swarm" and "obstacle" that `fragile` was already marking.

**One consequence of that, which is a real behaviour and not a bug:** the bomb still deletes every
fragile enemy on screen in one detonation regardless of the numbers above (`BombSystem.java:115`), so
raising basic, light and shooter did not weaken the bomb against a swarm.

**Tests.** `./gradlew build` — exit 0, whole build green, no test changed. The 11a rule-asserting
tests are untouched. `LevelScoreReplayTest`'s golden fingerprint did not move because that fixture is
built in-test and does not read `assets/data/` (see the finding below).

**Generated documents.** `node tools/build-level-docs.js` run after the content change and committed;
it reported `updated docs/levels/level-01.md`, `unchanged docs/levels/waves.md`. Re-running it after
the prose edits reports both unchanged, so the tree is clean against CI.

## Findings

### For `core/` — a javadoc claim that this change made false

`core/src/test/java/dev/luchoc/littlespaceship/core/application/LevelScoreReplayTest.java:32` says the
fixture gives the tank and the carrier *"the same `health` points `assets/data/enemies.json` gives
them (40 and 80)"*. Both numbers have moved. The **test is correct and still passes** — its fixture is
built in-test with `health(40f)` and `health(80f)` at `:124` and `:127`, and nothing in the suite
reads the real content files — but the sentence explaining why those two values were chosen is now
wrong, and it is the sentence a future reader would trust. `core-domain` owns that file; I did not
touch it. Either the javadoc drops the claim, or the fixture tracks the content.

### For 11d's document contract

I am the first reader of `docs/levels/level-01.md` who did not help build it, and it was genuinely the
instrument for this task — the Roster's `shots to kill`, `screen time`, `shots per pass` and
`children per pass` are what made "the carrier never spawns a child" visible as arithmetic instead of
a hunch. Two things it does not say, both of which cost a detour into `core/`:

1. **`shots to kill` counts projectiles, and the player does not fire one projectile per pull.**
   `core/domain/system/WeaponSystem.java:96` fires 1, 2, 3 and 5 parallel projectiles at shot levels
   1 to 4, spaced 3 units apart — so one trigger pull lands all of them on any target wider than about
   12 units, which is every archetype in the roster. The real time-to-kill at shot level 4 is a fifth
   of what the column implies. The document prints `weaponLevels 4` in "Designing against the player"
   and prints `shots to kill` in the Roster, and never connects the two. Suggested fix: either rename
   the column to `projectiles to kill`, or add a `pulls to kill` column per shot level, or add one
   sentence under the Roster saying which one it means.
2. **Time to kill in seconds is never printed**, although both inputs are — `weaponFireCooldown 0.15`
   is in "Designing against the player" and the projectile count is in the Roster. The complaint this
   whole task exists to fix is stated in the plan in seconds ("about 1.2 s against the 32 s its
   stretch reserves"), and the document cannot express it. A `seconds to kill` column next to
   `screen time` would have made the problem and the fix readable in one row, since those are exactly
   the two numbers you compare.

Both are additions to `tools/build-level-docs.js`, which is the coordinator's, not mine.

### Still open, and recorded in `docs/planning/10-mvp-initial-values.md`

**`bombDamage` 50 against a carrier at 1000.** A bomb now removes 5% of a carrier where it used to
remove 62%, and `02-mvp-functional-spec.md` asks the bomb for "heavy damage to resistant enemies".
`bombDamage` was left alone deliberately: it also lands on the boss's parts and the boss is task 4's.
It needs a decision from whoever holds both.

### For [#198](https://github.com/LuchoC-Dev/little-spaceship/issues/198), the fourteen-wave rebuild

The numbers moved under it. If any of the fourteen waves ends on `{"type": "cleared"}`, a tank now
takes 30 projectiles and a carrier 100 rather than 4 and 8, so a cleared wave holding either one lasts
several times longer than the same wave would have before this branch.

## What the play session should look for

Beyond the five questions already in `plan.md`:

- **`enemy-basic` versus `enemy-shooter` reads only in the first ~130 s.** Level 1 hands out
  `weapon-upgrade` at 21.0 s, 133.5 s and 256.0 s, and at shot level 4 a basic, a light and a shooter
  all die to one pull whatever their `Health` is. Watch-item 1 from `docs/STATUS.md` is answerable in
  the opening beats and nowhere else.
- **Whether the carrier now overstays.** 1000 is deliberately a floor, chosen so at least one child
  spawns under fire. If it reads as a sponge rather than a heavy, the number to cut is this one and
  the arithmetic scales linearly.
- **Whether the tank at 300 forces the priority shift or just interrupts.** Its beat is 20 s and its
  pass is 31 s; 300 is about 4.5 s of held fire at shot level 1.
