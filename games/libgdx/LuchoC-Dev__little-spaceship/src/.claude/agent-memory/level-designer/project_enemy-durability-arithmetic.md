---
name: enemy-durability-arithmetic
description: How long an enemy actually survives player fire — the weapon level multiplies projectiles per trigger pull, fragile is orthogonal to Health, and the bomb ignores Health on a fragile enemy entirely.
metadata:
  type: project
---

Everything needed to reason about an enemy's durability before touching `assets/data/enemies.json`.
None of it is in `docs/`, and two of the four cost a detour into `core/` during phase 11e.

**A trigger pull is not one projectile.** `WeaponSystem.pattern` (`:96`) returns 1, 2, 3 and 5
parallel projectiles at shot levels 1 to 4, spaced `SHOT_SPACING` 3 units apart — so level 4 spans
±6, and every archetype in the roster is wider than that. **One pull lands every projectile.** A pull
is therefore worth 10, 20, 30 or 50 damage against `weaponProjectileDamage` 10, and effective DPS at
`weaponFireCooldown` 0.15 runs 67 / 133 / 200 / 333 per second.

**Why:** the `shots to kill` column in the generated `docs/levels/level-01.md`, and the "one stream of
fire does about 67 damage per second" line in `10-mvp-initial-values.md`, are both written against a
*single* projectile — i.e. shot level 1 only. Sizing a health value off either one, without checking
where the level's `weapon-upgrade` drops fall, overestimates durability by up to 5×.

**How to apply:** before choosing a number, find the `weapon-upgrade` times in the Drops section of
the generated level document and work out which shot level the player holds during the beat you are
tuning. A fragile archetype's health only "reads" until the pull damage exceeds it — after that it is
a one-pull kill again whatever the JSON says, which is the upgrade doing its job, not a bug.

**`fragile` and `Health` answer different questions and never fight.** Health on a fragile archetype
*is* honoured for weapon fire — `DamageSystem:93` calls `HealthDamage.apply` and never looks at
`Collider#fragile` on that branch. `fragile` is read in exactly two places, both whole-body impact:
`DamageSystem:149` (destroyed when it rams the player) and `BombSystem:115` (destroyed by a
detonation **outright, whatever Health says**).

**How to apply:** raising a fragile archetype's health needs no change in `core/` and cannot be
blocked by `fragile`. But it also cannot make the bomb weaker against a swarm, because the bomb never
consults Health there. Against a *non-fragile* enemy the bomb subtracts `bombDamage` normally — which
is where raising a carrier's health quietly makes the bomb useless against it, and there is no
mechanism that notices.

Related: [[level-values-that-live-in-code]], [[level-one-content-mechanics]].
