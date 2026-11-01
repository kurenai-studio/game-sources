# 11h task 5 — the boss scenario carries no prelude enemies (#251)

`level-designer`, branch `fix/boss-scenario-alone`, on `assets/data/test-boss.json` only.

A correction to task 2 (`docs/plan/11h-test-mode/status/245-test-scenarios.md`), asked for by the
project owner reviewing PR #249: *"if the test is for the boss only the boss should appear, no
pre-enemies"*.

## The change

`assets/data/test-boss.json` now holds the boss block and an empty `"waves": []`. The three
overlapping `l1-first-basics` placements are gone, and with them the twelve `enemy-basic`s and the
`weapon-upgrade` carrier that used to bring the player to weapon level 4 before the boss entered.

An empty placement list is accepted, not a loophole: `JsonContentSource.loadLevel`
(`game/src/main/java/dev/luchoc/littlespaceship/game/adapter/content/JsonContentSource.java:346`)
requires the file to carry `"events"` or `"waves"`, and `parsePlacements` (`:384`) iterates whatever
is there — zero entries resolve to an empty `List<WavePlacement>`. Verified below.

**Every boss field other than `entersAt` is `level-01.json`'s verbatim.** Confirmed by loading both
levels and comparing the parsed records field by field (output quoted below): the two
`SimpleBossDefinition`s differ in `entersAt` and in nothing else.

## `entersAt`: 26.0 to 2.0

26.0 existed to let the prelude play. With no prelude it is 26 seconds of empty sky per iteration,
which is exactly the cost this phase exists to remove.

It is not 0.0, because the boss would then spawn on the first simulated frame, before the player has
taken the stick. 2.0 buys that beat and nothing more.

The entrance is not instant and does not need padding on top. `BossSystem` spawns the core at
`CORE_SPAWN_Y = PLAYFIELD_HEIGHT + (CORE_KEEL_RADIUS - CORE_KEEL_OFFSET_Y)` =
`270 + (13 - (-27))` = **310** (`core/.../system/BossSystem.java:163`, `:82`, `:92`;
`SpawnSystem.java:92`), and descends to `combatY` 175.0 at `entranceSpeed` 25.0 px/s — 135 px, **5.4
s**. So the boss reaches its fighting position around **t = 7.4 s**, against 31.4 s before.

## What starting cold costs and what it buys

The owner allowed *"at most leave power-ups"*, and **the content format cannot express that
today**. A pickup exists only as the consequence of a holder dying — `CleanupSystem.java:65`,
`spawnDropIfAny`, reads the dying entity's `Drop` and `Transform` — so the only way to hand the
player a power-up is to make them kill something for it, which is the prelude the owner just
rejected. Inventing a standalone pickup placement is out: `JsonContentSource:349` rejects any
top-level key other than `boss`, `events`, `waves`, and the mechanism would be `core-domain`'s. Filed
as **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255)**.

**Corrected on 03/09/2026.** This paragraph first cited **#252**, which is a different problem — a
dropped pickup having no `Motion` and hanging in the air. The two are neighbours in
`CleanupSystem` and they are not the same: #252 is how a pickup behaves once it exists, #255 is the
absence of any way to make one exist without an enemy dying. **The wrong number came from the
coordinator's launch prompt, not from this branch**, and `reviewer` caught it by checking the
citation against what the issue actually said rather than against what it was called.

So the scenario starts at weapon level 1, three lives, two bombs
(`core/application/Simulation.java:66` `PLAYER_INITIAL_SHOT_LEVEL = 1`; `balance.json`
`initialLives`, `initialBombs`).

- **It buys** the thing the scenario is named for: the boss, alone, seven seconds from launch, with
  nothing else on screen to attribute a projectile or a collision to.
- **It costs** the signed-off damage race. In `level-01.json` the player meets `boss-l1` at weapon
  level 4 with an `attachment`; here the same 1800/500/500 hit points are chewed through at a
  quarter of the trigger output (`balance.json` `weaponLevels`), so the fight runs several times
  longer.

I agree with the brief's opinion, and would sharpen it: for **watching how the boss attacks**, which
is the case the owner named, the longer fight is the feature — more cycles of spread and sweep
observed per launch, and no chance of deleting a phase before it is read. Where cold is genuinely
wrong is **judging the fight's balance**, which this file cannot support until [#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255) exists. Anyone
reading a difficulty conclusion out of this scenario is reading it out of the wrong file.

## Verification

`JsonContentSource` over the real `assets/data`, all five levels (no test source set exists in
`game/`, so this is a throwaway `main` — see the loader note in the agent's memory):

```
test-boss loaded; hasBoss=true boss=SimpleBossDefinition[id=boss-l1, entersAt=2.0, coreHealth=1800, podHealth=500, armHealth=500, corePoints=1500, podPoints=500, armPoints=500, entranceSpeed=25.0, combatY=175.0, patternCooldown=0.7, spreadProjectileSpeed=85.0, sweepProjectileSpeed=125.0] placements=[]
test-wave-04 loaded; hasBoss=false placements=[WavePlacement[waveId=l1-combined-formations, offsetSeconds=0.0]]
test-wave-09 loaded; hasBoss=false placements=[WavePlacement[waveId=l1-high-pressure, offsetSeconds=0.0]]
test-wave-12 loaded; hasBoss=false placements=[WavePlacement[waveId=l1-final-escalation, offsetSeconds=0.0]]
level-01 loaded; hasBoss=true boss=SimpleBossDefinition[id=boss-l1, entersAt=134.5, coreHealth=1800, ... spreadProjectileSpeed=85.0, sweepProjectileSpeed=125.0] placements=[12 placements, unchanged]
```

`node tools/build-level-docs.js`:

```
unchanged  docs/levels/level-01.md
unchanged  docs/levels/waves.md
```

`git status --short` after that run shows `M assets/data/test-boss.json` and nothing else — level 1,
`waves.json`, `formations.json` and `trajectories.json` are untouched, and the other three scenarios
are untouched.

**Whether the fight reads right at weapon level 1: not checked.** That is the project owner's to
judge by playing it. The game was not launched for this change — the edit removes content and the
loader check covers the file being well-formed, so a launch would have added nothing.
