---
name: entity-lifetime-and-safety-box
description: Building #84 (an enemy that leaves the playfield leaves the simulation) — the CleanupSystem score-uniformity trap and its final decided fix (strip components upstream, don't teach the convergence point a new distinction), how the safety box's margin was sized, and the two-pass component-store technique
metadata:
  type: project
---

Phase 11b, task 1, branch `feat/entity-lifetime`. Two mechanisms: an optional per-archetype
`Lifetime` component (`core/domain/component/Lifetime.java`, a `"lifetime": {"seconds": N}` spec
through `ComponentFactoryRegistry`, same pattern as `"health"`/`"spawner"`/`"weapon"`) and a safety
box inside `LifetimeSystem` — a fixed margin past every playfield edge that removes an `ENEMY`-layer
entity outright. Both only ever fire once the entity's collider is fully off the playfield rectangle
(`x ± radius`, `y ± radius`), never on a still-visible one.

**`CleanupSystem`'s existing "converge every destruction path uniformly" design has a real, easy-to-
miss consequence the moment `LifetimeSystem` starts marking enemies for destruction: an escaped enemy
awards its `ScoreValue` and resolves its `Drop`, exactly like a defeated one.** `ScoreSystem` sweeps
`World.pendingDestruction()` without asking why an entity is on it, and `CleanupSystem`'s own javadoc
argues explicitly for this uniformity ("regardless of what killed its holder"). Before this task,
`LifetimeSystem` only ever expired projectiles, which never carry a `ScoreValue`, so this interaction
never had a chance to surface. The moment enemies go through the same `markForDestruction` path, it
does. Caught only by `LevelScoreReplayTest`'s golden-fingerprint test going red with a score *increase*
(1350→1600, exactly one `enemy-rush`'s worth) alongside the expected entity-count drop — a fingerprint
regression that changes two independent-looking numbers together is worth reading closely rather than
treating as "the entity count changed, so of course the fingerprint changed."

**First cut: I chose not to special-case this**, because issue #84 explicitly left "whether an escaped
enemy costs or gains the player anything" undecided — special-casing it would have been deciding that
game rule by implementation, the exact trap the phase's own risk list names. Recorded as an explicit,
revisitable decision in `docs/planning/08-decisions-and-open-items.md` instead of just implementing a
guess. **The coordinator brought back the project owner's actual decision the same day: an escaped
enemy gives nothing.** The mechanism that survived review: `LifetimeSystem` — the only place that
knows an entity is *escaping* rather than *being defeated* — strips that entity's `ScoreValue`,
`Drop` and `Collider` before calling `World.markForDestruction`. `ScoreSystem` and `CleanupSystem`
needed zero changes, because both were already conditional on the component they read being present;
stripping the component upstream is enough to make a uniformly-converging pipeline produce "nothing"
for this one entity without teaching it a new distinction. **The lesson generalises: when a system
already only acts on "is component X present", the cheapest way to opt an entity out of that system's
effect is to remove X before the shared convergence point sees it — not to add a flag or parameter
threading through every consumer.** This is also why the golden fingerprint moved twice
(1350→1600→1350): the intermediate value was a real, briefly-correct state, not a mistake to erase
from history — the test's own comment says so, and the git history carries both edits, not a squash.

**The safety box's margin was sized from `SpawnSystem.positionSpawned`'s own formula, not guessed.**
Worst case on 27/08/2026: `column-3`'s 44-unit spread carrying `enemy-carrier`'s 15-unit radius, born
at `y - radius = 314` past the bottom edge measured from its own boundary. Picked 128 units past every
edge (uniform on all four sides, not tuned per edge) specifically to leave ~2x headroom over that
314→398 gap, anticipating phase 11c's movement shapes without needing a second pass immediately.
`LifetimeSystemTest.safetyBoxClearsTheWorstCaseSpawn` hardcodes that same worst-case number (44, 15)
as a regression guard — it does not read `formations.json`/`enemies.json` (outside `core`'s reach), so
it only catches this specific number going stale by hand, not a live drift in content.

**Stripping a component from the very store a loop is walking mid-iteration is the same hazard
already documented for destruction ([[defensive-chain-and-collision-design]]), and it applies to a
plain `remove()`, not only to `World.markForDestruction`.** Once the fix needed to remove an escaping
entity's own `Collider`, the naive single pass over `world.colliders()` inside `expireEnemies` would
have swap-removed the current entity mid-loop, reordering the dense array under its own iteration —
`ComponentStore`'s class javadoc names this exact hazard. Fixed with two passes: collect escaping
entity ids into a plain list while walking `colliders()` read-only, then strip and mark each one only
after that loop has fully finished. Removing from *other* stores (`scoreValues()`, `drops()`) while
mid-iteration over `colliders()` is fine — the hazard is only ever "don't mutate the store you are
currently walking."

**`Lifetime` was built as *optional* per archetype, not required.** The safety box alone already fixes
#84 for every existing archetype with zero content changes, and `assets/data/enemies.json` is outside
this agent's `core/`-only boundary — a required field would have broken content loading for six
archetypes I cannot fix from here. Whether any archetype should carry an explicit, shorter `Lifetime`
is left as a content decision for `level-designer`.

See [[core-deferred-surface]] for the running list of what was deferred and why (the `Lifetime`
component itself was one of these, closed by this task), [[game-systems-design]] for the
`Health`/`ScoreValue`/`Drop` shapes this interacts with, and [[player-vertical-clamp]] for the last
time an unwritten spatial-bounds decision caused a silent gap.
