# 11h task 2 — the four test scenarios (#245)

`level-designer`, branch `feat/test-scenarios`, on `assets/data/` only.

## What was added

Four scenario files, each a level file in the existing format. **Nothing was added to the format**
and nothing in level 1 was touched — the diff is four new files and this fragment.

| Scenario id (file) | Content | Saves |
|---|---|---|
| `test-wave-04` (`assets/data/test-wave-04.json`) | one placement, `l1-combined-formations` | 33.0 s |
| `test-wave-09` (`assets/data/test-wave-09.json`) | one placement, `l1-high-pressure` | 88.0 s |
| `test-wave-12` (`assets/data/test-wave-12.json`) | one placement, `l1-final-escalation` | 119.5 s |
| `test-boss` (`assets/data/test-boss.json`) | `boss-l1` at `entersAt` 26.0, after a three-placement weapon prelude | 108.5 s |

**The ids `game-presentation` needs are the file names without `.json`**: `test-wave-04`,
`test-wave-09`, `test-wave-12`, `test-boss`. `JsonContentSource` loads a level as
`dataDir.child(levelId + ".json")` (`game/adapter/content/JsonContentSource.java:93`), so the id *is*
the file stem, and `game/LittleSpaceshipGame.java:42`'s `LEVEL_ID` is the one field a TESTS entry has
to replace.

**The names deliberately do not match `level-NN`.** `tools/build-level-docs.js:1027` discovers level
files with `/^level-\d+\.json$/`, so a scenario named `level-02.json` would have generated a
`docs/levels/level-02.md` and changed the index. Named `test-*.json`, the generator ignores them.

## The starting state each scenario assumes, and why

The level file cannot express a starting state. Its schema is `boss`, `events`, `waves` and nothing
else (`JsonContentSource.java:349`, `requireOnlyKeys`), and the player is constructed from
`balance.json`'s `initialLives` (3) and `initialBombs` (2) plus
`core/application/Simulation.java:66`, `PLAYER_INITIAL_SHOT_LEVEL = 1`, used at `:210`. **Every
scenario therefore starts at weapon level 1, three lives and two bombs, unless it earns otherwise
from drops it spawns itself.** The only lever content has is `drop`/`dropSlot` on a spawn, which
means playing a prelude.

In the signed-off level the player reaches each of these moments with:

| Moment | Weapon level there | Why |
|---|---|---|
| wave 4, 33.0 s | **2** | only `l1-first-basics`' `weapon-upgrade` carrier, spawned at 11.0 s |
| wave 9, 88.0 s | **4** (the cap, `balance.json` `weaponLevels`) | plus `l1-tanks-and-priority` (48.0 s) and `l1-evolved-shooters` (86.0 s) |
| wave 12, 119.5 s | **4** | the same three, plus `shield`, `extra-life`, `attachment`, `bomb-recharge` |
| boss, 134.5 s | **4** | the same |

The three wave scenarios ship **cold: weapon level 1, no prelude.** That is a deliberate trade and a
real deviation from the signed-off encounter, stated here rather than hidden. The reasoning:

- What phase 11i iterates on in these waves is **movement, grouping, entrances and space** — where a
  formation enters, how two of them read together, whether the player has room. Those read the same
  at weapon level 1 as at 4. What does *not* survive the difference is a damage race, and none of
  these three waves is one.
- The only way to reach weapon level 4 in content is to replay drop-carrying waves. The cheapest
  honest prelude is about 20 s plus a clearing gap, which puts back a third of the cost this phase
  exists to remove — and it leaves `enemy-basic`s from the prelude alive inside the wave under test
  (a basic on `slow-descent` needs roughly 15 s to cross the playfield), contaminating exactly the
  density the scenario exists to judge.
- Cold also lets the wave start at t = 0, which is the fastest loop available.

**If the project owner judges wave 12 unreadable at weapon level 1, the fix is not a content one** —
see "What it would take". Do not invent a key: an unnamed key is a level that fails to load.

`test-boss` is the exception and ships **kitted to weapon level 4**, because the boss *is* a damage
race: `coreHealth` 1800 with `core-keel` carrying the core's health independently makes the kill
target effectively 3600, and one trigger pull fires 1/2/3/5 projectiles by weapon level. At level 1
it is not a longer version of the signed-off fight, it is a different fight. The prelude is three
placements of the existing `l1-first-basics`, overlapped by `-10.0`, so the waves start at 0.0, 4.0
and 8.0 and their `weapon-upgrade` carriers spawn at 3.0, 7.0 and 11.0 — 1 to 4, the cap. The last
prelude spawn is at 20.0; `entersAt` is **26.0**, and with `entranceSpeed` 25.0 from y 310 to
`combatY` 175.0 the core is in position at 31.4 s, by when the prelude basics have left the
playfield. **Nothing about the boss itself was changed**: every other field is `level-01.json`'s
verbatim.

Caveats on `test-boss`, so it does not quietly lie: the player arrives with 3 lives and 2 bombs and
no `shield`, where the real fight follows `l1-brief-rest`'s `bomb-recharge` and may carry an
`attachment` and a `shield`; and a player who misses a `weapon-upgrade` in the prelude fights the
boss under-levelled with no second chance.

## What it would take to set a starting state properly

Two options, both code, neither this task's:

1. **A `player` block in the level file** — `weaponLevel`, `lives`, `bombs` — parsed by
   `JsonContentSource` and read where `Simulation.java:210` builds the `Player`. Keeps the scenario a
   single self-describing file; costs a schema change in `core.port` plus the parser. `core-domain`.
2. **The TESTS menu setting it** when it launches a scenario, with the starting state named beside
   the scenario in the menu. No format change; the knowledge then lives in `game/` rather than in the
   content. `game-presentation`.

Option 1 is the one this agent would argue for, but the decision is not mine and the phase does not
need it to ship.

## Verification

- **All four load through the real parser.** A throwaway `LoadCheck` main compiled against
  `core.jar`, `game.jar` and `gdx-1.14.2.jar`, building a real `JsonContentSource` over
  `assets/data`, printed:

  ```
  level-01 OK boss=true entersAt=134.5 placements=[l1-opening-calm@0.0 ... l1-final-escalation@0.0]
  test-wave-04 OK boss=false placements=[l1-combined-formations@0.0]
  test-wave-09 OK boss=false placements=[l1-high-pressure@0.0]
  test-wave-12 OK boss=false placements=[l1-final-escalation@0.0]
  test-boss OK boss=true entersAt=26.0 placements=[l1-first-basics@0.0 l1-first-basics@-10.0 l1-first-basics@-10.0]
  ```

- **`docs/levels/` still regenerates identically.** `node tools/build-level-docs.js` printed
  `unchanged  docs/levels/level-01.md` and `unchanged  docs/levels/waves.md`, and
  `git status --porcelain` afterwards listed only the four new `assets/data/test-*.json`.
- **Level 1 untouched.** `git status --porcelain` shows `assets/data/level-01.json`, `waves.json`,
  `formations.json` and `trajectories.json` unmodified; the only changes on this branch are four new
  files plus this fragment.
- **Not checked:** how any scenario plays. No scenario was launched and the game was not run from
  this branch at all. Whether wave 12 is readable at weapon level 1, whether the boss prelude is dull
  to sit through, and whether 26.0 is the right `entersAt` are questions only playing answers, and
  playing is the project owner's.
- **Not checked:** the TESTS menu. Task 1 is in flight on another branch and nothing here depends on
  it beyond the four ids.

## Open for whoever comes next

- The starting-state gap above is the one real open item, and the thing most likely to make a
  scenario mislead.
- If 11i changes `l1-first-basics`, `test-boss`'s prelude changes with it — it references the wave by
  id on purpose, so it follows the level rather than freezing a copy. If 11i removes that wave's
  `weapon-upgrade`, `test-boss` silently stops kitting the player. Worth a grep before touching it.
