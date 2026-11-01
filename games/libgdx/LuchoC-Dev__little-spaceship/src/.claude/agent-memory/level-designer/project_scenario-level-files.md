---
name: scenario-level-files
description: What a standalone scenario level file can and cannot do — the doc generator's level-NN glob, and the fact that no level file can set the player's starting state
metadata:
  type: project
---

Learned building the four test scenarios of phase 11h (#245, 03/09/2026), files
`assets/data/test-wave-04.json`, `test-wave-09.json`, `test-wave-12.json`, `test-boss.json`.

**A level file's name decides whether it becomes a document.** `tools/build-level-docs.js` discovers
level files with `/^level-\d+\.json$/` (line 1027 when this was written), so any other name under
`assets/data/` is invisible to the generator and to CI's regeneration check, while still being a
perfectly loadable level — `JsonContentSource` takes the level id from the caller and reads
`dataDir.child(levelId + ".json")`, it never lists the directory. That is what makes a throwaway or
tool-only level possible at all. Name a real campaign level `level-NN`, name anything else anything
else, and check the glob before assuming either way.

**No level file can set the player's starting state.** The schema is `boss`/`events`/`waves` and
`requireOnlyKeys` rejects the rest, and the player is built from `balance.json`'s `initialLives` /
`initialBombs` plus `Simulation.PLAYER_INITIAL_SHOT_LEVEL = 1`. The only lever content has is a
`drop` on a spawn, so "start at weapon level 4" means placing drop-carrying waves and *playing* a
prelude. Two consequences worth remembering before promising a starting state:

- A prelude costs real seconds and contaminates what follows: an `enemy-basic` on `slow-descent`
  takes roughly 15 s to cross, so its stragglers are alive inside the next wave. Fine before a boss
  (`entersAt` can be pushed past them), bad before a wave whose density is the thing under judgement.
- Reusing an existing wave for the prelude means the prelude follows the level: three placements of
  `l1-first-basics` overlapped at `-10.0` take the player 1 to 4, but only for as long as that wave
  keeps its `weapon-upgrade`. A rebalancing phase can silently un-kit the scenario.

The fix, if it is ever wanted, is a `player` block in the level file — `core-domain`'s, not content's.
See [[level-values-that-live-in-code]] for the other constants that have nowhere in `assets/data/` to
live.

**Updated 04/09/2026, phase 11i (#271), two things that cost time when building four more scenarios:**

- **A level file's `"events"` list parses but spawns nothing.** `JsonContentSource.loadLevel` still
  accepts the pre-11b flat `events` form and files it under `timelines`, but `SpawnSystem` reads only
  `world.content().placements(levelId)` — nothing in `core/` calls `ContentSource.timeline` any more.
  So `events` looks like a way to write a self-contained scenario without touching `waves.json`, and
  it is not. **Every spawn must come from a wave, and waves come from exactly one file**,
  `dataDir.child("waves.json")`. A scenario that needs a new wave has to append to `waves.json`; make
  the entry additive and `test-`prefixed and level 1 stays untouched, but there is no avoiding the
  file. The generated `docs/levels/waves.md` will then list it as `**unplaced**`, which is accurate.
- **The TESTS menu is a hardcoded list in `game/`**, not a directory scan:
  `game/src/tests/java/.../screen/TestScenarios.java`, a `List.of(Scenario(levelId, label))`. Adding
  a `test-*.json` therefore does **not** make it reachable. Content alone cannot finish a scenario —
  budget a `game-presentation` line, or say so in the fragment.
