# Architecture

Decided on 18/08/2026, on top of the platform validated in `11-technical-prototype-results.md` and the rules of `02` and `03`.

This document defines the structure of the real project, not of the spike. The rule that governs everything: **no abstraction is built that does not have a concrete case in the MVP**.

## Structural decisions

| Decision | Choice |
|---|---|
| Entity model | In-house ECS, hand-written, without a library |
| Balanceable content | External JSON, read without reflection |
| Tests | Pure systems plus deterministic replays |
| Concurrency | None. Deterministic single-thread loop |
| Dependency injection | Manual by constructor, without a framework |

## Project configuration

| Element | Value |
|---|---|
| Repository | `little-spaceship`, private at first |
| Root package | `dev.luchoc.littlespaceship` |
| Java version | 17 |
| Build | Gradle with wrapper |
| Tests | JUnit 5 |

On Java 17: chosen for being verified end to end in the spike, including execution in a real browser. Java 21 also compiles across the whole pipeline and its features run on TeaVM, so moving up later is a two-line change. The detail is in `11-technical-prototype-results.md`.

## Modules

```
little-spaceship/
  core/        Pure Java. Simulation, rules and ECS. No libGDX.
  game/        libGDX. Presentation, assets, input and screens.
  desktop/     LWJGL3 launcher.
  web/         TeaVM launcher.
  assets/      Content: JSON, sprites, audio.
```

Dependencies, in one direction only:

```
desktop ─┐
         ├─→ game ──→ core
web ─────┘
```

### Why `core` is pure Java

`core` **does not depend on libGDX**. Not even on its math utilities.

It is not purism: it is what makes the simulation testable in milliseconds, the replays reliable and determinism independent of the framework. The spike already showed that pure Java behaves the same on the JVM and in the browser — `collisionbench` runs on both without a single change.

The cost is reimplementing a `Vec2` and a few math functions. That is tens of lines, and in exchange the module holding all the game rules cannot be broken by a framework change.

The rule is mechanical and verifiable: **if `core` needs to import `com.badlogic.gdx`, the design is wrong**.

### What lives in `game`

Everything that touches the framework:

- asset loading and translation of JSON into content definitions;
- rendering of the world and of the HUD;
- audio, reacting to the events the core emits;
- reading input and building each tick's `InputFrame`;
- menu, options, ship selection, victory and defeat screens, with `scene2d.ui`.

## Hexagonal architecture

The project follows **ports and adapters**: the domain at the centre, knowing nobody, and everything external —framework, rendering, audio, input, files— connected from outside through ports that the domain itself declares.

The dependency rule is a single one and admits no exceptions: **everything points inwards**. The domain does not import infrastructure; infrastructure imports the domain.

```
                 ┌──────────────────────────────┐
                 │          adapters            │   game, desktop, web
                 │  render · audio · input      │
                 │  content · persistence       │
                 └──────────────┬───────────────┘
                                │  implement
                 ┌──────────────▼───────────────┐
                 │            ports             │   core.port
                 └──────────────┬───────────────┘
                                │  declared by
                 ┌──────────────▼───────────────┐
                 │         application          │   core.application
                 ├──────────────────────────────┤
                 │            domain            │   core.domain
                 │  rules, entities, systems    │
                 └──────────────────────────────┘
```

### What is taken and what is not

Hexagonal is applied **in full**: it is exactly the problem we have, a core of rules that must not be coupled to libGDX, to TeaVM or to the content format.

From Clean Architecture we take the dependency rule and the separation between domain and infrastructure, but **use cases are not forced where there are none**. A game loop is not a transactional operation: `MotionSystem` is not a use case, it is a rule that runs sixty times per second. Modelling it as one would add ceremony while buying nothing, and it contradicts the rule of not building abstractions without a real case.

Where there are genuine use cases is **outside the loop**, in the actions the player triggers once: starting a game, selecting a ship, applying options and, later on, saving and continuing. Those live in `core.application`.

### Package structure

```
core/
  domain/        rules, entities, components, systems, events
                 without a single external dependency
  application/   loop orchestration and use cases outside it
  port/          interfaces the domain needs from the outside

game/
  adapter/content/     JSON  → ContentSource
  adapter/render/      WorldView → SpriteBatch
  adapter/audio/       GameEvent → Sound
  adapter/input/       keyboard and mouse → InputFrame
  screen/              scene2d.ui
  ui/                  the Skin and the palette
```

Adapters are interchangeable by definition: replacing libGDX, changing JSON for another format or adding a new target touches `game`, never `core`.

## Contracts at the boundaries

On top of that framing, a strict rule: **no module exposes concrete classes to another**. Every boundary crossing happens through a contract, and the contract is defined by **the consumer**, not by the implementer.

This holds inside `core` too: the domain is modelled with named concepts —ship, enemy, projectile, attachment— and not with loose identifiers and anonymous components manipulated from anywhere.

### What it implies

**`core` declares what it needs; `game` implements it.** The core knows not a single class of `game`. The ports are its own:

```java
public interface ContentSource {
    BalanceValues balance();
    EnemyDefinition enemy(String id);
    TrajectoryDefinition trajectory(String id);
    FormationDefinition formation(String id);
    WaveTimeline timeline(String levelId);
    AttachmentDefinition attachment(String id);
    boolean hasBoss(String levelId);
    BossDefinition boss(String levelId);
}

public interface GameEventSink {
    void emit(GameEvent event);
}
```

`EnemyDefinition`, `WaveTimeline` and `BalanceValues` are domain contracts. `game` builds them by reading JSON, but the core never sees the JSON or the class that parses it.

**`game` does not manipulate the ECS.** To render, it does not access components: it reads through a read-only contract.

```java
public interface WorldView {
    void forEachSprite(SpriteVisitor visitor);
    PlayerStatus player();
    BossStatus bossStatus();
    LevelOutcome outcome();
    CompletionBonus completionBonus();
}

public interface SpriteVisitor {
    void accept(SpriteId sprite, float x, float y, int frame, float rotation);
}
```

The visitor is deliberate: iterating with it does not allocate one object per entity per frame, which at 60 fps and hundreds of entities would be constant garbage for the collector. The contract protects the boundary **and** performance.

**What crosses is immutable or read-only.** `InputFrame` comes in immutable. `GameEvent` goes out immutable. Nobody receives a reference with which they could modify another module's state.

### What it costs and what it buys

It costs more interfaces and the discipline of not leaking implementation types, which is the usual way this kind of rule degrades: a single `getter` returning the concrete class "for convenience" is enough to lose the whole boundary.

In exchange: the domain stays explicit instead of dissolved into the framework, test doubles are written effortlessly because everything is an interface, and changing libGDX or the content format touches not one game rule.

### How it is verified

The boundary is not held up by good intentions. It is checked mechanically:

- `core` does not declare the libGDX dependency, so it cannot import it even if it wanted to;
- `core` does not declare a dependency on `game`, so the arrow can never be inverted;
- an architecture test verifies the dependency rule between layers, and that no type of `core`
  *reachable from `game`* exposes implementation classes. `PublicContractTest` inspects `core.port`
  and `core.application`, not `core.domain`, where `World` publicly hands `ComponentStore`,
  `EntityRegistry` and `Rng` to the systems that must mutate them. That is the design rather than a
  hole — `Simulation.world()` is package-private and `view()` returns a `WorldView`, so `game` can
  never reach a running `World` — but the criterion has been worded more broadly than the test
  before, which is [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4).

## The loop

Fixed step, accumulator, no interpolation:

```
accumulator += min(realDelta, 0.25)     // the cap avoids the spiral of death
while accumulator >= STEP:
    world.update(STEP, tickInput)
    accumulator -= STEP
render(world)
```

`STEP` is 1/60. The simulation **never** receives a variable delta, because a variable delta destroys determinism and with it the replays.

No interpolation when rendering: in pixel-art with positions snapped to whole pixels, interpolating adds little and complicates things. If it is ever noticeable, it is added in the presentation layer without touching the core.

### Three determinism rules

The core cannot:

1. **read the clock** — it receives the fixed step;
2. **read input directly** — it receives an immutable `InputFrame` per tick;
3. **use `Math.random()`** — it uses its own `Rng` with an explicit seed.

Breaking any of the three invalidates the replays silently, so it is best to treat them as invariants, not as preferences.

## The ECS

Hand-written. Three pieces and nothing more.

### Entity

An `int`. An identifier and its generation, to detect references to entities already destroyed.

### Components

Pure data, with no logic and no behaviour methods. The MVP ones:

| Component | Content |
|---|---|
| `Transform` | position |
| `Motion` | velocity and, optionally, trajectory |
| `Collider` | radius, collision layer, and `fragile` — whether ramming destroys it |
| `Health` | health points (enemies and boss) |
| `Player` | lives, bombs, shot level |
| `Weapon` | rate of fire, pattern, timer, for the player |
| `EnemyWeapon` | the same for an enemy archetype, including its first-shot delay |
| `BombState` | charges held, and whether one was requested this tick |
| `Sprite` | reference to the resource and current animation |
| `ScoreValue` | points on being destroyed |
| `Drop` | what it drops on death, if it drops anything |
| `Spawner` | what it spawns and how often, for the carrier |
| `Shield` | active shield |
| `Invulnerable` | remaining grace time |
| `Attachment` | equipped attachment and its durability |
| `Pickup` | type of collectable power-up |

### Systems

Functions over the world, executed **in a fixed order**. The order is part of the game rules, not a detail: changing it changes the behaviour.

**The order lives in `core.domain.system.SystemOrder`, and that enum is the authority.** It is
reproduced here because a reader learning the architecture needs to see it, and the enum carries a
per-stage javadoc saying what breaks if a stage moves. If this list and the enum ever disagree, the
enum is right and this document is stale.

```
1  INPUT          translates the InputFrame into player intent
2  MOTION         applies velocities and trajectories
3  WEAPON         resolves the player's rate of fire and creates projectiles
4  BOMB           detonates the bomb, before COLLISION on purpose
5  SPAWN          advances the level timeline
6  SPAWNER        ticks each carrier's periodic child spawn
7  ENEMY_WEAPON   resolves every enemy's cooldown and creates its projectile
8  BOSS           entrance, the pattern state machine and its fire
9  LIFETIME       expires projectiles and effects
10 COLLISION      detects hits and emits collision events
11 DAMAGE         applies the defensive priority, and damage dealt to enemies
12 PICKUP         resolves power-ups and attachments
13 SCORE          accumulates score
14 CLEANUP        destroys what is marked and frees identifiers
```

`INPUT` is a declared stage with no system in it: the player's intent is read straight from the
`InputFrame` by the systems that need it. A stage with no system is skipped, which is how the enum
was written so that a phase can fill one in without renumbering anything.

`BOMB` sitting before `COLLISION` is the one placement that is load-bearing rather than tidy.
`BombSystem` only *marks* entities for destruction and leaves their colliders in place, so it is
`CollisionSystem`'s own rule — skip anything already marked this tick — that turns the marking into
actual protection. Move `BOMB` after `COLLISION` and a bomb stops saving the player from what it
just cleared.

`DamageSystem` is the only place where the confirmed defensive priority lives —invulnerability → shield → attachment → life— and where invulnerability is granted after any damage. Concentrating it in a single system is what makes it testable and what prevents it from scattering into conditionals across the code.

### Collision

By layer pairs, not everything against everything:

```
player projectile  ×  enemy
enemy projectile   ×  player
enemy              ×  player
pickup             ×  player
```

Naive comparison at first. The `collisionbench` benchmark measured that the MVP scenario costs 0.028 ms, so optimising now would be work without a cause. The uniform grid is already written and measured in the spike; if some advanced level needs it, it is introduced behind the same interface without touching the systems.

## Events

They exist, but with a strict boundary:

- **Inside the simulation**, systems call each other directly. No events: a flow of rules that jumps through a bus is impossible to follow and to test.
- **Towards presentation**, the core emits events and the `game` layer consumes them. Audio, HUD, particles and camera shakes hook in there.

```
core emits:  EnemyDestroyed
```

**One event, deliberately.** Phase 01 decided not to invent an event's fields before a system emits
it (`docs/plan/01-foundations/status.md`), and nothing since has needed a second one: audio reads
`EnemyDestroyed` through `GameEventSink`, and the HUD gets everything else by diffing the
`PlayerStatus` snapshot it already receives every frame. `PlayerHit`, `PowerUpTaken`, `BombFired`,
`AttachmentLost`, `BossPhaseStarted` and `LevelCleared` were named here as the expected set and were
never built. Add one when a consumer exists for it, not before.

That way the core does not know sound exists, and adding a new effect touches no game rule. It is the decoupling the specification asked for, applied where it really pays off.

Events accumulate in a queue per tick and are drained after the update. There are no reentrant callbacks.

## Content in JSON

The files live in `assets/data/`. `game` reads them with `JsonReader`/`JsonValue`, **never** with the automatic serialisation class `Json`: that one uses reflection and on TeaVM it would force declaring every class by hand.

```
assets/data/
  enemies.json      archetypes and their components
  trajectories.json trajectories
  formations.json   formations
  attachments.json  attachments and their durability
  level-01.json     level timeline and the boss
  balance.json      values from 10-mvp-initial-values.md
```

Shot patterns never became a file of their own: a pattern is a string on the weapon component, and a
`patterns.json` holding one entry would be an abstraction with no case behind it.

An enemy is a list of components, not a class:

```json
{
  "id": "enemy-tank",
  "components": {
    "health":     { "points": 40 },
    "motion":     { "trajectory": "crawl" },
    "weapon":     { "pattern": "straight-single", "rate": 4.8, "speed": 60,
                    "firstShotDelay": 1.6 },
    "collider":   { "radius": 10.5, "fragile": false },
    "scoreValue": { "points": 500 }
  }
}
```

The loader does not know what a tank is: it looks up a `name → component factory` registry. When a new component is added it is registered once and **becomes available from JSON** without touching the loader.

`core` parses nothing. It defines the content interfaces and `game` hands them over already built. That is why the tests can assemble definitions by hand without reading a single file.

### The level timeline

A level is a sequence of timestamped events, which is the executable form of the intensity curve:

```json
{
  "events": [
    { "at": 8.0,  "spawn": "enemy-basic", "formation": "line-3", "atX": 0.5 },
    { "at": 12.0, "spawn": "enemy-light", "formation": "diagonal", "atX": 0.2 },
    { "at": 45.0, "spawn": "enemy-tank", "formation": "single", "drop": "shield" }
  ]
}
```

The guaranteed drops from `10-mvp-initial-values.md` are expressed here, marking the concrete instance. It is what allows one enemy to drop something without all of its type doing so.

## Dependency injection

Manual, by constructor, with a single composition root.

No Guice, Dagger or Spring: all three rely on reflection or annotation processors and would add risk with TeaVM in exchange for nothing. In a project of this size, a class that assembles the object graph is clearer than a framework.

There is no `Composition` class. The object graph is assembled in `LittleSpaceshipGame` (the skin,
the atlas, the content source) and in `PlayScreen` (the simulation and the renderers), each building
what it owns. A single root class was the sketch below; two owners turned out to be enough, and a
third class holding both would only pass them straight through.

```java
// the shape of it, in game
var rng = new Rng(seed);
var content = contentLoader.load();
var world = new World(content, rng);
var systems = List.of(
    new InputSystem(), new MotionSystem(), /* ... */);
var loop = new GameLoop(world, systems);
```

Systems receive what they need and do not consult singletons. That is what allows instantiating any of them in a test with fake dependencies.

## Tests

`core/src/test/java`, with JUnit 5. They do not need libGDX, so they run in seconds.

**System unit tests.** Each system with its minimal world. The cases that matter come from the rules already decided: the complete defensive priority, invulnerability after absorbed damage, the lives cap, the weapon upgrade maximum, the power-up picked up at maximum granting points, the attachment that absorbs a hit and disappears.

**Deterministic replays.** A replay is a seed plus the sequence of `InputFrame` per tick. The test reproduces it in full and compares the final state against the expected one.

There is no replay file format and no `core/src/test/resources/`. A replay is a JUnit test that
builds its seed and its input sequence in code — `BombReplayTest`, `BossReplayTest`,
`DamageReplayTest`, `LevelScoreReplayTest`, `SpawnerReplayTest`. An external format was the plan and
was never needed, since no replay has yet had to outlive the test that produces it.

**What most of them assert today is that a run reproduces itself, not that a rule holds**, which is
[#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) and work for the 11 group: a broken
rule breaks identically on both runs, so the test stays green.

They detect what unit tests do not see: two systems that are correct separately interacting badly. And they act as a safety net when refactoring, which is exactly when it is most needed.

If a replay fails after a deliberate balance change, it is regenerated. An obsolete replay is not a failure, it is a piece of data that expired.

## Continuous integration

GitHub Actions: compile, pass the `core` tests, and build the web and desktop targets.

With a limitation the spike made clear: **the web runtime cannot be validated in CI**, because headless Chrome with SwiftShader fails even though the real browser works. CI verifies that the web build compiles and produces artifacts; that it runs is checked by hand.

## Conventions

- **All code in English**: identifiers, comments, log messages, content file names and JSON keys.
- Packages according to the hexagonal layers: `core.domain.*`, `core.application`, `core.port`, `game.adapter.*`, `game.screen`.
- Components have no logic; systems have no state of their own beyond the strictly necessary.
- No static singletons in `core`.

## What is NOT built now

It is in the vision, not in the MVP, and building it ahead of time would be guesswork:

- profiles, saving and serialisation of the run state;
- difficulty system;
- hangar, shop and economy;
- Survival and Endless modes;
- checkpoints;
- spatial grid for collisions;
- object pooling, until profiling justifies it;
- any platform abstraction beyond the launchers.

The design must allow adding them without rewriting the systems. That is different from leaving them prepared.

## Suggested implementation order

1. `core`: ECS, loop, `Rng`, `InputFrame` and the tests covering them.
2. Movement, collision and damage, with the complete defensive priority.
3. `game`: desktop launcher, minimal rendering and input. First playable moment.
4. JSON content loading and enemy archetypes.
5. Level timeline and waves.
6. Power-ups, attachment, bomb and score.
7. HUD and screens.
8. Boss.
9. Audio and audiovisual finish.
10. Web target, CI and deployment.

Desktop first does not contradict the platform decision: it is the shortest path to having something playable, and the core is the same. The web target is activated once there is a game to show.
