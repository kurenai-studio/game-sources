---
name: trajectory-evaluation-wiring
description: How issue #164 wired a per-tick trajectory re-evaluation into MotionSystem — why Trajectory stores an id not a definition, why it is attached uniformly for every kind, and the SpawnEvent constructor trick used a second time.
metadata:
  type: project
---

`core.port.TrajectoryDefinition` (sealed to `SimpleTrajectoryDefinition`/`ArcTrajectoryDefinition`,
see [[movement-shape-content-contract]]) sat unused on the `feat/spawn-shape-id` branch: #163 built
the closed-form `verticalVelocityAt(elapsed)`, nothing called it. Closing that required deciding what
a `Trajectory` component stores and when it gets attached — neither was written down anywhere.

**A component that names content stores the id, never the resolved object.** `Trajectory` holds
`String trajectoryId` + `float elapsed`, not a `TrajectoryDefinition` reference, matching
`Spawner.enemyId`'s existing pattern. `MotionSystem.advanceTrajectories` resolves it through
`world.content().trajectory(id)` every tick. This costs a hash-map lookup per entity-with-a-Trajectory
per tick, accepted deliberately — the MVP moves a few hundred entities, and CLAUDE.md's own stance is
"optimise drawing first, spatial structures for collision only if it ever becomes necessary". Caching
the resolved object on the component would be the standard optimization but has no case yet.

**`Trajectory` is attached to every entity with a `Motion`, `constant` shapes included — not only to
entities on a time-varying shape.** The component's own pre-#164 javadoc implied the opposite ("an
entity with no Trajectory simply keeps whatever constant Motion..."), written before the binding was
decided. I went uniform instead: `MotionSystem` re-evaluates unconditionally, and a `constant` shape's
`verticalVelocityAt` ignores elapsed time and returns the same value forever, so the result is
bit-identical to the old one-time snapshot — proven by a dedicated test
(`constantShapeStaysConstantAcrossTicks`) rather than assumed. This avoids a second code path (`if
(isTimeVarying)`) for a case with no real cost difference at MVP scale. If this project ever needs to
skip the per-tick lookup for genuinely static enemies, that decision should be re-made against a
measured cost, not assumed cheap the way I assumed it now.

**The record-constructor back-compat trick ([[boss-fight-design]]) applies a second time cleanly.**
`SpawnEvent` gained a seventh component (`trajectoryId`) the same way it gained `dropSlot` in #23:
old five- and six-argument constructors delegate to the new seven-argument canonical one with the new
field defaulted (`null` here, meaning "no override"). Every existing test call site and `game`'s
loader kept compiling. Worth continuing to reach for first whenever a widely-constructed record needs
one more field with a sensible default.

**Evaluation happens inside `MotionSystem.advanceTrajectories`, in the same loop as the `elapsed`
increment, before `integrate()`** — not a separate method, not a separate `SystemOrder` stage. The
override itself (`SpawnEvent.trajectoryId` replacing the archetype default) is applied in
`SpawnSystem.spawnWave`, right after `attachComponents`, by calling a new
`ComponentFactoryRegistry.attachTrajectory(World, int, String)` — made `public static` (not
package-private) specifically so `SpawnSystem`, in a different package, can call it; the two systems
share this one resolution path instead of duplicating it.

Related: [[boss-fight-design]], [[movement-shape-content-contract]], [[movement-state-component]],
[[content-pipeline-design]].
