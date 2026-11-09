# Codebound: The Programming Dungeon

A 2D top-down pixel-art puzzle game that teaches C# and real-world software habits by making you **debug**, not just read.

You play a new Warden of the Keep, a codebase that keeps breaking. Each room is a bug ticket. You predict what the code does, watch it run, find the cause, pick a fix, and prove it with a test.

Built as a final-year IT project. Target audience: Philippine IT students and career-shifters.

## What you learn

| Wing | Topics |
|---|---|
| 1. The Vaults | Value vs reference types, copies, null |
| 2. The Gates | Conditions, loops, off-by-one, parsing input |
| 3. The Workshop | Methods, side effects, exceptions, stack traces, unit tests |
| 4. The Archive | Collections |
| 5. The Great Hall | Object-oriented programming |
| 6. The Messenger Towers | SQL, JSON, HTTP |
| 7. The Architect's Chamber | Git, writing tests, root-cause thinking |

7 wings, 42 rooms, 126 stars, and a story ending.

## How a room works

Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief

Every fix is rated **Best**, **Symptom only** or **Wrong**, and you see the consequence of your choice replayed in the Keep before the test runs. Stars reward predicting correctly, finding the cause first try, and using few hints.

## Tech

- Unity 2022.3 LTS, 2D URP, C# 9, uGUI + TextMeshPro
- Game rules live in a pure C# assembly (`Codebound.Core`) with no engine references, so they are unit-tested outside the editor
- 500+ NUnit edit-mode tests (room data, trace layout limits, star scoring, unlock rules, save file)
- Rooms are authored as data (code lines, execution traces, fix options) and replayed by a small trace engine

```
Assets/_Project/Scripts/Core   game rules, rooms, trace engine (no UnityEngine)
Assets/_Project/Scripts/App    app wiring and save
Assets/_Project/Scripts/UI     scenes and panels
Assets/_Project/Tests/EditMode unit tests
Plans/                         design plan written before each chapter was built
```

## Run it

1. Install Unity **2022.3.62f3** (LTS) from Unity Hub.
2. Open this folder as a project.
3. Open `Assets/_Project/Scenes/MainMenu.unity` and press Play.
4. Run tests: Window → General → Test Runner → EditMode → Run All.

## Docs

Game design: [GAME_DESIGN_DOCUMENT.md](GAME_DESIGN_DOCUMENT.md), story: [STORY.md](STORY.md), lesson plan: [LESSON_PLAN.md](LESSON_PLAN.md), architecture: [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md).

## Credits and license

Code by e-roz, MIT licensed (see [LICENSE](LICENSE)). Third-party assets are listed in [CREDITS.md](CREDITS.md).
