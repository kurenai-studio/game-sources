---
name: boss-fight-design
description: How phase 07's boss avoided a new component/store, the record-constructor trick for issue #23, a shared-vs-independent-Health tradeoff, and a mid-phase scope correction on the carrier
metadata:
  type: project
---

Two reusable techniques from building `BossSystem`, plus one verification habit worth repeating.

**A single, unique multi-entity thing does not need a component or a `ComponentStore`.** The boss is
five entities (core, two pods, two arms) that must move and be tracked together, but nothing else in
the game needs to query "which entities belong to a boss" generically — there is exactly one boss,
owned by exactly one `BossSystem`. So the five entity ids are plain instance fields on `BossSystem`
itself (the same pattern `SpawnSystem` already uses for its cursor and elapsed time), not a new
`BossPart` component with a fifth `ComponentStore` in `World`. This avoided touching `World`'s store
list, `destroyEntity`'s removal list, and any new iteration cost, for a case with exactly one
consumer. Reach for a component/store only when something *else* — a different system, or
presentation through `WorldView` — needs to look the relationship up independently.

**A record can grow a field without breaking existing callers, by keeping the old constructor as a
delegating overload.** `SpawnEvent` needed a `dropSlot` field for issue #23 (a designed drop must tie
to one formation slot, not apply to every slot), but dozens of call sites across `core` tests and, more
importantly, `game`'s content loader (outside this agent's boundary to fix) already used the original
five-argument constructor. Adding `dropSlot` as a sixth canonical component and then adding back a
five-argument constructor that delegates to the six-argument one (defaulting `dropSlot` to `0`) kept
every old call site compiling, with old behaviour reinterpreted as "the drop goes to slot 0" — a
behaviour change, but not a compile break, and the correct default besides. Worth remembering whenever
a decided fix needs a new field on a widely-constructed record: check whether the field can default
sensibly before assuming every call site (including ones outside this agent's own module) must change.

**Adding a method to a `core.port` interface that `game` already implements is expected to break
`game`'s compile, and that is fine to leave for the other agent — but verify it, don't guess.**
`ContentSource` gained `hasBoss`/`boss` this phase; running `./gradlew :game:compileJava` from the
worktree (read-only — this agent never edits `game/`) confirmed the exact, single compile error named
in the status file, rather than asserting "this will need updating" without checking what the actual
error says. The same check is worth repeating any time a `core.port` interface implemented outside
`core` grows a method — `BalanceValues`, by contrast, was deliberately *not* touched this phase
precisely because it has more implementers across the boundary and none of the new boss numbers were
generic enough to belong there; they went on the new `BossDefinition` instead.

**A component sharing its `Health` object reference across two entities looks tempting and is a trap.**
Closing the boss's keel gap needed a sixth collider (`core-keel`) covering the same region the core's
own drawn sprite occupies. The instinct was to give it the *same* `Health` object as the core, so a
hit on either reduces one shared number — but `HealthDamage.apply` marks for destruction whichever
single entity it was called with, not "whoever holds this `Health` object". A shared reference would
leave the core entity itself technically alive forever if the keel happened to absorb the killing
blow, silently breaking any `!world.isAlive(core)` check downstream without a second, entity-specific
bookkeeping layer to compensate. Giving the keel its own independent `Health`/`ScoreValue` — treating
it as a sixth ordinary part rather than a second hitbox for the same part — needed no special case at
all and is the pattern to reach for first the next time "two colliders, one logical thing" comes up.

**A report can be wrong mid-phase, and the fix is to correct it, not to defend the original call.**
This phase's first report said the carrier's `Spawner` component had "no real consumer" and was left
unbuilt. The coordinator came back and pointed out the strong encounter (two carriers) was *chosen*
specifically because a carrier spawning basics produces sustained pressure — without `Spawner`, the
encounter is just two large, slow enemies, and the reason for picking it stops being true. The
original call was reasonable given what was known at the time (no consumer existed *yet* in the
code), but "no consumer" was the wrong test — the consumer was the design decision itself, one layer
up from the code. Building it was cheap once flagged. Worth re-checking, before deferring anything as
"no real consumer", whether an already-made design decision is quietly depending on it.

**"One field plus one write site" from a plan is a guess, not a count — `git grep` the actual creation
sites before believing it.** Phase 11b's task 2 (issue #85, a `WaveOrigin` component recording which
wave spawned an entity) had exactly this shape: the plan named `SpawnSystem.spawnWave` as the only
site and called the task "probably wrong by one" in the same breath, pointing at `SpawnerSystem`'s
carrier-child spawn as the second. `git grep -n "createEntity" core/domain/system/` turned up seven
sites in total; checking each against the actually-decided rule ("children a carrier spawns inherit
their parent's wave") ruled out five of them (`CleanupSystem`'s dropped pickup, `BossSystem`'s parts
and its own projectiles, `EnemyWeaponSystem`'s and `WeaponSystem`'s projectiles) rather than assuming
every entity created downstream of a wave-spawned entity should inherit the tag. The grep is cheap;
skipping it and trusting the plan's own count is the mistake this note exists to prevent.

Related: [[core-deferred-surface]], [[content-pipeline-design]], [[rng-teavm-constraints]].
