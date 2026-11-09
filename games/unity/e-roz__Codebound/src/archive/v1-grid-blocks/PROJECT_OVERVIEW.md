# Codebound: The Programming Dungeon — Project Overview

Status: **PRE-PRODUCTION (planning only, no code yet)**
Last updated: 2026-11-01

Legend used in every planning document:
- **[CONFIRMED]** — stated by the team in the project brief.
- **[RECOMMENDED]** — Claude's proposal, awaiting approval.
- **[OPEN]** — undecided; see `OPEN_DECISIONS.md`.

---

## 1. Summary

Codebound is a 2D top-down puzzle-adventure for Windows PC. The player does not walk the hero directly. They
build a program out of visual blocks, press Run, and watch the hero execute it. Each dungeon room is a small
programming problem. The game teaches programming fundamentals and computational thinking *by solving problems*,
not by answering quizzes.

## 2. Confirmed decisions [CONFIRMED]

| Area | Decision |
|---|---|
| Name | Codebound: The Programming Dungeon |
| Genre | 2D top-down puzzle adventure |
| Platform | Windows PC |
| Engine / language | Unity / C# |
| Art | Pixel art, retro fantasy RPG |
| Camera | Orthographic, top-down |
| Movement | Grid-based |
| Education focus | Programming fundamentals, computational thinking |
| Input method | Visual programming blocks (initially) |
| Screen target | 16:9 desktop |
| Core loop | Observe → build → run → watch → debug → solve → unlock |
| Feedback | Mistakes must be *explained*, never just "Incorrect" |
| Assets | Free/Kenney/itch.io pixel art; AI concept art only where appropriate |

## 3. Environment findings (Task 1)

- `F:\UnityGames\CODEBOUND` is **empty**. No Unity project, no docs, no assets, no git repository.
- Unity Hub editors installed on this machine: **2022.3.62f3** and **6000.5.7f1**.
- Sibling folders under `F:\UnityGames` (`My project`, `MokTopRun`, etc.) are unrelated and were not touched.
- Nothing needs fixing; everything must be created later (see below).

**To be created when implementation is approved:**
1. A Unity project from the *2D (URP)* template, in the editor version chosen in `OPEN_DECISIONS.md` (D-01).
2. Git repository with a Unity `.gitignore` and (recommended) Git LFS for large binary art/audio.
3. Folder structure and assembly definitions described in `TECHNICAL_ARCHITECTURE.md`.
4. Packages: Input System, TextMeshPro, 2D Tilemap Editor/Extras. Nothing else initially.

## 4. Scope philosophy [RECOMMENDED]

- Polished and finished beats ambitious. Ship a small, complete vertical slice, then widen.
- One interaction paradigm (blocks), one camera, one tileset family, one hero.
- Every feature must answer: *does it teach a concept, or help the player see/debug?* If not, cut it.

## 5. Document map

| File | Purpose |
|---|---|
| `GAME_DESIGN_DOCUMENT.md` | What the game is and how it plays |
| `GAMEPLAY_SYSTEMS.md` | Blocks, program model, execution, failure reasons |
| `TECHNICAL_ARCHITECTURE.md` | Unity structure, modules, communication |
| `ASSET_REQUIREMENTS.md` | Art direction and asset inventory |
| `DEVELOPMENT_ROADMAP.md` | Phases, milestones, risks |
| `OPEN_DECISIONS.md` | Questions needing your approval |

## 6. Critical concept evaluation (Task 2)

### Strengths
- The core idea (programming *is* the movement) is proven (Lightbot, Human Resource Machine, Baba-style logic
  games, Code.org Hour of Code) and maps cleanly onto a grid.
- Deterministic and turn-based: easy to test, easy to debug, no physics or real-time skill needed.
- A dungeon theme naturally explains constraints (walls, doors, switches) that double as programming concepts
  (conditions, state).
- Small art scope: a top-down tileset plus one hero covers the whole game.

### Weaknesses and risks
1. **The block editor is the real game.** If dragging blocks feels clumsy, nothing else matters. It is the
   largest piece of work and the biggest risk.
2. **"Dungeon with theme" can drift into skin-deep.** A hero walking in a dungeon is cosmetic unless the world
   *state* (doors, switches, keys) creates real problems that need the concept being taught.
3. **Block-only programming can become a trap.** Players may learn to drag blocks without understanding why.
   Mitigation: prediction ("what will happen?"), tracing, debugging levels, and a text view of the generated code
   (stretch goal).
4. **Brute-force/trial-and-error solving.** If Run is free and instant, players spam attempts. Mitigation:
   block budget, efficiency stars, mandatory explanation of failures, and levels designed so *understanding* beats
   guessing.
5. **Difficulty cliffs.** Variables and functions are abstract; a sudden jump will lose beginners.
6. **Repetition.** "Walk to the exit" five chapters in a row is boring. Each chapter needs distinct objective
   *types*, not only harder maps.

### Assumptions I challenge
- **Chapter order.** Conditionals before loops is the less common order. Most beginner curricula (Code.org,
  Lightbot, Scratch tutorials) go sequence → loops → functions → conditionals → variables. Loops are easier to
  grasp visually (repetition you can *see*), and you need them to make conditionals worth using (an "if" inside a
  loop is the moment conditionals click). See GDD §8 for a recommended re-order. **Needs your decision (D-02).**
- **Variables as a full chapter.** Variables are hard to make *meaningful* on a grid. Counters ("take 3 steps",
  "collect keys, then open door when keys == 3") work, but "store and use values" in a library setting risks
  becoming a quiz. Recommend merging variables into a smaller late chapter, built around counters and inventory.
- **Five full chapters.** For a student project with an unknown deadline, five chapters is the *ceiling*, not the
  MVP. Recommend an MVP of three chapters, built fully, with chapters four and five as stretch.
- **"Functions" as the finale.** Fine pedagogically (it rewards everything before it), but it requires a
  second program canvas, which adds UI and execution complexity. Plan for it from day one, build it last.

### Features that might be unnecessarily complicated
- Node-based / free-form wiring programming (see `GAMEPLAY_SYSTEMS.md`).
- Typing real code (C#/Python) as the primary input.
- Free-roaming exploration between rooms. A level-select "dungeon map" gives the same fantasy at a fraction of
  the cost.
- Combat, enemies with AI, inventory systems, dialogue trees, RPG stats. None teach programming.
- Procedural level generation. Hand-authored levels are better pedagogy and easier to validate.

### Features that could become repetitive
- Pure navigation puzzles → fix by varying *goals*: collect all items, activate N switches in an order, reach the
  exit with ≤ N blocks, fix a broken program (debug level), predict the outcome, finish a half-built program.
- Identical feedback text → write specific, varied explanations per failure reason.
