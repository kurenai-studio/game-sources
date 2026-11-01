---
name: wave-content-contract
description: Adding WaveDefinition/WavePlacement/WaveEndCondition/ContentSource.wave(id) for #111 — why the new lookup is a default method, why WaveTimeline was left untouched in code, and the offset-placement correction.
metadata:
  type: project
---

Phase 11b, task 3 (#111, PR #119 against `phase/11b-wave-system`). Added `WaveDefinition` (id, spawns,
endCondition — three things), `WavePlacement` (waveId, offsetSeconds), `WaveEndCondition` (sealed:
`FixedDuration`/`Cleared`) and `SimpleWaveDefinition` to `core.port` — the ninth content kind.

**A new `ContentSource` method has to be a `default` method, or it breaks a module you don't own.**
`ContentSource` is implemented in exactly two places: `core`'s own `TestContent` (test support, mine
to update) and `game`'s `JsonContentSource` (not mine to touch). `tools/pre-pr-check` runs
`./gradlew build` for the whole repo whenever `core/` changes — not just `:core:test` — so an abstract
method added to `ContentSource` fails the check by breaking `game`'s compile, even though the diff
that caused it never touched a file outside `core/`. `ContentSource.wave(String id)` is a `default`
method that throws `UnsupportedOperationException` naming the issue that will override it (#113), so
`game` keeps compiling untouched until that PR lands. Checked precedent: `hasBoss()`/`boss()` were
added as *abstract* methods in commit `ce48e9e`, and `game`'s `JsonContentSource` was fixed in a
separate commit (`2ddab6e`) — that gap must have broken the whole-repo build for whoever's `pre-pr-check`
ran in between, or that pairing was coordinated in the same PR window. Don't assume abstract-by-default
is safe just because it happened before; check whether `./gradlew build` (not just `:core:test`) stays
green before opening the PR.

**A task that says "you may not touch system X" can still be blocked by X being the only consumer of
the type you're asked to redesign.** `WaveTimeline` is `SpawnSystem`'s only consumer
(`world.content().timeline(levelId).events()`). The task asked me to decide whether `WaveTimeline`
"gains a layer above it or its name stops matching," but literally reshaping it would have broken
`SpawnSystem`'s compile — out of bounds for this task, in scope for #112. Resolved it as a doc-only
change: `WaveTimeline`'s javadoc now says explicitly that it's superseded-but-not-retired and names the
task that migrates it, instead of silently drifting out of sync with the new `WaveDefinition` contract
sitting next to it. `SpawnEvent` is reused by both the legacy `WaveTimeline` (level-relative `at`) and
the new `WaveDefinition.spawns()` (wave-relative `at`) — its doc was generalised to not assume a single
reference frame, since it's genuinely just "a timestamped spawn," and the container decides what zero
means.

**Corrected after review: a "declares these four things" list is not evidence they belong on one
type — reuse semantics outrank the literal grouping.** Issue #111 lists "an id, its spawns, one end
condition, its placement" as what a wave declares, and I read that as license to put `offsetSeconds()`
directly on `WaveDefinition`, since the issue phrased placement as one of *the wave's* four properties.
That was wrong: the project owner caught it by reading my own `WaveDefinition` javadoc back at me — it
claimed the id-lookup "lets the same wave id be referenced twice... without copying anything," which is
false the moment the wave itself carries where it starts, since both references are then forced to
share one offset. The tell was already sitting in my own doc; I didn't re-read it against the reuse
claim before shipping. Fixed by moving `offsetSeconds()` onto a new `WavePlacement` record (`waveId`,
`offsetSeconds`) — the type a level's ordered sequence becomes — leaving `WaveDefinition` with three
properties. **Lesson: when a spec lists several properties as belonging to one thing, check each one
against what the surrounding prose independently claims that thing can do (here, "reusable") before
building it as one record — a list format flattens a structural distinction the surrounding text
already contradicts.**

See [[project_content-pipeline-design]] for the general ComponentSpec/registry pattern this follows,
and [[project_game-systems-design]] for why an optional-per-archetype component (the same shape
`WaveEndCondition` avoids by being sealed instead) can drift the wrong way.

**Update (#122, PR #124):** once `JsonContentSource` implemented both methods (#113), the defaults on
`wave(String)` and `placements(String)` were retired — both are abstract again. Confirmed by
`git grep -ln "implements ContentSource"` that only `JsonContentSource` (game) and `TestContent`
(core test support) exist, so nothing else could have silently inherited the throwing default.
