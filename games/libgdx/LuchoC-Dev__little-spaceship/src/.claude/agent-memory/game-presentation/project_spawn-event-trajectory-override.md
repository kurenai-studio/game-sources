---
name: spawn-event-trajectory-override
description: parseSpawnEvent reads an optional "trajectory" key that is deliberately unvalidated at load time, matching enemyId/formationId
metadata:
  type: project
---

`JsonContentSource.parseSpawnEvent` (`game/adapter/content/JsonContentSource.java`) reads a seventh,
optional key, `"trajectory"`, via `entry.getString("trajectory", null)`, passed straight to
`SpawnEvent`'s seven-argument constructor. Issue #164, phase 11c.

**Deliberately not resolved against `ContentSource` in this loader**, on purpose, to match how
`enemyId`/`formationId` already behave: `SpawnEvent`'s own compact constructor validates everything
except `trajectoryId`; an unknown id parses clean and only fails later, when `SpawnSystem` actually
resolves it via `ContentSource.trajectory(id)` (`IllegalArgumentException: unknown trajectory id '…'`).
Making `"trajectory"` the one eagerly-validated field would have been the inconsistent choice, and it
can't fully validate anyway — `loadWaves` may run before `trajectories.json` depending on file order,
and the legacy `loadLevel` path holds no `ContentSource` reference to check against. `requireOnlyKeys`
still catches a *misspelled key* (syntax) at load time; a *well-formed but nonexistent* id (semantics)
is a `SpawnSystem`-time failure. See [[requireOnlyKeys-guards-every-json-object]] for the general
pattern this follows.

`parseSpawnEvent` is one method shared by two call sites — a wave's `"spawns"` list (`loadWaves`) and
the legacy flat `"events"` timeline (`loadLevel`) — so the key works identically in both without any
extra code; that symmetry is correct, nothing marks the legacy path as reduced-capability.

Verified via the same reflection-over-compiled-classes trick as #163 (see
[[libgdx-jsonvalue-key-iteration]] for the classpath recipe): with the key present, without it, with
an unrecognised JSON key (rejected), and with a syntactically fine but nonexistent trajectory id
(parses clean, then fails loudly the moment `content.trajectory(id)` is actually called).
