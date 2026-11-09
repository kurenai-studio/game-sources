# Codebound — Game Design Document (v2)

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. Supersedes v1 (`archive/v1-grid-blocks/`).
Companion docs: `STORY.md`, `MECHANICS.md`, `LESSON_PLAN.md`.

---

## 1. Game overview
Codebound: The Programming Dungeon is a 2D top-down pixel-art game where the player, an apprentice Warden, investigates
a malfunctioning ancient dungeon called the Keep. Each room is a bug ticket written in real C#. The player reads,
predicts, investigates, hypothesises, fixes and proves, learning how fundamentals work **and where they matter at
work**. [CONFIRMED]

## 2. Target audience
- **Primary [CONFIRMED]:** IT students in the Philippines (senior high through college, especially 2nd–4th year).
- **Secondary:** instructors and job-hunting graduates.
- Assumes basic familiarity with programming terms; not an absolute-beginner "what is a variable" tutorial. **[OPEN D-03]**
  confirm prerequisite level.
- Text language: English with simple wording; Taglish flavour in dialogue is possible. **[OPEN D-12]**

## 3. Game objectives
- Player: clear the Keep's rooms, restore the wings, discover why the Keep is breaking.
- Educational: students predict program behaviour, trace state, debug with a method, make safe small fixes, write/choose
  tests, and connect each concept to a real job scenario.

## 4. Core gameplay loop [CONFIRMED]
Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief (details in `MECHANICS.md`).
- Micro-loop (seconds): step a line, watch the Watch panel.
- Room loop (5–10 min): one ticket.
- Chapter loop (1 hr): six rooms ending in a Code Review or Interview room.
- Meta-loop: tools and story unlock; mentor fades.

## 5. Gameplay mechanics
- **Predict:** structured question before running (for example, "How many items are in vault B?").
- **Observe:** Run replays the code as events in the Keep: chests appear, guards link to them with threads, items move.
- **Investigate tools:** Watch (Ch1), Step Through (Ch1), Breakpoint (Ch2), Log Reader (Ch3), Test Runner (Ch3),
  Inspector (Ch4+), Git Notes (Ch7+).
- **Hypothesis:** pick the cause from options the evidence supports.
- **Fix:** choose from options (including plausible wrong ones). Each wrong choice runs and shows its own consequence.
- **Prove:** a test runs; symptom-only fixes fail with a visible reason.
- **Debrief:** one line on the concept and where it appears at work.

No movement, combat, timers, or lives.

## 6. Code instruction system (replaces the v1 block system)
The "programming" is **reading and reasoning about C#**, shown in a code panel with line highlighting. The player does
not type code in the MVP. Room content is data (`GAMEPLAY_SYSTEMS.md`). A later upgrade can let players edit code, run
by a mini C# interpreter, using the same event format. **[OPEN D-07]**

## 7. Educational objectives
By the end of the MVP the student can:
- Distinguish value and reference behaviour, predict aliasing, null, shallow vs deep copy.
- Read conditions, loops and boundaries and find off-by-one and precedence bugs.
- Handle hostile input and arithmetic edge cases.
- Read a stack trace, avoid hidden side effects, handle exceptions properly.
- Write or choose a test that reproduces a bug; split a long method.
- Use the developer habits: read before writing, predict then verify, model the state, debug with a method, think
  adversarially, decompose, prove it works.

## 8. Chapter and level progression
| # | Chapter (Keep wing) | Topic | MVP? |
|---|---|---|---|
| 1 | The Vaults | Data & Memory | Yes |
| 2 | The Gates | Logic & Flow | Yes |
| 3 | The Workshop | Functions & Errors | Yes |
| 4 | The Archive | Collections | Stretch |
| 5 | The Great Hall | OOP in Practice | Stretch |
| 6 | The Messenger Towers | Data & Systems (SQL, HTTP, JSON) | Stretch |
| 7 | The Architect's Chamber | First Week on the Job (Git, tests, tickets) | Stretch |

Room-by-room Chapters 1–3 in `LESSON_PLAN.md`. Chapters 4–7 will be planned after the MVP is validated. **[RECOMMENDED]**

Room types: Predict, Trace, Bug Hunt, Repair, Build, Code Review, Interview.

## 9. Puzzle (room) design principles
1. One concept per room; combine later.
2. Failure first: show the bug before explaining it.
3. Short code: aim for ≤ 12 lines.
4. Wrong options each represent a real misconception and show a consequence; never "Incorrect" alone.
5. Realistic symptoms phrased like tickets, with local scenarios where natural (fares, enrolment, e-wallets).
6. Each chapter ends in a Code Review or Interview room.
7. Technical accuracy reviewed by a C# expert before release.
8. Automatic validation of room data (every room has exactly one best fix, valid line references, and a test).

## 10. User interface and user experience
Left (~55%) Keep scene · Right code panel (monospaced, syntax-highlighted, current-line marker) · Top ticket and
progress · Bottom Tala's panel (Watch, hints, log) with Run / Step / Reset · Bato/Tala speech bubbles near the scene.
Code font must be a clear monospace, not a pixel font. 16:9, 1920×1080 reference. Mouse-driven; keyboard shortcuts for
Run/Step. Main menu: New game (enter your name), Continue, Settings, Credits. Chapter map = Keep map.

## 11. Art direction
Pixel-art top-down fantasy dungeon (see `ASSET_REQUIREMENTS.md`). Readability first: interactive objects pop in colour;
threads (references) are bright and animated. Warm torch lighting, cool stone.

## 12. Audio direction
One calm loop per chapter, soft UI sounds, characterful but short SFX (chest, thread link, door, test pass/fail).
Failure sounds are gentle. Volume sliders.

## 13. Player feedback systems
- Live line highlight, Watch values, thread/object visualisation.
- Specific consequence for each wrong fix.
- Three-tier hints from Tala (nudge, concept reminder, near-answer); free to use but tracked.
- Debrief line per room; chapter summary: "What you can now do at work".
- Mentor voice changes by chapter (explain → hint → confirm → gone).

## 14. Win and failure conditions
Win a room: correct hypothesis (optional for pass) and a fix that passes the test. Failure: wrong fix or failed test
only produces feedback; no game over. Reset is instant. Stars: ★ solved, ★★ right prediction and hypothesis, ★★★ smallest
safe fix with passing test. Stars never block progress.

## 15. Difficulty progression
Within a chapter: predict → trace → bug hunt → repair → review. Across chapters: more code, subtler bugs, fewer hints,
mentor withdraws. Challenge variants optional.

## 16. Minimum viable product (MVP) [RECOMMENDED, OPEN D-04]
Must: player name entry, Chapters 1–3 (18 rooms), code panel and Keep visualiser, Watch/Step/Breakpoint/Log/Test tools,
hint system, stars and save, Bato/Tala dialogue, title and chapter map, basic audio, Windows build, playtest with real IT
students.
Should: story beats between chapters, final twist teaser.
Could: Chapter 4, Interview room polish.

## 17. Future features
Chapters 4–7; code editing with a mini C# interpreter; SQL/HTTP rooms; instructor dashboard; Filipino localisation;
more themes; teacher-made rooms via an authoring tool.
