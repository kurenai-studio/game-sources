# Codebound — Technical Architecture Proposal

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. No code is written yet.

---

## 1. Guiding principles
1. **Pure logic separated from Unity.** Rules (program, interpreter, world state) are plain C# classes with no
   `MonoBehaviour`. This makes them testable and prevents UI/animation bugs from corrupting game logic.
2. **Data-driven levels.** A level is data (grid, objects, allowed blocks, goals, hints), not custom scripts.
3. **One-way dependencies.** Lower layers never know about higher layers.
4. **Events over references.** Systems announce what happened; interested systems listen.
5. **Do not overengineer.** No dependency-injection framework, no ECS, no addressables, no networking.

Plain-language note on why: a Unity `MonoBehaviour` is tied to scenes and frame updates, which makes it hard to
test and easy to tangle with graphics. Keeping the rules in ordinary C# classes lets us run the whole game's logic
in a test, and lets the visuals simply *replay* what the logic decided.

## 2. Unity setup [RECOMMENDED]
- **Editor version [OPEN D-01]:** options on this machine: **2022.3.62f3 (LTS, very stable, most tutorials and
  assets target it)** or **6000.5.7f1 (Unity 6 line, newer, more recent features and UI Toolkit improvements)**.
  Recommend **2022.3 LTS** for a deadline-driven student project unless your instructor requires Unity 6. If the
  Unity 6 build is a non-LTS "update" release, stability risk is higher; verify on the Hub.
- **Template:** 2D (URP). Pixel-perfect rendering via Pixel Perfect Camera (URP) or integer scaling.
- **Packages:** Input System (or legacy input for simplicity — **OPEN**), TextMeshPro, 2D Tilemap Extras.
- **UI technology:** uGUI (Canvas) for the block editor. UI Toolkit is capable but drag-drop with custom
  prefab-like blocks is better-supported and more documented in uGUI. [RECOMMENDED]
- **Source control:** Git with the standard Unity `.gitignore`; force-text serialization and visible meta files.
- **Assembly definitions** to enforce layering (optional but cheap; compile times stay small).

## 3. Layered module map

```
  PRESENTATION (Unity)           UI: BlockEditor, HUD, Feedback panel  |  World: GridView, HeroView, ObjectViews
         ▲  listens to events / calls commands
  APPLICATION (Unity glue)       GameFlow, LevelManager, ExecutionController, SaveService, AudioService
         ▲
  CORE (pure C#, no UnityEngine) Program model, Interpreter, WorldState, GoalEvaluator, FeedbackBuilder
         ▲
  DATA                           LevelDefinition (ScriptableObject), Feedback templates, Chapter definitions
```

### Modules and responsibilities

| System (from brief) | Module | Responsibility |
|---|---|---|
| Grid-based dungeon | `Core.Grid` (`GridMap`, `Cell`, `Direction`) | Cells, walkability, coordinates, neighbour lookup |
| Tilemap / obstacles | `World.TilemapLoader` + `LevelDefinition` | Read a Unity Tilemap (visual) and build `GridMap` (logic); never use Tilemap for rules |
| Player character | `Core.HeroState` + `World.HeroView` | Logic state (cell, facing, inventory) vs. sprite/animation |
| Instruction/block system | `Core.Program` + `UI.BlockEditor` | Tree of instructions vs. its visual editor |
| Command execution engine | `Core.Interpreter` + `App.ExecutionController` | Produces events deterministically; controller plays them back (Run/Step/Pause/Speed) |
| Puzzle validation | `Core.GoalEvaluator` | Compares final `WorldState` with level goals |
| Level management | `App.LevelManager` | Loads a `LevelDefinition`, builds world, resets, advances |
| Educational feedback | `Core.FeedbackBuilder` + templates | Turns `ExecutionResult` into messages and highlight targets |
| UI management | `UI.UIRoot`, screens | Menu, chapter map, HUD, result panel |
| Progress and save | `App.SaveService` | JSON file in `Application.persistentDataPath` |
| Audio | `App.AudioService` | Plays SFX/music by id; volume settings |

## 4. How systems communicate [RECOMMENDED]
Use three simple mechanisms and no others:

1. **Direct references from higher layer to lower layer** (e.g., `ExecutionController` calls
   `Interpreter.Run`).
2. **C# events / `Action` callbacks upward** (e.g., `ExecutionController.OnStepExecuted`,
   `OnRunFinished`). Presentation subscribes.
3. **ScriptableObject data** shared as read-only configuration.

Avoid global singletons except a very small `ServiceLocator`-like `GameServices` (or a single `GameBootstrap`
that creates `SaveService` and `AudioService` and hands them down). **Why:** singletons everywhere become
invisible dependencies and make tests hard.

### Main sequence: pressing Run
```
RunButton ─► ExecutionController.Run()
  ExecutionController ─► Validator.PreCheck(program, level)      (fail early with friendly message)
  ExecutionController ─► Interpreter.Execute(program, worldCopy) ─► List<ExecutionEvent> + ExecutionResult
  ExecutionController ─► for each event: raise OnEvent(e)
       BlockEditor highlights e.InstructionId
       HeroView animates e (move / turn / interact)
       AudioService plays sound for e
  ExecutionController ─► GoalEvaluator.Evaluate(finalState)
  ExecutionController ─► FeedbackBuilder.Build(result) ─► FeedbackPanel.Show(message)
  Success ─► ProgressService.RecordCompletion(level, stars) ─► LevelManager.UnlockNext()
```

## 5. Key data structures (names only)
- `LevelDefinition` (ScriptableObject): id, chapter, grid size, tile layout reference or char-map, objects with
  link ids, start cell + facing, `AllowedBlocks`, `BlockBudget`, `Goals`, `StarThresholds`, `Hints[]`,
  `IntroText`, optional `PrefilledProgram`.
- `WorldState`: hero, object states (door open?, switch on?, item collected?), counters.
- `Instruction` hierarchy: `ActionInstruction`, `RepeatInstruction`, `IfInstruction`, …
- `ExecutionEvent`: type, instruction id, from/to cell, extra data.
- `ExecutionResult`: outcome, failure reason, location, context.

## 6. Scenes and project layout [RECOMMENDED]
Scenes: `Boot`, `MainMenu`, `ChapterMap`, `Gameplay` (single scene reused for all levels; the level is loaded
as data). Fewer scenes = fewer bugs and faster iteration.

```
Assets/_Project/
  Scripts/
    Core/        (Program, Interpreter, Grid, Goals, Feedback)   <- no UnityEngine
    App/         (LevelManager, ExecutionController, SaveService, AudioService)
    World/       (GridView, HeroView, ObjectViews, TilemapLoader)
    UI/          (BlockEditor, Toolbox, HUD, FeedbackPanel, Menus)
    Data/        (ScriptableObject definitions)
  Art/  Audio/  Prefabs/  Scenes/  Levels/  Settings/  Tests/
```
Tests: Edit-mode tests for `Core` (Unity Test Framework). Highest value, low cost.

## 7. Save system
JSON via `JsonUtility` to `persistentDataPath/save.json`: completed levels, stars, last chapter, settings,
hint usage. Write on level completion and settings change; version field for future migration. Single save slot
(**OPEN D-09** whether multiple profiles are needed for a classroom).

## 8. Audio
`AudioService` with two `AudioSource`s (music, sfx), a small pool for overlapping SFX, volume stored in settings,
sounds referenced by an enum or id in a `SoundLibrary` ScriptableObject.

## 9. UI architecture
- One Canvas (Screen Space - Overlay), Canvas Scaler 1920×1080, match width/height.
- Block editor MVC-lite: `ProgramView` renders from `Program`; user drops call `ProgramEditor` commands
  (`Insert`, `Move`, `Remove`); the model raises `OnChanged`; the view re-renders. **View never mutates the model
  directly.** Gives free undo/redo (command history).
- Drag handling with Unity EventSystem (`IBeginDragHandler`, `IDragHandler`, `IEndDragHandler`) and drop-target
  slot components.

## 10. Key technical risks (ranked)
1. **Block editor drag-drop and nested layout** — highest effort; mitigated by slot model, early prototype,
   Vertical/HorizontalLayoutGroup with careful rebuild, and keeping blocks uniform in size.
2. **Execution/animation sync and Step/Pause** — mitigated by precomputing events, playback separate from logic.
3. **Level content volume and solvability** — mitigated by editor-time validator and level data format that is
   fast to author.
4. **Scope creep** (functions, variables, extra mechanics) — mitigated by MVP gates.
5. **Pixel-perfect rendering / UI scaling at different resolutions** — mitigate with a fixed reference resolution
   and early multi-resolution testing.
6. **Unity version choice** locking packages/APIs — decide before creating the project.
7. **Asset style inconsistency** — mitigate with a strict tile size and palette.

## 11. Things deliberately not included
Dependency injection frameworks, ECS/DOTS, Addressables, node-graph tools, networking, cloud saves, procedural
generation, a dialogue system, a custom editor suite beyond a level validator. Add only when a concrete need
appears.
