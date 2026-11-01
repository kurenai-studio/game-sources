---
name: game-systems-design
description: How phase 05's weapon, bomb, pickup, score and Health systems were shaped, and the fragile/Health split that keeps damage resolution from disagreeing with itself
metadata:
  type: project
---

Built in phase 05 (`docs/plan/05-game-systems/`), across three rounds — a first pass, a review
round that added `Health`, and a second review round that rejected the phase over three defects in
`BombSystem` plus a test guard that had stopped guarding. The shape decided here is load-bearing for
whoever eventually adds a boss (phase 07, needs `Health` too) or a second attachment type.

**`Health` exists, built mid-phase after a coordinator review caught it missing — see
[[verify-against-architecture-doc]] for why the first pass got this wrong.** `12-architecture.md`
already named the component and showed `{"points": 40}` as a tank's illustrative value; nothing in
`10-mvp-initial-values.md` fixes real per-archetype numbers, which is a genuinely open item, but the
component's *shape* was never in question. `HealthDamage.apply` (a small package-private helper
shared by `DamageSystem.resolveEnemyHit` and `BombSystem.detonate`) is the one place damage is
subtracted from it, so the two systems cannot apply the rule differently. `Collider.fragile` keeps
its phase 02 meaning — whole-body outcome for ramming and the bomb — and now answers a strictly
different question from `Health`, which governs sustained weapon damage: the bomb checks `fragile`
first (outright destruction) and only consults `Health` for a non-fragile target. An entity with no
`Health` component is treated as having exactly one point everywhere damage is applied, which is
shorthand for the weakest case of the rule, not a second rule that could disagree with it — this is
what keeps a missing `"health"` in content from becoming a second, silently different mechanism.

**`ScoreValue` removal on award is what makes double-marking-for-destruction safe.**
`World.markForDestruction` has no dedupe — nothing stops two systems from marking the same entity
in the same tick (a fragile enemy both rammed and shot, say). `ScoreSystem` calls
`world.scoreValues().remove(entity)` the instant it awards the points, so a second appearance of the
same entity in `pendingDestruction` finds nothing to award. Whoever adds a third destruction source
should rely on this rather than trying to dedupe `pendingDestruction` itself — that list is shared
and cleared by `CleanupSystem`, not owned by whoever marks it.

**`CleanupSystem` is the one place `Drop` becomes an actual `Pickup` entity**, deliberately not
`DamageSystem` or `BombSystem` even though both are sources of enemy death. `Drop`'s own javadoc
(written in phase 04) already said the resolution happens "when the holder is destroyed" — `Cleanup`
is the literal single place every destruction path converges, so putting it there instead of
duplicating "check for a Drop" in every system that can kill something was the only design that
does not grow linearly with the number of death sources. Read `Transform` and `Drop` *before*
calling `World.destroyEntity`, in that order — the entity's components are still valid until that
call.

**A `Weapon` component (cooldown timer) is separate from `Player.shotLevel`** on purpose: shot level
survives a death like every other persistent power-up (it lives on `Player`, per phase 02's
precedent), while the cooldown is per-tick machinery nothing needs to persist. Putting both on
`Player` would have made a field on the "persistent stats" component that is not actually
persistent, which is exactly the kind of drift `core-boundary-decisions.md` warns about elsewhere.

**`LifetimeSystem` expires by position, not by a timer**, and no `Lifetime` component was built even
though `core-deferred-surface.md` named one as a future possibility. Every MVP projectile is a
straight line, so "has this left the playfield" is a cheap position check against bounds
`SpawnSystem`/`MotionSystem` already define — a timer would have been an invented number
(`docs/planning/` has none) solving a problem position-checking already solves for free. Same
"build what the existing need asks for" precedent `content-pipeline-design.md` already recorded for
trajectories vs. patterns.

**Six pickup kinds are fixed string constants on `PickupSystem`, and `"attachment"` is not one of
the fixed five** — it is resolved through `ContentSource.attachment(String)` using the pickup's own
kind string as the content id. This is what makes attachment durability genuinely data-driven
(`AttachmentDefinition.durability()`) without a seventh special case: the MVP's one attachment type
happens to reuse `"attachment"` as both its `Pickup.kind` and its content id, and a second attachment
type would only need a different content id, never a branch in `PickupSystem`.

**An edge-shaped input needs state inside `core`, tracked per tick — neither `GameLoop` nor the
adapter can debounce it, and this was the second real defect the phase's own tests did not catch.**
`GameLoop.advance` feeds one `InputFrame` to every tick of a rendered frame, by contract — that is
what lets a variable frame time simulate a whole number of fixed steps — so anything that reads
`InputFrame.bomb()` as "spend one charge" without tracking what it saw last tick spends one charge
*per tick*, not per press, the moment a frame produces more than one tick (any frame rate below 60,
or the tick burst after `GameLoop.MAX_FRAME_TIME` lets a stall catch up). The fix is a tiny
component (`BombState.heldLastTick`) read and written by the one system that consumes the edge,
never by the loop or the adapter — neither of those layers has tick-granularity visibility. `fire`
never needed this because it is deliberately level-shaped (sustained fire); the next one-shot input
this project adds will need the identical pattern, not a shared abstraction built now for a second
case that does not exist yet.

**A test that claims to guard "every X" needs to discover X mechanically, not enumerate it by
hand — `WorldTest.destroyStripsEveryComponent` had already drifted from 13 stores to 4 assertions
once before this was caught.** The fix: reflection over `World.class.getDeclaredFields()`, filtered
to `ComponentStore`-typed fields, so the set of things to check is derived from `World` itself and
cannot go stale by omission. That alone is not sufficient — a newly added store would still pass
vacuously (empty before and after) if nobody populates it — so the test also asserts every
reflectively-discovered store is non-empty *before* asserting it is empty after destruction; skipping
the populate step for a new component fails loudly with the store's name, rather than passing
silently. The same shape (`assertTrue(x.size() >= N, "...")`) already existed in
`PublicContractTest.inspectsTheBoundary()` and `DeterminismRulesTest.readsTheSources()` before this
phase — "assert the check is actually exercised" is a recurring pattern in this codebase's
architecture tests, not new here, just newly applied to `WorldTest`.

See [[core-deferred-surface]] for what is still unbuilt, [[verify-against-architecture-doc]] for
the process lesson `Health` cost a review round to catch, [[defensive-chain-and-collision-design]]
for the `SystemOrder`-ordinal discipline `BOMB`'s insertion had to respect and the
`pendingDestruction`-filtering rule the second review round added there, and
`docs/plan/05-game-systems/status.md` for the acceptance-criteria table and the exact `game`-module
compile breakage this phase leaves behind for `game-presentation`.
