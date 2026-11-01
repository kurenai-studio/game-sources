---
name: wave-loader-flattening-bridge
description: JsonContentSource loading waves.json and a level's wave/placement references (#113) — a load-time flattening bridge that existed for one PR revision, then was deleted once #112 merged
metadata:
  type: project
---

**This is a corrected memory — the first version described the flattening bridge as the design.
It was removed within the same PR (#120) once #112 merged, before the phase closed.** Kept because
the reason it existed and the reason it had to go are both non-obvious and could recur: any time a
`core` contract lands before the system that consumes it, `game`'s loader is the one under pressure
to make something runnable in the gap, and whatever it builds to do that needs to come back out.

**Timeline:** #111 (the wave content contract: `WaveDefinition`, `WaveEndCondition`,
`WavePlacement`, `ContentSource.wave(String)`) merged first. I implemented #113
(`JsonContentSource` reading `waves.json`) against that, while #112 (`SpawnSystem` reading
`wave()`/`placements()` directly, resolving both end conditions at runtime) was still open. Since
`SpawnSystem` only read `ContentSource.timeline(String)` — the legacy flat, absolute-time
`SpawnEvent` list — at that point, a level's new `"waves"` placements had nowhere to go except
flattened at load time into that same `WaveTimeline`, which only worked for `FixedDuration` waves
(a `Cleared` wave's end is a runtime fact a loader can't precompute) and had to reject a `Cleared`
placement outright. #112 then merged into the same phase branch, mid-review, and the flattening
became the wrong design in one step: it silently reimplemented scheduling `SpawnSystem` now does
itself, and it was the reason a `Cleared` wave could never load through the only path the shipped
game uses — one of the phase's two required end conditions was unreachable.

**Final shape, after #112:** `ContentSource.timeline(String)` stayed **abstract** (per #112's own
`ContentSource` javadoc) for a level still on the legacy `"events"` block; `wave(String)` and
`placements(String)` — both `default`-throwing until an adapter overrides them — became the real
path. `JsonContentSource.wave(id)` hands back a `WaveDefinition` exactly as declared (spawns'
`at` left relative to the wave's own start); `placements(levelId)` hands back the level's
`List<WavePlacement>` exactly as declared (offset and wave id untouched) — the only load-time
validation left is resolving each placement's wave id against `waves.json`, so a typo still fails
loudly naming the level and the id rather than surfacing later as `SpawnSystem`'s own unqualified
failure. No shifting, no merging, no sorting, no rejecting `Cleared`. A level file still allows
exactly one of `"events"`/`"waves"`; a level using `"waves"` is simply absent from `timelines` and
`timeline()` on its id throws the same "unknown level timeline id" any other unresolved lookup
would.

**`waves.json` stayed optional** (`FileHandle.exists()` guard) through both revisions, since
`level-01.json` still uses `"events"` and `assets/data/waves.json` does not exist in the repo yet
— an unconditional load would have broken the real game at startup either way.

See `[[libgdx-jsonvalue-key-iteration]]` for the scratch-classpath technique used to re-verify all
eleven cases (including the two whose expected outcome flipped — a `Cleared` placement now loads
instead of being rejected, and `placements()` itself is what rejects an unknown wave id) against a
`core.jar` rebuilt from the merged branch, without a `game` test suite.
