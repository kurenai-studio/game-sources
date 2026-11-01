---
name: content-pipeline-design
description: How the phase 04 content contracts are shaped — generic ComponentSpec, the factory registry, and why patterns/weapon were left out
metadata:
  type: project
---

Built in phase 04 (`docs/plan/04-content-pipeline/`). The shape decided here is load-bearing for
whoever writes `game`'s JSON loader and for phase 05's `WeaponSystem`/`PickupSystem`.

**`ComponentSpec` is one generic interface (name + typed key/value bag), not one Java type per
component.** This was the one point in the whole phase where a typed-interface-per-component design
looked tempting and would have been wrong: it would have meant a matching Java type for every JSON
object in `enemies.json`, which defeats the entire point of a `name -> factory` registry. The
generic shape is also literally what `12-architecture.md`'s own JSON example already implies
(`"collider": {"radius": 7, "layer": "enemy"}`), so it was not really a free choice.

**Firing patterns were deliberately not built, even though the plan's task list names them next to
trajectories.** No `Weapon` component and no `WeaponSystem` exist yet (phase 05's job). Declaring a
`PatternDefinition` now would mean guessing shot count / spread / cooldown / projectile sprite with
no consumer to check the guess against — the exact mistake phase 02's memory already flagged for
`GameEvent` (`core-deferred-surface.md`). Trajectories *were* built in the same task because
`MotionSystem` already exists and already consumes a `Motion` component, so a trajectory's shape (a
constant velocity, nothing curved) was not a guess — it is exactly what the existing consumer reads.
**If a future phase is tempted to declare a content contract for something with no consuming system
yet, check for a real, already-built consumer first, the same way this phase did for trajectories vs.
patterns.**

**`Drop` (the component) is attached directly by `SpawnSystem` from the `SpawnEvent`, never through
`ComponentFactoryRegistry`.** A designed drop marks one instance of a wave, not the archetype — the
plan says so explicitly (task 8). Routing it through the same generic per-archetype-component registry
as `motion`/`collider`/`sprite`/`scoreValue` would have quietly turned it back into archetype data,
which is the exact bug the plan calls out avoiding.

**A `ComponentFactoryRegistry` is looked up by exact key, never iterated.** Registration order in
`withDefaults()` therefore has zero effect on a replay — worth remembering before "reordering
registration calls" gets flagged as a determinism risk it is not.

**Two bugs review round 1 caught, both worth generalising:**

- **A "measure against my own field" positioning formula is wrong the moment the field can vary
  across a group.** `SpawnSystem` computed each spawned entity's y from *that entity's own*
  `slot.offsetY()`, which only guarantees "fully off-screen" for a single-slot formation. A formation
  with slots at different `offsetY` (a `diagonal`) needs the guarantee checked against the group's
  extremum — the lowest `offsetY` — and every other member measured relative to *that*, not to its
  own offset. No test caught this because every formation fixture up to that point used `offsetY: 0`
  for every slot, which makes "measure against your own offset" and "measure against the group's
  extremum" produce identical numbers. **Whenever a test fixture only ever uses the zero/neutral case
  of a field a formula depends on, that formula's real behaviour on a non-neutral value is unverified,
  not merely untested.**
- **An optional accessor with a default is only safe when the default is actually the common case,
  and only if "wrong type present" is treated as a failure, never silently folded into "absent".**
  `ComponentSpec.flag("fragile", false)` shipped with a minority-case default (2 of 6 archetypes
  are non-fragile) and, worse, `MapComponentSpec`'s optional accessors returned the default on a
  *wrongly-typed* value too — so a JSON string `"true"` and a JSON boolean `false` were
  indistinguishable to a caller. Fixed by removing every default entirely: `ComponentSpec` now has
  no optional accessor, "missing" and "wrong type" are distinct failure messages, and the field the
  game rule actually depends on (`fragile`) must be explicit in every archetype. Removing the default
  was simpler to defend than picking a better one, and it was also how the two dead accessors
  (`number`/`text` with a default, `H3` in the same review) got noticed and removed — nothing in
  `core` ever called them.

See [[core-deferred-surface]] for the running list of what is deferred and why, and
[[defensive-chain-and-collision-design]] for the `SystemOrder` ordinal-checking discipline this
phase's `SpawnSystem` (ordinal 3, before `COLLISION` at 5) had to respect too.

**Update (enemy first-shot-delay task, branch `feat/enemy-first-shot-delay`): the "no optional
accessor" rule above got its first real counter-case, and it was added back deliberately, not
relaxed.** `EnemyWeapon.cooldownRemaining` starting at the full `cooldown` meant an enemy's first shot
waited as long as every shot after it — fine for the one archetype that shipped with a short cooldown,
wrong the moment content wants a long `cooldown` (a "slow shot" archetype) with a short, readable delay
before the *first* shot. Fixed by adding `ComponentSpec.numberOr(key, default)` back, but narrowly: it
still fails loudly on a wrongly-typed value (only a *missing* key takes the default), and the default
chosen (`cooldown` itself) is the value every existing archetype already effectively had, not a
guessed common case — the same trap `flag("fragile", false)` fell into is what this avoids. The new
field is `firstShotDelay` in JSON, read in `ComponentFactoryRegistry.attachEnemyWeapon`; zero is
rejected by `EnemyWeapon`'s constructor (same "strictly positive" treatment as `cooldown` and
`projectileSpeed`) because zero means "fire the instant it spawns", the exact unreadable case the
delay exists to prevent. Lesson generalised: this rule's exception condition is "a real consumer needs
a default that is not the field's own most permissive/dangerous value, and wrong-type still fails" —
check both before adding a second one.
