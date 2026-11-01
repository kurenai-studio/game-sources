---
name: boss-volley-density
description: Why a hardcoded fan count fixed the level-1 boss's "too easy" fight, and a test trick for counting only newly-spawned entities across ticks
metadata:
  type: project
---

**A boss firing exactly one projectile per charging part is not fixable through content.** Level 1's
boss was diagnosed as too easy from real play: `patternCooldown` was already lowered by content, but two
bullets every ~1.45 s cannot be tuned into a real fight from the content side — the *count* was
hardcoded in `BossSystem.fire`/`fireFrom`, one call per pod or per arm. The fix had to live in `core`.

**Widening a volley into a fan of fixed ratios is the same technique `SPREAD_VX_RATIO` already used, just
applied `FAN_COUNT` times instead of once.** `fireFrom` stayed untouched; a new `fireFan` loops a
`float[]` of ratios (narrowest to widest) and calls `fireFrom` once per ratio, all sharing one `vy`
ratio. No `Math.sin`/`cos`, no `Rng`, no clock — the JVM/TeaVM float-parity constraint that motivated
the original single-ratio constants extends cleanly to an array of them. Varying only the horizontal
ratio (keeping `vy` uniform across the fan) was a deliberate simplification: it's already enough to
produce visually distinct rays from one origin, and it keeps every ray of a volley reaching the
player's height at the same predictable cadence.

**`FAN_COUNT` was chosen as a fixed design constant, not a `BossDefinition` field.** The task explicitly
allowed either, given the deadline and that exposing a new content key requires editing `game`'s
`JsonContentSource.requireOnlyKeys` — outside this agent's boundary. Precedent: the part radii and
offsets are already hardcoded as "footprint, not balance" in this same class's javadoc, and volley shape
is the same category of fact. If a future difficulty pass wants per-level fan width, that key would need
`game`'s content loader updated in the same PR, not left for `core` alone to add.

**Testing "how many projectiles did this one `update()` call spawn" needs a seen-set, not a raw
collider count.** `BossSystemTest` has no `MotionSystem`/`CleanupSystem` running, so every projectile
ever fired stays a live `ENEMY_PROJECTILE` collider forever — comparing collider counts before/after a
second volley silently includes the first volley's leftover projectiles (12 instead of 6, in this case).
The fix: track spawned entity ids in a `Set<Integer>` across calls and only report entities newly added
to it. Worth reusing any time a test needs to isolate "what did this one tick create" in a system test
that runs in isolation from the systems that would normally clean up after it.

Related: [[boss-fight-design]], [[rng-teavm-constraints]].
