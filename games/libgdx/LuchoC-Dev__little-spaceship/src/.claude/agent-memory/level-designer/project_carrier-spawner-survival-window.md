---
name: carrier-spawner-survival-window
description: A spawner's first child arrives one full interval after the holder spawns, so a carrier's health has a hard floor set by ideal player dps — the arithmetic and where the numbers come from.
metadata:
  type: project
---

Learned tuning `enemy-carrier` from 1000 to 700 on 01/09/2026 (phase 11e, #210). It is the one health
value in the roster that is not a taste question.

**A `Spawner`'s timer starts at `interval`, not at zero** — `core/domain/component/Spawner.java:52`,
`this.timer = interval`. So a carrier with `interval 4.0` produces its **first** child 4.0 s after it
spawns, and a carrier that dies in under 4.0 s produces none at all. Its entire designed mechanism is
invisible and nothing in the build reports it: no test, no check in the generated document, no
warning. It reads as "the carrier is just a big target".

**How to check a candidate health value, in one line of arithmetic.** The holder must survive
`interval` seconds, so it needs `health > interval x dps`. `dps` is not 67: `WeaponSystem.java:96`
fires 1/2/3/5 parallel projectiles at shot levels 1-4 and all of them land on anything wider than
about 12 units, which every archetype is. At `weaponProjectileDamage` 10 and `weaponFireCooldown`
0.15 that is **67 / 133 / 200 / 333 dps**. Against `interval 4.0` the floors are 268 / 532 / 800 /
1332.

**Which shot level to use is read from the generated document, not assumed.** The Drops section of
`docs/levels/level-01.md` gives the `weapon-upgrade` times and the pacing table gives the beat's start
time; count the upgrades that fall before it. In level 1 as it stands, carriers appear at 67.0 s and
97.5 s with upgrades at 11.0 / 48.0 / 86.0 — shot levels 3 and 4, floors 800 and 1332. **700 is below
both.** It was applied anyway because it is the project owner's decision and because "ideal dps" means
perfectly aligned, never dodging, from the tick the carrier crosses the edge — which no real player
holds for four seconds while other enemies are on screen.

**How to apply:** when a carrier's health is proposed, print the floor for the shot level its beat
actually implies before agreeing it is safe, and say in the fragment whether the number clears it.
A number below the floor is not automatically wrong — it is a bet that the player will be interrupted
— but it must be named as one, because the failure is silent and looks like a design choice.

Related: [[enemy-durability-arithmetic]], [[level-one-content-mechanics]].
