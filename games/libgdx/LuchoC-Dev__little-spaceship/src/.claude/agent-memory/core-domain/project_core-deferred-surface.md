---
name: core-deferred-surface
description: What the core deliberately leaves unimplemented, and which phase owns each gap
metadata:
  type: project
---

The core grew deliberately incomplete: each phase adds only what its own systems need. Knowing what was left out **on purpose** stops it being re-decided as if it were an oversight.

**How to apply:** before adding a type to `core.port` or a component to the domain, check whether it was deferred here with a reason.

> **Corrected on 26/08/2026 by the phase 10b memory audit.** Two entries below had gone stale, and the
> reason is structural rather than careless: this file tracks *what was built in which phase*, which
> `CLAUDE.md` says belongs in `status.md` and not in memory, so every phase silently falsifies it. The
> entries are now marked where they were wrong. Read the bullets for **why** something was left out;
> do not trust them for **whether** it still is — `git grep` answers that in a second.

- `WorldView.player()` — **built in phase 03.** `WorldView.bossStatus()` — **built in phase 07**,
  a `(present, hp, hpMax)` snapshot only; per-part tell state deliberately has no contract of its own
  — see below.
- `ContentSource.enemy()`, `.trajectory()`, `.formation()` and `.timeline()` — **built in phase 04.**
  `ContentSource.pattern()` is not: see below. `.hasBoss()`/`.boss()` — **built in phase 07.**
- Concrete `GameEvent` implementations — ~~still deferred as of phase 07~~ **partly built: `EnemyDestroyed` exists in `core/domain/event/`.** The reasoning below still holds for the ones that do not (`PlayerHit`, `AttachmentLost`).
  `DamageSystem` and `CollisionSystem` remain the natural emitters per `12-architecture.md`
  (`PlayerHit`, `AttachmentLost`); phase 07 needed a "boss fight started" signal for the music-change
  hook and deliberately did *not* become the first to build a `GameEvent` for it — `BossStatus.present`
  flipping is the same edge `game-presentation` already has to poll `WorldView` for on every frame, so
  a second, parallel event-based channel had no real consumer to justify its shape yet. Revisit if a
  future need cannot be read off an existing snapshot the same way.
- `Health` component — **built in phase 05**, and this entry was wrong once already: an earlier
  version of it said "still does not exist" and treated the gap as an undecided future mechanic.
  It was not undecided — `12-architecture.md`'s component table names it and its JSON schema example
  gives a tank `"health": {"points": 40}` — it had simply never been built, because phase 04 modelled
  fragility as `Collider.fragile` instead and this phase's `plan.md` did not list
  `12-architecture.md` among its required reading. A coordinator review caught the miss mid-phase.
  See [[core-deferred-surface]]'s own lesson below and `game-systems-design.md` for the
  `fragile`/`Health` relationship phase 05 settled on.
- `Weapon` component — **built in phase 05**, holds only the fire cooldown timer; `Player.shotLevel`
  still carries the persistent upgrade level, per phase 02's "persistent state lives on `Player`"
  precedent.
- A `PatternDefinition`/`ContentSource.pattern()` content contract — **still deferred**, even though
  `WeaponSystem` now exists. The four weapon levels' shot counts and shapes are fixed data read
  straight from `docs/design/02-sprite-sizes.md`'s table and hardcoded as constants inside
  `WeaponSystem`, the same way `Simulation` hardcodes the player's sprite id and collider radius from
  a synchronisation-point document. Nothing in the MVP asks for a second weapon pattern, so there is
  still no real second case to generalise a content contract against.
- `Lifetime` component — still deferred even though `LifetimeSystem` now exists (phase 05): it
  expires projectiles by playfield position, not by a timer, so it never needed the component.
- `Spawner` component — **built in phase 07**, later in the same phase than the report that first
  flagged it as an unbuilt gap: the coordinator came back mid-phase and said the strong encounter's
  own reason for existing (two heavy carriers producing "sustained pressure" instead of two large,
  stationary targets) depended on it, so the initial "no consumer yet" call was corrected before the
  PR closed rather than left as a follow-up issue. ~~`enemy-shooter`'s higher rate of fire is still
  unbuilt — no `"weapon"` factory for enemies exists~~ — **built after phase 07**: `ComponentFactoryRegistry`
  registers `"weapon"`, the component is `EnemyWeapon`, and every archetype in `assets/data/enemies.json`
  declares one.
- `ScoreValue`, `Drop` components — built in phase 04, **now read** (phase 05): `ScoreValue` by
  `ScoreSystem`, `Drop` by `CleanupSystem`, which turns it into an actual `Pickup` entity read in
  turn by `PickupSystem`.
- `SystemOrder` stages with no system registered yet: only `INPUT` — every other stage is filled as
  of phase 05. `BOMB` is a new stage phase 05 inserted between `WEAPON` and `SPAWN`; `BOSS` is a new
  stage phase 07 inserted between `SPAWN` and `LIFETIME` (a second, independent per-tick timeline
  alongside the wave one, not a wave itself, so it does not share `SPAWN`'s stage). `SPAWNER` is a
  second stage phase 07 inserted, between `SPAWN` and `BOSS` specifically — ticks down every entity's
  `Spawner` component and creates a child when one is due, the heavy carrier's periodic spawn.

See [[core-boundary-decisions]], [[defensive-chain-and-collision-design]] for the boundary shape
those additions have to respect, [[game-systems-design]] for the damage/scoring/pickup shape phase
05 settled on, and [[rng-teavm-constraints]] for what stays reproducible across runtimes. Current
implementation state — what phase added what — lives in `docs/plan/*/status.md`, not here.
