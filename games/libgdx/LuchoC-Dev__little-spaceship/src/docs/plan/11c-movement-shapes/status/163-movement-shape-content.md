# 163 — a movement shape is named content

**Half written by `core-domain`.** `level-designer` appends its own half below, for the
`assets/data/trajectories.json` entries, once this half has landed.

## What was built

`core/port/TrajectoryDefinition.java` is now a sealed interface, mirroring `WaveEndCondition`'s
pattern, permitting exactly two records:

- `SimpleTrajectoryDefinition(id, vx, vy)` — unchanged constructor and validation, now documented as
  the catalogue's `constant` shape. `velocityAt` ignores elapsed time.
- `ArcTrajectoryDefinition(id, vx, vy, ay)` — new, the catalogue's `arc` shape. Rejects a missing id
  and any non-finite `vx`/`vy`/`ay`.

Both implement a new method, `float verticalVelocityAt(float elapsedSeconds)`: `constant` returns
`vy` unconditionally, `arc` returns `vy + ay * elapsedSeconds` — the closed form the catalogue's "For
#163" section asked to be picked deliberately rather than accumulated tick by tick. `vx()` stays
time-independent for both kinds, per the catalogue's refusal of horizontal acceleration, so no
`horizontalVelocityAt` was added.

`ComponentFactoryRegistry.attachMotion` is unchanged in behaviour — it still snapshots a trajectory's
velocity once, at spawn, into `Motion`. Its javadoc now says explicitly that this snapshot does not
keep re-evaluating an `arc`'s vertical velocity after spawn, and names #164 as the issue that wires a
`Trajectory` component and a per-tick re-evaluation into `MotionSystem`. This PR does not touch
`MotionSystem` at all — no `SystemOrder` change, per invariant 5 and the acceptance criteria.

No `ContentSource` method signature changed: `trajectory(String id)` already returned
`TrajectoryDefinition`, so both kinds resolve through the one existing lookup.

Tests added to `ContentDefinitionsTest`: the constant shape ignores elapsed time; `ArcTrajectoryDefinition`
validates id and every parameter's finiteness; the closed-form formula is checked against the
catalogue's own `strike-run` numbers (turns at `t = -vy/ay = 4.07s`); `ay = 0` degenerates to a flat
line without being routed through `SimpleTrajectoryDefinition`.

## The exact JSON shape expected

For a `constant` entry (unchanged, the four that already ship):

```json
{ "id": "slow-descent", "vx": 0, "vy": -18 }
```

For an `arc` entry:

```json
{ "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 }
```

`"type"` is optional and defaults to `"constant"` — the four existing entries need no edit.

## What is NOT done, and why — a gap in the plan worth flagging

**`game/JsonContentSource.loadTrajectories` was not touched.** It still reads exactly `id`, `vx`,
`vy` and ignores an unknown key, so today an `arc` entry would load silently as a `constant` — the
exact trap the plan's "Watch out" section and the shape catalogue's own "For #163" section describe,
and the shape catalogue says outright: "The entries land in the same pull request as the parser that
reads them."

`JsonContentSource.java` lives in `game/`, which is `game-presentation`'s module, not `core-domain`'s
— my own agent boundary is "you write only inside `core/`", reinforced by three earlier memory entries
("not mine to touch") on this exact file. The task's own scope line ("`core/` only — the `core.port`
contract, the `ContentSource` lookup and the JSON reading") names JSON reading as in-scope, but the
only place `JsonReader`/`JsonValue` exist in this repository is `game/` — `core` has no libGDX
dependency, checked (`core/build.gradle` declares nothing beyond the JDK). I judged the module
boundary in `CLAUDE.md`'s agent table to outrank the task's own scope wording, which reads as
imprecise rather than a deliberate widening.

**Consequence:** the parser update — reading `"type"`, defaulting to `"constant"`, constructing
`ArcTrajectoryDefinition` for `"arc"`, and rejecting any other value loudly (naming the trajectory id
and the bad type) — still needs to land before `level-designer` adds `arc` entries to
`trajectories.json`, or those entries load silently wrong. This is the change needed, spelled out so
whoever picks it up does not have to re-derive it:

```java
private void loadTrajectories(JsonReader reader, FileHandle file) {
    inFile(file, () -> {
        for (JsonValue entry : reader.parse(file).get("trajectories")) {
            TrajectoryDefinition trajectory = parseTrajectory(entry);
            trajectories.put(trajectory.id(), trajectory);
        }
        return null;
    });
}

private static TrajectoryDefinition parseTrajectory(JsonValue entry) {
    String id = entry.getString("id");
    String type = entry.getString("type", "constant");
    if ("constant".equals(type)) {
        return new SimpleTrajectoryDefinition(id, entry.getFloat("vx"), entry.getFloat("vy"));
    }
    if ("arc".equals(type)) {
        return new ArcTrajectoryDefinition(
            id, entry.getFloat("vx"), entry.getFloat("vy"), entry.getFloat("ay"));
    }
    throw new IllegalArgumentException("trajectory '" + id + "' has an unknown type '" + type + "'");
}
```

I recommend the coordinator route this to `game-presentation` before `level-designer`'s entries land,
or fold it into whichever branch does #164 (also `core-domain`, but #164's own scope explicitly
excludes `game/` too — the same boundary question would recur there).

## Acceptance criteria — my half

- One archetype, two shapes: not demonstrable yet from this PR alone — `ComponentFactoryRegistry`
  still resolves one trajectory id per archetype, one snapshot at spawn; the override lives in #164's
  `SpawnEvent` change. Not this PR's criterion to close.
- A shape that is not a constant vector exists and is followed: `ArcTrajectoryDefinition` exists and
  its `verticalVelocityAt` is tested against the catalogue's own worked numbers. "Followed" by a
  running entity is #164's wiring; the shape itself is built and correct here.
- Determinism replays pass: `./gradlew :core:test` is green, unchanged from before this branch —
  nothing here is wired into any system's per-tick behaviour yet, so nothing new could have broken a
  replay.
- `DeterminismRulesTest` stays green: confirmed, part of the same green `:core:test` run.
- `SystemOrder` unchanged: confirmed, no file under `core/domain/system/` was touched.
- Javadoc: `TrajectoryDefinition`'s own class javadoc no longer claims curves are not built — the one
  sentence that became false by this diff was corrected. The fuller closing pass across `Motion.java`
  and the roadmap is #86's, explicitly not mine per the task dispatch.

## `pre-pr-check`

Run against `phase/11c-movement-shapes`, output pasted in the pull request once `level-designer` has
appended its half and the branch is ready.

---

## `game-presentation`'s half — the loader itself

Followed `core-domain`'s recommended diff, with one addition: `requireOnlyKeys` on each entry, matching
the strictness the rest of this class already applies to a wave's end condition and a level's top-level
blocks. Without it a `constant` entry carrying a stray `ay` would parse clean and silently drop the
value — the same "unrecognised key loads clean and does nothing" gap #163's own class javadoc says
this file exists to close.

`JsonContentSource.parseTrajectory` (`JsonContentSource.java:157-186`) now reads `"type"`, defaulting
to `"constant"` when absent — via `entry.getString("type", "constant")`, so the four entries shipped
before `"type"` existed need no edit — and switches on it: `"constant"` builds a
`SimpleTrajectoryDefinition` after checking the entry carries only `id`, `type`, `vx`, `vy`; `"arc"`
builds an `ArcTrajectoryDefinition` after checking `id`, `type`, `vx`, `vy`, `ay`. Any other value
throws `IllegalArgumentException`, naming both the trajectory id and the bad type — the loader used to
accept anything and silently discard unknown keys, which is the exact defect the task exists to close.

**Verified without a test source set** (`game/build.gradle.kts` declares no `testImplementation`; see
this agent's own memory on the classpath trick). Compiled `:game:compileJava` clean, then ran a
throwaway program against the real compiled classes and the real `gdx-1.14.2.jar`, invoking the
private `parseTrajectory(JsonValue)` through reflection so no `ContentSource` had to be fully
constructed (that needs `balance.json`, `enemies.json`, `formations.json`, `attachments.json` and a
level file, none of which this task touches):

- The four existing entries (`slow-descent`, `swoop`, `dive`, `crawl`, taken verbatim from
  `assets/data/trajectories.json`) load as `SimpleTrajectoryDefinition` with unchanged `vx`/`vy`.
- `{ "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 }` — the catalogue's own example
  — loads as `ArcTrajectoryDefinition` and `verticalVelocityAt(2f)` returns `-56.0`, matching the
  closed form `vy + ay·t = -110 + 27·2`.
- `{ "id": "bogus", "type": "spiral", ... }` throws `IllegalArgumentException: trajectory 'bogus' has
  an unknown type 'spiral'` — names the id and the bad type, per the task's own acceptance line.
- An `arc` entry missing `ay` throws (`getFloat` on a missing key), and a `constant` entry carrying a
  stray `ay` throws `"trajectory 'typo' has an unrecognised key 'ay'"` from the new `requireOnlyKeys`
  call.

Full transcript and the exact classpath-discovery steps are in this agent's memory, not repeated here.

**Not touched:** `core/`, `assets/data/` — no content entries added, per this task's scope. `game/`'s
other loaders (`loadFormations`, `loadEnemies`, etc.) are untouched; only `loadTrajectories` and its
new `parseTrajectory` helper changed.

**What was and was not checked about the web target:** `./gradlew build` was not run (issue #123 means
`compileTeavmJava` reports `NO-SOURCE` locally regardless of this change) — not checked. `JsonReader`/
`JsonValue` are the only JSON API touched, no reflection-based `Json` class, no new dependency added —
the two web-target rules this task calls out by name are both satisfied by inspection of the diff.

## Acceptance criteria — this half

- A `type` the loader does not know fails loudly, naming the trajectory id and the bad type: done,
  verified above.
- The four existing `constant` entries load exactly as before: done, verified above with the literal
  entries from `assets/data/trajectories.json`.
- An `arc` entry loads as `ArcTrajectoryDefinition`: done, verified above with the catalogue's own
  `strike-run` numbers.
- No `core/` or `assets/data/` file touched: confirmed, `git status --porcelain` shows only
  `JsonContentSource.java` changed for this half.

## `pre-pr-check` — `game-presentation`'s run

Not yet run for the pull request — the branch is not ready until `level-designer` adds the content in
the same branch, per the task dispatch. `pre-pr-check --base phase/11c-movement-shapes` was run once
during this task to confirm nothing outside `docs/` and `game/` was touched; see the coordinator's
final pull request for the run that accompanies it.

---

## `level-designer`'s half — the entries themselves

Three entries added to `assets/data/trajectories.json`, exactly the three the shape catalogue
(`docs/plan/11c-movement-shapes/shape-catalogue.md`, "The entries") decided, with its numbers
unchanged:

```json
{ "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 },
{ "id": "veer-left", "type": "arc", "vx": -32, "vy": -95, "ay": 20 },
{ "id": "veer-right", "type": "arc", "vx": 32, "vy": -95, "ay": 20 }
```

**The four existing entries are unchanged.** `git diff assets/data/trajectories.json` touches the
`crawl` line only to add the comma the three new entries require after it; `slow-descent`, `swoop`,
`dive` and `crawl` keep their exact text, carry no `"type"` key, and still load as
`SimpleTrajectoryDefinition` with the same `vx`/`vy`. They are bound to six archetypes in
`enemies.json` and the game ships on them today, so nothing about them was allowed to move.

**Nothing points at the three new entries yet, and that is correct here.** No wave, no archetype and
no level was edited: `waves.json`, `level-01.json` and `enemies.json` are untouched, and
`git status --porcelain` shows `trajectories.json` as the only file changed for this half. A spawn
cannot choose a shape until [#164](https://github.com/LuchoC-Dev/little-spaceship/issues/164) puts an
optional shape id on `SpawnEvent`, and pointing an *archetype* at one instead would silently redesign
level 1, which is [11e](../../11e-level-one-redesigned/plan.md)'s decision and out of this phase's
scope. So these three are loadable, resolvable content that no entity flies today. They are not dead
content; they are the content #164's mechanism is built to select.

### How it was checked

`game/` still has no test source set, so this was verified by running the real parser over the real
file, the way `game-presentation` verified its half:

1. `./gradlew :game:compileJava` — clean.
2. A throwaway program invoking the private `JsonContentSource.parseTrajectory(JsonValue)` by
   reflection over the literal `assets/data/trajectories.json`. All seven entries parse; the four old
   ones as `SimpleTrajectoryDefinition`, the three new ones as `ArcTrajectoryDefinition`.
   `verticalVelocityAt` returns `-110 → -56 → ~0` for `strike-run` at `t = 0, 2, 4.074`, which is the
   closed form and the turn time the catalogue states.
3. **The whole content set, through the real constructor.** `new JsonContentSource(new
   FileHandle(new File("assets/data")), "level-01")` loads `balance`, `trajectories`, `formations`,
   `enemies`, `attachments`, `waves` and `level-01.json` without throwing, and `trajectory(id)`
   resolves all seven ids. This is the check that matters: the new entries do not break the load of
   any file that was already loading. (A plain `FileHandle(File)` needs no `Gdx.files`, so no
   application context is required.)

The game itself was not launched — `./gradlew :desktop:run` was not run. Nothing flies these shapes
yet, so there is nothing on screen to look at; **not checked**, deliberately.

### Rule 3 — every shape leaves the playfield — re-checked against the code, not the catalogue

`LifetimeSystem` only removes an enemy once it is off screen, so a shape that comes to rest inside the
playfield deadlocks a `cleared` wave. The catalogue stated an exit time per entry; those numbers were
recomputed here against `SpawnSystem` and `enemies.json` rather than trusted:

- `anchorX = event.atX() * MotionSystem.PLAYFIELD_WIDTH` (`SpawnSystem.java:267`), width 208, so the
  catalogue's `atX 0.9 → x = 187` is right (187.2).
- Collider radii read from `assets/data/enemies.json`: `enemy-rush` 4.0, `enemy-light` 4.5 — the
  values the catalogue's spawn heights `274` and `274.5` assume.
- `strike-run`: turns at `-vy/ay = 110/27 = 4.074 s`, apex `vy²/(2ay) = 224.07` below spawn, so
  `y ≈ 50` on `enemy-rush` — above the player's band, not resting in it. Back at spawn height at
  `8.15 s`, through the safety box's `y = 398` about `1.0 s` later. It always leaves.
- `veer-left` / `veer-right`: turn at `95/20 = 4.75 s`, apex `225.6` below spawn (`y ≈ 49`) and `152`
  units sideways. From `atX 0.9`, `veer-left` crosses `x = 0` at `5.85 s` and `x = -128` at `9.85 s`.
  It leaves sideways before it would leave upward, which is fine — leaving is leaving.

Every number above matches the catalogue to the digit it rounded to. **Nothing disagreed**, so no
third number was invented.

One thing the arithmetic makes into a constraint rather than a suggestion, restated here because it is
the kind of thing a later level edit will forget: **the veers must be spawned on the side they veer
away from** — `veer-left` at `atX >= 0.75`, `veer-right` at `atX <= 0.25`. Spawned on the wrong side
the enemy crosses the edge before reaching its apex and the whole shape happens off screen. That is
11e's problem to honour when it places them; it is written in the catalogue and now here.

### Acceptance criteria — this half

- The entries the catalogue decided, and no others: done — three added, and no fourth kind, no `sine`,
  no `ax`, nothing from the refusals table.
- The four existing entries byte-for-byte unchanged apart from the required comma: done, shown by the
  one-hunk diff.
- The file still loads, and so does everything loaded beside it: done, verified through the real
  constructor over the real `assets/data` directory.
- No wave, archetype or level edited: done, `trajectories.json` is the only content file in the diff.

### `pre-pr-check`

Run against `phase/11c-movement-shapes`; output pasted into the coordinator's pull request, which is
the run that covers all three halves of this branch.
