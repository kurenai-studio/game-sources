# Phase 04 — Content pipeline

**Lane:** code · **Owner:** `core-domain` (loader in `game`) · **Depends on:** 02 · **Target:** day 4

## Before you start

**Read, in this order:**

1. `docs/planning/12-architecture.md` — the JSON content section, including the schema example.
2. `docs/planning/03-game-systems.md` — enemy and wave design: archetype, trajectory, pattern, formation and drop are independent concepts.
3. `docs/planning/02-mvp-functional-spec.md` — the level 1 enemy roster.
4. `docs/planning/04-campaign-and-levels.md` — the level's provisional sequence.

**Do not re-decide:** JSON is read with `JsonReader`/`JsonValue`, never with the `Json` serialisation class. That one uses reflection and breaks the web build far from where the mistake was made.

**Coordinate with the art lane:** content ids have to match sprite names. That is synchronisation point 2.

## Goal

Turn the game's content into data. Enemies, patterns, trajectories, formations and the level timeline stop being code and become JSON that can be balanced without recompiling.

This is what makes the design principle real: archetype, stats, trajectory, firing pattern, formation and drop are independent and combinable.

## Preconditions

Phase 02 accepted. Sprite ids agreed with the art lane — this is synchronisation point 2.

## Tasks

1. **Content contracts in `core`.** `EnemyDefinition`, `WaveTimeline`, `BalanceValues` and friends, declared by the core as interfaces. The core never parses anything.
2. **JSON loader in `game`.** `JsonReader`/`JsonValue` only — the `Json` serialisation class uses reflection and TeaVM would need every class declared by hand.
3. **Component factory registry.** `name → component factory`, so adding a component means registering it once and it becomes available from JSON without touching the loader.
4. **Enemy archetypes.** The six of level 1: basic, fast light, evolved basic, super-fast, tank and heavy carrier. Each is a list of components, not a class.
5. **Trajectories and firing patterns.** Separate files, referenced by id, reusable across archetypes. A tank on the super-fast's trajectory must be a data change, not a new class.
6. **Formations.** Line, diagonal, single, and whatever the level needs.
7. **`SpawnSystem` and the timeline.** A level is a sequence of timestamped events. This is the intensity curve in executable form.
8. **Designed drops.** A specific instance of a wave can be marked to drop something, without that becoming a property of the archetype.

## Acceptance criteria

- Changing an enemy's stats requires editing JSON only — no recompilation.
- The same trajectory can be attached to two different archetypes from data alone.
- Adding a new component type requires one registration and no loader change.
- Core tests build definitions inline and never read a JSON file.
- Malformed JSON fails with a message naming the file and the offending id, not a `NullPointerException`.
- All content ids are in English.

## Risks

**Reflection creeping in.** The convenient way to parse JSON in libGDX is the `Json` class, and it will work on desktop and break the web build. The failure appears far from the cause.

**Over-generalising the schema.** It is easy to build a system able to express content nobody will ever write. Six archetypes and one level is the actual requirement.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
