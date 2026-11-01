# Phase 04 — Content pipeline · status

**State:** done, both halves — `core` (reviewed, round 1 fixed) and the `game` loader
**Updated:** 20/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

The `core` half of the phase: contracts, registry, `SpawnSystem`, the timeline, and the player-in-world fix. The JSON loader in `game` is not part of this pass — see "Notes for whoever comes next".

- **Content contracts in `core.port`.** `ComponentSpec` (a generic name + typed key/value bag) is
  what makes "an enemy is a list of components, not a class" real: `EnemyDefinition.components()`
  returns a `List<ComponentSpec>`, and nothing in `core` needs to know what a `"collider"` or a
  `"motion"` component is. Every accessor is required (no default variant survived review — see
  "Review round 1"), failing with a message that distinguishes a missing key from one present with
  the wrong type, both naming the component and the field. Also added: `TrajectoryDefinition`,
  `FormationDefinition` + `FormationSlot`, `SpawnEvent`, `WaveTimeline`. Each has a straightforward
  record implementation (`Simple*`) that both core tests and, once it exists, the `game` loader can
  use directly instead of writing their own. `MapComponentSpec` is the same idea for `ComponentSpec`
  — backed by a plain `Map<String, Object>`, which is what a `JsonValue` object maps onto without
  reflection.
- **`ContentSource` grew `enemy()`, `trajectory()`, `formation()` and `timeline()`.** All four are
  meant to fail by naming the id they could not resolve, never by returning null.
- **`BalanceValues` grew `playerStartX()`/`.playerStartY()`.** Placeholders, same open status as
  `playerSpeed()`/`.playerSlowFactor()` from phase 02 — see `08-decisions-and-open-items.md` and
  `10-mvp-initial-values.md`.
- **Component factory registry**, `core.domain.content.ComponentFactoryRegistry` +
  `ComponentFactory`. `name -> factory`, looked up by exact key, never iterated — registration order
  has no observable effect on a replay. `withDefaults()` registers `motion`, `collider`, `sprite`,
  `scoreValue`; a fifth component type is one more `.register(...)` call, no change to `SpawnSystem`
  or to the loader.
- **Two new components**: `ScoreValue` (points, attached from the archetype's `"scoreValue"` spec)
  and `Drop` (a pickup content id, attached directly by `SpawnSystem` from the *event*, never from
  the archetype — per `03-game-systems.md`, a designed drop marks one wave instance, not every enemy
  of that archetype). `World` grew their stores and frees them in `destroyEntity`.
- **`SpawnSystem`**, `SystemOrder.SPAWN` (ordinal 3, before `COLLISION` at 5). Walks a level's
  `WaveTimeline` with a single advancing cursor — the timeline is validated sorted by
  `SimpleWaveTimeline`'s constructor, which is what makes that cursor correct instead of skipping or
  reordering waves. For each due `SpawnEvent`, resolves the `EnemyDefinition` and `FormationDefinition`
  and creates one entity per formation slot, positioned at `atX * PLAYFIELD_WIDTH + slot.offsetX` on
  the x axis; the y axis is `PLAYFIELD_HEIGHT + radius + (slot.offsetY() − lowestOffsetY)`, measured
  against the whole formation's lowest `offsetY`, not each slot's own — see "Review round 1" (B1) for
  why the simpler per-slot version was wrong. `PLAYFIELD_HEIGHT = 270f` is a new constant here, the
  vertical counterpart to `MotionSystem.PLAYFIELD_WIDTH`, sourced from `docs/design/04-hud-layout.md`'s
  208x270 playfield figure.
- **The extra task: the player now exists from tick zero.** `Simulation`'s shared constructor calls a
  private `spawnPlayer` after building `World`, using `BalanceValues.playerStartX/Y()` for position
  and two new private constants (`ship-basic`, radius 3.0, both from
  `docs/design/02-sprite-sizes.md` — art facts, not balance values, same reasoning as
  `MotionSystem.PLAYFIELD_WIDTH`). The public 3-argument constructor still works unchanged and still
  registers no `SpawnSystem` (no level id to build a timeline from); a new 4-argument overload takes
  a level id and wires `SpawnSystem` into the pipeline too.
- **Tests**, all inline, none reading a file: `MapComponentSpecTest`, `ContentDefinitionsTest`
  (validation of every `Simple*` type — empty ids, no components, no slots, negative timestamps,
  an anchor outside `[0,1]`, an out-of-order timeline naming the offending index),
  `ComponentFactoryRegistryTest` (all four default factories, an unknown component name failing by
  name, registering a new one), `SpawnSystemTest` (due/not-due waves, the cursor never re-firing,
  one tick firing several waves, a multi-slot formation, a designed drop attaching only to that
  wave's entities, the same trajectory id reused across two archetypes, an unknown enemy id and a
  malformed component both failing with the archetype id named), and
  `LevelContentIntegrationTest`, which builds all six level 1 archetypes with the exact sprite ids
  and collider radii from `02-sprite-sizes.md` and the exact score values from
  `10-mvp-initial-values.md`, runs them through a real `Simulation` for ten seconds, and checks every
  archetype's sprite id appears in the world alongside the player's.
- **167 tests total, all passing** after review round 1's fixes (below).

Acceptance criteria against `plan.md`:

| Criterion | Status | Where |
|---|---|---|
| Changing an enemy's stats requires editing JSON only | met on the `core` side | `ComponentSpec`/`EnemyDefinition` carry no code-side stat; `game`'s loader is what makes this true end to end — not built here |
| The same trajectory attaches to two different archetypes from data alone | met | `SpawnSystemTest.sameTrajectoryReusedAcrossArchetypes`, `LevelContentIntegrationTest.tankOnRushTrajectoryIsADataChange` |
| Adding a component type is one registration, no loader change | met | `ComponentFactoryRegistryTest.registeringANewFactoryWorks` |
| Core tests build definitions inline, never read a file | met | every test in this phase |
| Malformed content fails naming the file and the offending id | met for the id half | every `core` failure names an id (enemy, component field, trajectory, timeline index) — see "Notes for whoever comes next" for what the loader still owes |
| All content ids are in English | earned by the loader, not here | every id in this branch lives in a test fixture; no content file exists yet to actually be in English or not — same treatment phase 02 gave an equivalent claim, corrected in review |

Task 5 of the plan ("trajectories and firing patterns") is **half-built**: trajectories are done,
firing patterns are deliberately deferred to phase 05, along with `Weapon` — see "Decisions taken
while implementing" for why. Not an oversight, but also not something the table above should be
allowed to paper over by omission.

## Done — the JSON loader in `game`

`game-presentation`'s half, added once the `core` side above merged into `main` and closing GitHub
issue #18. Built on branch `feat/first-playable` — the same branch phase 03 is on, since phase 03's
two blocked acceptance criteria could only be earned once this existed, per the coordinator's
instructions.

- **`assets/data/*.json`** — `balance.json`, `trajectories.json`, `formations.json`, `enemies.json`,
  `level-01.json`. Content, not code: the six level 1 archetypes, their four trajectories, three
  formations and one timeline, copied from the exact ids, radii, trajectory vectors and score values
  `core-domain` already proved work end to end in `LevelContentIntegrationTest` — not re-invented,
  since that test is the closest thing this project has to a reviewed content spec. `enemies.json`
  gives every `"collider"` an explicit `"fragile"`, per review round 1 (B2): `true` for basic, light,
  shooter and rush, `false` for tank and carrier.

  **`level-01.json` is not level 1.** It is six events in 9.5 seconds, one enemy of each archetype in
  a row, and it exists to prove the pipeline loads and spawns end to end. The designed level is the
  fourteen-beat sequence in `docs/planning/04-campaign-and-levels.md`: initial calm, isolated basics,
  light and fast, combined formations, tanks and shifts in priority, super-fast, carriers, shooters,
  high-pressure combinations, the difficult encounter that hands over the attachment, a brief rest,
  the final escalation, the boss. None of that is here, and it cannot be written yet: the level's
  target duration and the intensity-curve tooling are open items in `docs/STATUS.md`. Tracked in
  issue #20 - do not read this file as the level being done.
- **`game/adapter/content/JsonContentSource.java`** — the `ContentSource` implementation. Parses all
  five files eagerly in the constructor with `JsonReader`/`JsonValue` only (never the reflection-based
  `Json` class), so a malformed file fails at startup instead of on whichever tick first asks for the
  broken id. Every failure `core`'s own contracts throw (naming a component, a field, or an id) is
  caught here and rethrown with the file's path prefixed — the other half of "malformed content fails
  with a message naming the file and the offending id," which `core` cannot supply on its own since it
  never knows a file exists.
- **`game/adapter/content/JsonComponentSpecs.java`** — turns one enemy entry's `"components"` JSON
  object into `List<ComponentSpec>`, one `MapComponentSpec` per component key, boxing each field as
  `Float`/`String`/`Boolean` to match what `MapComponentSpec` requires. An unsupported JSON type (a
  nested object or array) fails naming the component and field rather than guessing a conversion.
- **`game/adapter/content/JsonBalanceValues.java`** — a record `BalanceValues`, every field required
  from `balance.json` with no default, same reasoning `core`'s own `ComponentSpec` settled on: a
  missing balance number silently defaulting is a worse failure than refusing to start.
- **`LittleSpaceshipGame`** now builds `JsonContentSource` from `Gdx.files.internal("data")` and passes
  `JsonContentSource.LEVEL_ID` ("level-01") to `Simulation`'s new 4-argument constructor, which is
  what actually wires `SpawnSystem` into the running pipeline. Without the level id, the 3-argument
  constructor still works (a player-only sandbox) but no enemy ever spawns.
- **A real bug this surfaced: `WorldRenderer` was drawing every entity's `x` unmodified.**
  `core.domain`'s `Transform.x` is measured from the playfield's own left edge, in `[0, 208]` —
  confirmed against `MotionSystem.PLAYFIELD_WIDTH` clamping the player to that exact range and
  `SpawnSystem` computing `atX * PLAYFIELD_WIDTH` — while the logical resolution is 480 wide with the
  playfield centred inside it. This was invisible in phase 03 because the world was always empty; the
  first entity phase 04 put on screen would have rendered 136 logical units too far left, inside the
  HUD margin instead of the playfield. Fixed by adding `playfieldLeft` in `WorldRenderer.accept`; `y`
  needs no equivalent shift since the playfield is the full 270-unit logical height.
- **`PlaceholderAtlas` grew the six enemy archetypes**, generic alien-hull silhouettes at the exact
  sizes `docs/design/02-sprite-sizes.md` fixes (`enemy-basic` 13x13 through `enemy-carrier` 39x31),
  packed into the same one-texture atlas as the ship, so nothing about phase 03's "one texture, no
  per-frame allocation" property changed.
- **Verification without a display.** Two headless checks, run against the actual production classes
  rather than a reimplementation of their logic — full detail and exact output in this phase's other
  status file, `docs/plan/03-first-playable/status.md`, since what they prove is that phase's blocked
  acceptance criteria, not this one's:
  - a small program that builds a real `JsonContentSource` from `assets/data/`, runs a real
    `Simulation` for 11 simulated seconds, and confirms all seven sprite ids (the player plus the six
    archetypes) exist in the world with the positions their trajectories predict;
  - a second program that replaces `Gdx.input`/`Gdx.graphics` with JDK dynamic proxies (no display,
    no LWJGL, no `Application` needed, since none of the methods exercised touch native code) and
    calls the real `InputAdapter.sample()` to confirm keyboard-alone, mouse-alone and opposing
    keyboard+mouse all produce the movement the summing rule predicts, including exact cancellation.

## Acceptance criteria against `plan.md` — updated now that the loader exists

| Criterion | Status | Where |
|---|---|---|
| Changing an enemy's stats requires editing JSON only | **met** | `enemies.json` holds every stat; no archetype is hardcoded in `game` or `core` |
| The same trajectory attaches to two different archetypes from data alone | met (already true on the `core` side) | `SpawnSystemTest.sameTrajectoryReusedAcrossArchetypes`, `LevelContentIntegrationTest.tankOnRushTrajectoryIsADataChange`; `trajectories.json` itself reuses `crawl` for both `enemy-tank` and `enemy-carrier` |
| Adding a component type is one registration, no loader change | met (`core`-side property, unaffected) | `ComponentFactoryRegistryTest.registeringANewFactoryWorks` |
| Core tests build definitions inline, never read a file | met (`core`-side property, unaffected) | every test in `core` |
| Malformed content fails naming the file and the offending id | **met by construction, untested** | `JsonContentSource.inFile` prefixes the file path and `core`'s own exceptions name the component, field or id, so both halves of the message exist. Nothing exercises them: `game` has no test suite at all, and an error path is exactly what running the game once does not reach. Tracked in issue #19 |
| All content ids are in English | **met** | every id in `assets/data/*.json` — `ship-basic`, `enemy-basic` through `enemy-carrier`, `slow-descent`/`swoop`/`dive`/`crawl`, `single`/`line-3`/`diagonal`, `level-01` |
| Trajectories (task 5, half) | still deferred | firing patterns and `Weapon` stay phase 05's, per `core-domain`'s original reasoning below — the loader does not change that |

## Blocked

Nothing. Both halves of this phase are done.

## Review round 1

`reviewer` accepted the phase on pull request #16, with two real bugs and three honesty findings to
fix before merge. The reviewer verified every citation in the branch — sprite radii and ids, the HUD
270 figure, the score table, the `SystemOrder` ordinals — checks out; that had not been true of
earlier phases. What changed:

| # | Finding | Fix |
|---|---|---|
| B1 | `SpawnSystem`'s javadoc guaranteed every enemy enters "fully off-screen regardless of its size", but the y position only accounted for the entity's own collider radius, not the formation's vertical extent. A formation like `diagonal` (offsets 0, −15, −30) put two of its three entities inside the visible playfield the instant they spawned. | `spawnWave` now computes the formation's lowest `offsetY` once and measures the spawn height against *that* slot, so every other slot lands further above it: `y = PLAYFIELD_HEIGHT + radius + (slot.offsetY() − lowestOffsetY)`. Pinned by `SpawnSystemTest.diagonalFormationEntersFullyOffScreen`, which asserts every entity's bottom edge (`y − radius`) clears `PLAYFIELD_HEIGHT` — no test exercised a non-zero `offsetY` before this. |
| B2 | `"fragile"` defaulted to `false` in `ComponentFactoryRegistry`, but four of the six level 1 archetypes are fragile — omitting the key in content would silently produce a weak enemy that survives ramming the player. Worse: `MapComponentSpec`'s optional accessors returned the default on a *wrongly typed* value too, so `"fragile": "true"` as a JSON string also silently read as `false` — exactly the bug the malformed-content acceptance criterion exists to catch. | Removed every optional accessor from `ComponentSpec`; `flag`, `number` and `text` are all required now, failing with a message that distinguishes "missing" from "wrong type", both naming the component and the field. `attachCollider` calls `spec.flag("fragile")` with no default, so omitting it fails loudly instead of guessing. Pinned by `MapComponentSpecTest.wrongTypeFlagFails`, `ComponentFactoryRegistryTest.colliderFragileIsRequired`. |
| H1 | "All content ids are in English" was marked met on the strength of test fixtures, in a branch with no content file — the same defect phase 02 shipped and had to correct in review. | Acceptance table now marks it "earned by the loader, not here", matching how the other loader-dependent criteria are already phrased. |
| H2 | Task 5 ("trajectories and firing patterns") reads as done in the task list with no mention that only half of it was built. | Called out explicitly under the acceptance table: trajectories done, firing patterns deferred to phase 05, with the reason repeated from "Decisions taken while implementing". |
| H3 | Two `ComponentSpec` accessors (`number(key, default)`, `text(key, default)`) had no consumer anywhere in `core` — the same "no consumer, don't guess" test that correctly killed `PatternDefinition`, not applied to this interface. | Removed both; only `flag`, now required, survived review, and it has a real consumer (`attachCollider`). |

167 tests total (up from 164 — two dead-accessor tests removed, five new ones added for the required
`flag` accessor, the wrong-type failure path, and the diagonal-formation regression), all passing.

## Decisions taken while implementing

- **`ComponentSpec` is a generic name + typed bag, not one interface per component.** The
  architecture doc's own JSON example (`"collider": {"radius": 7, "layer": "enemy"}`) is already
  shaped this way; a typed interface per component would have meant a matching Java type for every
  JSON object, which is exactly the machinery a `name -> factory` registry is supposed to replace.
- **Firing patterns are not in this pass.** The plan's task 5 names them alongside trajectories, but
  no `WeaponSystem` or `Weapon` component exists yet (phase 05's job per `docs/plan/05-game-systems`),
  and declaring a `PatternDefinition` now would mean guessing its shape — shot count, spread, cooldown,
  projectile sprite — with no consumer to check it against. `core-deferred-surface.md` already
  flagged exactly this risk for `GameEvent` in phase 02; the same reasoning applies here. Trajectories
  did get built because `MotionSystem` already exists and already consumes a `Motion` component, so
  their shape (a constant velocity) is not a guess.
- **`Drop` is attached by `SpawnSystem` directly, never through `ComponentFactoryRegistry`.** A
  designed drop is a property of the `SpawnEvent`, not of the `EnemyDefinition`'s component list —
  the plan's task 8 says so explicitly. Routing it through the same generic registry as archetype
  components would have blurred that distinction back in.
- **Which archetypes are "fragile" was a judgement call.** Recorded as open in
  `08-decisions-and-open-items.md`: the functional spec names "basic, light and fast" as weak and
  only excludes tank and heavy carrier, leaving the shooter archetype's classification implicit.
  Read broadly here — everything except tank and carrier is weak.
- **`Simulation` gained a second public constructor instead of changing the existing one's arity.**
  The 3-argument constructor still works and still spawns the player, just without `SpawnSystem`
  registered (no level id to build a timeline from). This kept every existing test compiling with a
  one-line fix (`DamageReplayTest`) instead of a rewrite, while still giving `game` a 4-argument
  constructor that wires the whole MVP pipeline including spawning.
- **`SpawnSystem` holds mutable instance state (`levelTime`, `cursor`)**, the first system in this
  codebase to do so — every other system so far is a pure static-method holder. `GameSystem`'s own
  javadoc allows "state of their own beyond the strictly necessary"; tracking a level's elapsed time
  and timeline cursor on `World` instead would have meant inventing a general "level time" concept
  that nothing else needs yet. A fresh `Simulation` always builds a fresh `SpawnSystem`, so this stays
  as reproducible as everything else the composition root creates once per run.

## Notes for whoever comes next

- **What `game`'s JSON loader still has to build**, against the contracts declared here:
  - Read `enemies.json`, `trajectories.json`, `formations.json`, `level-01.json` and `balance.json`
    with `JsonReader`/`JsonValue`, never `Json`.
  - For every JSON object naming a component, build a `MapComponentSpec` (or an equivalent
    `ComponentSpec`) and hand the whole list to `new SimpleEnemyDefinition(id, components)`.
  - Build `SimpleTrajectoryDefinition`, `SimpleFormationDefinition` (+ `FormationSlot`) and
    `SimpleWaveTimeline` (+ `SpawnEvent`) directly from parsed JSON — no core-side conversion needed.
  - Wrap whatever `IllegalArgumentException` those constructors or `ContentSource`'s lookups throw
    with the file name, since `core` only ever knows the id, never the file. That combination is
    what the acceptance criterion "names the file and the offending id" actually needs — `core`
    supplies the id half unconditionally, `game` has to supply the file half.
  - Implement `ContentSource` itself: four maps (or similar) keyed by id, built once at load time,
    handed to `Simulation`'s constructor. `balance()` needs a real `BalanceValues`, including the
    still-placeholder `playerSpeed`, `playerSlowFactor`, `playerStartX`, `playerStartY`.
  - **Every `"collider"` component in `enemies.json` must include `"fragile"` explicitly** — it is a
    required field as of review round 1 (B2), not a default. `enemies.json` needs `true` for basic,
    light, shooter and rush; `false` for tank and carrier.
  - The composition root now needs a level id string (e.g. `"level-01"`) to pass to `Simulation`'s
    4-argument constructor.
- **`SystemOrder.SPAWN` is ordinal 3, `COLLISION` is 5.** A spawned enemy is visible to `CollisionSystem`
  the same tick it appears, since `SPAWN` runs before it. Confirmed by re-checking the ordinals
  directly in `SystemOrder`, per this phase's own warning about a previous status file getting this
  wrong.
- **`ComponentFactoryRegistry` factories always attach the enemy collision layer.** The content
  pipeline only spawns enemies in this phase — no pickups, no structures — so `"collider"`'s factory
  hardcodes `CollisionLayer.ENEMY` rather than reading a `"layer"` field nothing would ever set to
  anything else yet. Whoever spawns pickups or structures through this same registry needs to either
  add that field back or give pickups/structures their own spawning path.
- **The six level 1 archetypes are not hardcoded anywhere in `core`.** They only exist as literal
  values inside `LevelContentIntegrationTest`, built to prove the generic machinery covers them —
  copy those exact ids, radii and score values into `enemies.json`, they are sourced straight from
  `docs/design/02-sprite-sizes.md` and `docs/planning/10-mvp-initial-values.md`.
