# Codebound — Game Design Document

Legend: **[CONFIRMED]** from the brief · **[RECOMMENDED]** Claude's proposal · **[OPEN]** needs a decision
(see `OPEN_DECISIONS.md`).

---

## 1. Game overview
Codebound: The Programming Dungeon is a 2D top-down puzzle adventure. The player is a young adventurer in an
ancient dungeon whose doors and mechanisms obey *instructions*. The player writes a program from visual blocks,
runs it, and the hero carries it out step by step. [CONFIRMED]

**Fantasy [RECOMMENDED]:** you are an apprentice "Codebinder" whose spells are written instructions; the dungeon
is a living machine built by the Grand Architect. Light story, delivered in a few lines per chapter (no dialogue
trees).

## 2. Target audience
- **Primary [RECOMMENDED]:** beginners with little or no programming experience, roughly 12+ and first-year
  university / senior-high students.
- **Secondary:** classmates and instructors evaluating the project.
- **[OPEN D-03]** Confirm age/level. It affects tone, reading level, and how fast difficulty rises.
- No prior gaming skill required; no real-time reflexes.

## 3. Game objectives
Player-facing: clear each room, collect treasure, descend to the final chamber.
Educational: by the end the player can read and write a sequence, a loop, a condition, a function, and can find
and fix a bug in a short program. (See §7.)

## 4. Core gameplay loop [CONFIRMED]
1. Enter a room and read the objective.
2. Observe the map (walls, hazards, switches, items, exit).
3. Build a block program.
4. Press Run.
5. Watch the hero execute it (current block highlighted).
6. If it fails, read the explanation, debug.
7. Solve the room (stars awarded).
8. Unlock the next room; new concept is introduced at chapter boundaries.

**Micro-loop** (seconds): drag block → see program grow. **Macro-loop** (minutes): one room.
**Meta-loop** (hours): chapter → new tool unlocked → harder combinations.

## 5. Gameplay mechanics
**Grid and hero.** Square grid, hero occupies one cell and faces one of four directions. [CONFIRMED]

**Hero actions (chapter I toolbox):** Move Forward, Turn Left, Turn Right, Interact (pull lever / pick up /
open). [CONFIRMED: move, turn, interact]

**World objects [RECOMMENDED]:**

| Object | Behaviour | Concept it supports |
|---|---|---|
| Wall / pit | Blocks movement (failure if walked into) | Precision, planning |
| Door | Closed until a switch/plate/key is active | State, dependency |
| Lever / switch | Toggles linked objects when hero interacts | Sequencing, state |
| Pressure plate | Active while something stands on it | Conditions |
| Key / treasure | Collectible; some required to finish | Goals, counters |
| Spikes (toggling) | Safe/unsafe depending on a state the hero can read | Conditionals |
| Exit stairs | Complete the room if goal conditions are met | Win condition |

Keep it to this list for the MVP. Every object must be reusable across chapters.

**Run controls.** Run, Step (execute one block), Pause, Reset, Speed (1x/2x/4x), Hint. *Step* and the live
highlight are essential for teaching debugging. [RECOMMENDED]

## 6. Programming instruction system
Summary (details in `GAMEPLAY_SYSTEMS.md`):
- Blocks are dragged from a **toolbox** into a **program area**. A level defines which blocks are available and
  (optionally) a maximum block count.
- Programs are a **tree**: a top-level sequence whose blocks may contain child sequences (Repeat, If, If/Else,
  Function bodies). Nesting is shown visually.
- Execution is deterministic. The same program on the same level always produces the same result.
- Blocks introduced by chapter: Move, Turn L/R, Interact → Repeat N, Repeat Until → If / If-Else with sensor
  conditions → Set / Change counter, compare → Define / Call function.

## 7. Educational objectives [RECOMMENDED]
After each chapter the player can:

| Concept | Observable skill |
|---|---|
| Sequence | Order instructions to reach a goal; predict the result of a short program |
| Loops | Replace repeated instructions with a loop; choose a loop count; know when to stop |
| Conditionals | Choose an action based on the world state; use if/else |
| Variables / counters | Store a value, change it, compare it |
| Functions | Package repeated steps, reuse them, and call them |
| Debugging | Locate and fix a wrong instruction; use Step to trace |
| Computational thinking | Decomposition, pattern recognition, abstraction, algorithm design |

Principles: concept is *needed* to solve the room (not decorative); each concept is first isolated, then combined
with earlier ones; learning is assessed by *doing* (prediction, fix-the-bug, build-with-constraint), never by
multiple-choice questions.

## 8. Chapter and level progression
### Brief's proposal [CONFIRMED as starting point, not final]
I Sequence → II Conditionals → III Loops → IV Variables → V Functions.

### Recommended re-order [RECOMMENDED, **OPEN D-02**]

| # | Chapter | Concept | Why here |
|---|---|---|---|
| I | The Forgotten Hall | Sequence + first debugging | Foundation; includes "fix the broken program" |
| II | The Endless Maze | Loops (Repeat N, Repeat Until) | Visually obvious payoff; reduces block count |
| III | The Ancient Library | Functions (reuse) | Natural extension of loops: "name a repeated pattern" |
| IV | The Logic Chambers | Conditionals (If/Else) | Now learners can combine If inside loops |
| V | The Grand Architect | Variables/counters + capstone | Combines everything in a final set of rooms |

Reasoning: this follows the order most beginner curricula use, and it avoids an early conditional chapter where
"if" has little to do until loops exist. If you prefer the original order, the engine supports either; only level
content changes.

**Size [RECOMMENDED]:** 8–10 rooms per chapter → ~40–50 rooms for the full game. **MVP: Chapters I–III, ~24 rooms
(see §16).**

**Room types (to avoid repetition):**
1. *Guided* — introduces a new block with a constrained room.
2. *Build* — open problem, any valid solution.
3. *Optimise* — solve within a block budget.
4. *Debug* — a pre-filled program with a bug.
5. *Predict* — watch the program, then answer "where will the hero end up?" by placing a marker on the map (no
   text quiz).
6. *Complete* — program has gaps to fill.
7. *Boss/capstone* — last room of a chapter combines everything.

## 9. Puzzle design principles
1. One new idea per room; combine ideas only after each is mastered.
2. The solution is reachable by reasoning, not by trial and error.
3. Multiple valid solutions are accepted; stars reward efficiency, not one "true" answer.
4. A room fails fast and *explains* why.
5. Visual clarity first: the map must be readable at a glance.
6. Small maps (roughly 6×6 to 12×12) so the program and the map fit on one screen.
7. Teach by showing: first room of a concept has the answer almost demonstrated (e.g., pre-placed example).
8. Every level is validated by an automatic solver/test (see roadmap) so no level ships unsolvable.

## 10. User interface and user experience
**Layout [CONFIRMED proposal]:** left = dungeon, right = programming workspace, top bar = chapter/level/objective/
progress, bottom = Run/Reset/Hint, feedback area for status.

**Recommended refinements [RECOMMENDED]:**
- Split the right panel into **Toolbox** (narrow, left of the panel) and **Program Area** (wide), so blocks
  are never hidden behind scrolling in early chapters.
- Give the **map ~55–60%** of the width; programs are narrow but tall, maps are square.
- Put the **feedback area under the program area**, not floating, so errors sit next to the blocks they refer
  to. Failing blocks get a red outline.
- A persistent **objective strip** in the top bar (icons: collect keys, reach exit, block limit).
- Add **Step** and **Speed** buttons next to Run.
- A **Function tab** appears in Chapter III (a second canvas beside the main program).
- Support mouse drag-and-drop *and* click-to-append (click a toolbox block to add it at the end) for
  accessibility and speed.
- Undo / Redo and "Clear program".
- 1920×1080 reference resolution with a Canvas Scaler; test at 1280×720 and 2560×1440.

**Flow:** Main Menu → Chapter map → Level (with a short intro line) → Result panel (stars, what you learned,
Next/Retry) → Back to map.

## 11. Art direction
Pixel art, retro fantasy RPG, top-down. Single consistent tile size (16×16 or 32×32 — **OPEN D-06**). Limited
cohesive palette, dark stone dungeon with warm torchlight accents, bright saturated colors reserved for
interactive objects so puzzles are readable. UI: chunky pixel-style panels, colour-coded blocks by category
(Motion = blue, Control = orange/yellow, Logic = green, Data = purple, Functions = pink). Details in
`ASSET_REQUIREMENTS.md`.

## 12. Audio direction [RECOMMENDED]
- 1 calm looping dungeon track per chapter (or 2–3 for the whole game), low-intensity so thinking is easy.
- Short UI sounds: block pick/drop/snap, Run, success, failure, hint.
- World sounds: footstep, turn, lever, door, key pickup, trap.
- Audio must never punish: failure sound is soft, not buzzer-harsh.
- Free/CC0 sources (Kenney audio, OpenGameArt, itch.io). Master/Music/SFX volume sliders.

## 13. Player feedback systems
- **Live execution highlight** on the current block.
- **Structured failure explanation** (see `GAMEPLAY_SYSTEMS.md` §6): what happened, where (block highlighted),
  and a hint of what to inspect, in plain language.
- **Tiered hints** (3 levels): nudge → concept reminder → partial solution. Hints cost nothing but are tracked.
- **Stars:** ★ solved, ★★ within block budget, ★★★ an optional insight goal (e.g., no repeated sequences).
- **Concept reveal:** after a room, a one-sentence "You used a *loop*: it repeats blocks."
- Positive feedback matters as much as errors.

## 14. Win and failure conditions
**Win:** all room goals satisfied when the program finishes (e.g., hero on exit, required items collected,
switches in required state, block limit respected).
**Failure types [RECOMMENDED]:** hit wall, fell in pit/trap, tried to interact with nothing, program finished but
goal unmet, ran too long (infinite-loop guard), stepped on a hazard, used a block in an invalid context.
Failure never ends the game; Reset restores the room instantly. No lives, no timers. [RECOMMENDED]

## 15. Difficulty progression
- Within a chapter: guided → build → optimise → debug → capstone.
- Across chapters: new concept, then recombination; map size grows slowly; block budgets tighten later.
- Hint availability stays constant; optional "challenge" rooms hold harder variants without blocking progress.
- Never gate progress behind stars (stars are mastery tracking, not a wall). [RECOMMENDED]

## 16. Minimum viable product (MVP) [RECOMMENDED, **OPEN D-04**]
**Must have**
- Grid world + hero with Move/Turn/Interact.
- Block editor: drag-drop, nesting, delete, reorder, Run/Step/Reset.
- Execution engine with highlight and the failure-reason system.
- Objects: wall, door, switch, pressure plate, key, exit.
- Chapters I (sequence + debug), II (loops), III (functions or conditionals, per D-02), ~24 rooms total.
- Feedback panel, hints, stars, save/load progress, main menu, chapter map, settings (volume).
- Basic audio and visual polish; Windows build.

**Should have:** Chapter IV, speed control, undo/redo, tutorial overlays.
**Could have:** Chapter V, code-text view, achievements.

## 17. Potential future features (explicitly out of MVP)
- Generated text view of the program (pseudo-code → real Python/C#).
- Typing mode / hybrid editing.
- Level editor and sharing; community levels.
- Teacher dashboard / analytics export.
- Localization; gamepad support; more tilesets/themes.
- Enemies with simple patterns (introduces conditions on moving state).
- Procedurally generated practice rooms.

---
### Unresolved questions
See `OPEN_DECISIONS.md` (D-02 chapter order, D-03 audience, D-04 MVP scope, D-06 tile size, D-01 Unity version).
