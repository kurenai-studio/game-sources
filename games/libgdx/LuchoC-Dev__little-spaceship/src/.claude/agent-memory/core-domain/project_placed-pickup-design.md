---
name: placed-pickup-design
description: Why a placed pickup lives on WaveDefinition instead of a level-level list, the no-WaveOrigin decision that keeps Cleared waves from stalling, and reusing CleanupSystem's pickup-entity construction from SpawnSystem
metadata:
  type: project
---

Building issue #318 (`core` half of #255 — content places a pickup with no enemy involved).

**A capability that "enters the world at a scheduled time, like a spawn" belongs on the container that
already schedules spawns, not on a new level-level list.** `PlacedPickup(at, kind, atX, atY)` lives on
`WaveDefinition.pickups()` (a default method returning `List.of()`), scheduled by `SpawnSystem` with a
second per-`ActiveWave` cursor alongside the existing spawn cursor — reusing the wave's own clock
instead of inventing level-time scheduling for a capability with exactly one shape of user. This is the
same "narrow thing, not a placement engine" call invariant 6 forces every time; the alternative (a
level-level list parallel to `WavePlacement`) would have needed its own absolute-vs-relative-time
question that waves already answered.

**A pickup that carries `WaveOrigin` can silently deadlock a `Cleared` wave.** `WaveEndCondition.Cleared`
asks "does any entity still carry this wave's id" — if a placed (or dropped) pickup carried that tag,
a level could never complete until the player collected a reward they have no obligation to collect.
`CleanupSystem.spawnDropIfAny` already got this right by omission (it never tagged a dropped pickup with
`WaveOrigin`); the placed-pickup path had to match that omission on purpose, not by luck, and a dedicated
test (`placedPickupCarriesNoWaveOrigin`) pins it. Worth checking this exact question — "does the new
entity carry a tag some end condition or cleanup rule scans for, and should it?" — any time a new kind
of entity enters through `SpawnSystem`.

**Reuse across `SpawnSystem` and `CleanupSystem` is a package-private static method, not a new type.**
Both systems build the exact same five-component pickup entity (`Transform`, `Collider`, `Sprite`,
`Pickup`, falling `Motion`); they're in the same package (`domain.system`), so making
`CleanupSystem.spawnDropIfAny`'s inner logic a package-visible `static createFallingPickup(world, x, y,
kind)` and calling it from `SpawnSystem` avoided duplicating it, with no new abstraction, no new file.

**Validating a content id "at load" in this codebase usually means "at spawn time during simulation,"
not "when the JSON is parsed."** The existing precedent for the identical problem — an enemy's
unrecognised `Drop.pickupId` — is checked in `SpawnSystem.spawnWave` when that specific wave's placement
becomes due, not eagerly when `SimpleWaveDefinition` is constructed. `PlacedPickup`'s kind validation
(`PickupSystem.isRecognisedKind`) follows the same precedent for consistency, even though the issue's
acceptance criterion says "refused at load" — a level with a wave nobody reaches would never surface a
bad drop id either, under the existing design, so this isn't a new gap. Flagged this reading explicitly
in the status fragment rather than silently picking one interpretation.

Related: [[wave-content-contract]], [[boss-fight-design]], [[pickup-fall-and-lifetime]].
