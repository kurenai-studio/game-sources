# Codebound — Technical Architecture (v2)

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. No code is written. Supersedes the v1 block-editor
architecture.

---

## 1. Principles
1. **Pure logic separated from Unity.** Room flow, grading and trace playback are plain C# classes (no `MonoBehaviour`).
2. **Data-driven rooms.** Rooms are data; no per-room scripts.
3. **Events upward, references downward.** Presentation listens; logic never knows about visuals.
4. **Do not overengineer.** No DI framework, ECS, Addressables, networking, or cloud.

Plain-language note: a `MonoBehaviour` is tied to scenes and frames, which makes it hard to test. Keeping the rules in
ordinary classes lets us test a whole room without opening Unity, and the visuals simply replay what the data says.

## 2. Unity setup [RECOMMENDED]
- **Editor [OPEN D-01]:** 2022.3.62f3 (LTS, stable, most tutorials) or 6000.5.7f1 (Unity 6 line; check its support
  status). Recommend 2022.3 LTS unless required otherwise.
- Template: 2D (URP). Pixel Perfect Camera.
- Packages: TextMeshPro, 2D Tilemap Extras, Input System (or legacy; **OPEN D-11**), Unity Test Framework.
- UI: uGUI. Syntax-highlighted code via TextMeshPro rich text.
- Git with Unity `.gitignore`; consider Git LFS for art/audio.

## 3. Layers
```
PRESENTATION   Keep scene views, code panel, Tala/Watch panel, dialogue, menus, HUD
      ▲  listens to events
APPLICATION    RoomSession, GameFlow, DialogueService, SaveService, AudioService, ToolController
      ▲
CORE (pure C#) RoomDefinition model, TracePlayer, RoomStateMachine, Grader, ConsequenceResolver
      ▲
DATA           RoomDefinition assets, dialogue tables, chapter definitions
```

## 4. Modules
| Module | Responsibility |
|---|---|
| `Core.Rooms` | `RoomDefinition`, `RoomStateMachine` (Ticket→…→Debrief) |
| `Core.Trace` | `TraceEvent` types, `TracePlayer` (Run/Step/Pause/Breakpoints), `ITraceSource` |
| `Core.Grading` | Prediction, hypothesis, fix-quality, stars |
| `App.RoomSession` | Owns one room playthrough; exposes events (`OnEvent`, `OnStateChanged`, `OnResult`) |
| `App.ToolController` | Which tools are available; applies unlocks |
| `App.DialogueService` | Picks Bato/Tala lines by room, mentor mode, trigger; substitutes player name |
| `App.SaveService` | JSON in `persistentDataPath`: name, progress, stars, hints, settings |
| `App.AudioService` | Music/SFX by id |
| `World.KeepView` | Maps trace events to scene objects; places objects on grid slots |
| `World.ObjectViews` | Chest, guard, item, gate, machine views; `ThreadView` for references |
| `UI.CodePanel` | Lines, highlight, breakpoint markers |
| `UI.TalaPanel` | Watch, log, hints, test runner |
| `UI.Screens` | Menu, name entry, chapter map, result/debrief |

`ITraceSource` has two implementations: `AuthoredTraceSource` (MVP) and, later, `InterpreterTraceSource`. The rest of
the game never knows which one is used. This is the one extension point worth building now. **[RECOMMENDED]**

## 5. Communication
- Higher layers call lower layers directly.
- Lower layers raise C# events or `Action` callbacks.
- ScriptableObjects hold read-only data.
- No global singletons beyond a small bootstrap that creates `SaveService` and `AudioService` and passes them down.

### Sequence: pressing Run
```
RunButton → RoomSession.Run()
  TracePlayer.Play(trace) → raises OnEvent(e) for each event
     CodePanel highlights e.line
     KeepView spawns/moves objects, draws threads
     TalaPanel updates Watch values
     AudioService plays event sounds
  TracePlayer finishes → RoomSession moves to Investigate
```
Pressing Fix → `ConsequenceResolver` picks the chosen option's trace and test result → replay → `Grader` → `SaveService`
if complete.

## 6. Scenes and folders [RECOMMENDED]
Scenes: `Boot`, `MainMenu`, `ChapterMap`, `Room` (single scene reused for every room, loaded with a `RoomDefinition`).
```
Assets/_Project/
  Scripts/ Core/  App/  World/  UI/  Data/
  Art/  Audio/  Prefabs/  Scenes/  Rooms/  Dialogue/  Settings/  Tests/
```
Edit-mode tests cover `Core` (trace playback, state machine, grading, validator). Highest value, lowest cost.

## 7. Authoring and validation
Rooms are authored in ScriptableObjects (or JSON imported to them). A **Room Validator** editor tool checks every room
before build (see `GAMEPLAY_SYSTEMS.md` §9). A simple preview window plays a room's trace in the editor so authors can
check without launching the game. **[RECOMMENDED]**

## 8. Save
Single JSON file with version field: player name, completed rooms, stars, hint usage, settings, last chapter. Written on
room completion and settings change. **[OPEN D-09]** whether multiple profiles are needed for shared lab PCs.

## 9. Interpreter (optional future) [OPEN D-07]
A mini C# interpreter (lexer, parser, evaluator, runtime with stack/heap/null) would produce the same trace events from
student-edited code. Estimated 2–3 weeks for a subset covering Chapters 1–3 (variables, control flow, methods, classes,
`List<T>`, references, null); bigger for later chapters. Recommended only as a time-boxed spike after the vertical slice.

## 10. Technical risks (ranked)
1. **Content volume and correctness.** Mitigate with a data format that is fast to author, the validator, and expert
   review.
2. **Trace/visual sync (Step, breakpoints, replays).** Mitigate: TracePlayer is separate from visuals and tested.
3. **Keep visualisation clarity.** Many objects and threads can clutter. Mitigate: strict layout slots, max objects per
   room, early readability tests.
4. **Code panel quality** (formatting, highlighting, scaling). Mitigate: TextMeshPro rich text, fixed line height,
   monospaced font, test at several resolutions.
5. **Scope creep** (interpreter, extra chapters). Mitigate with MVP gates.
6. **Unity version choice.** Decide before creating the project.
7. **Asset consistency.** One tile size and one core pack.

## 11. Deliberately excluded
Block editor, grid pathfinding, hero controller, tilemap-based gameplay rules, DI frameworks, ECS, Addressables,
networking, analytics backends, procedural generation.
