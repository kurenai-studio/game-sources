# Codebound — Project Overview (v2)

Status: **PRE-PRODUCTION (planning only, no code yet)**
Supersedes the v1 grid-and-blocks plan (kept in `archive/v1-grid-blocks/`).

Legend: **[CONFIRMED]** decided by the team · **[RECOMMENDED]** Claude's proposal · **[OPEN]** see `OPEN_DECISIONS.md`.

---

## 1. Purpose [CONFIRMED]
Teach **IT students in the Philippines** programming fundamentals **and how those fundamentals are used in the
industry**, so they learn to **think like a developer**, not only to write code.

Why: schools teach what a concept is (e.g., value vs reference types) but not why it exists, what bug it causes at
work, or how to spot it. Graduates then find that "fundamentals" alone do not match job requirements.

## 2. Summary
Codebound is a 2D top-down pixel-art puzzle game. The player is an apprentice Warden of an ancient, malfunctioning
dungeon-fortress called the Keep. Each room is a **ticket**: a symptom (for example, "Vault B holds a sword nobody put
there"). The player reads real **C#** code, predicts what it does, watches the Keep act it out, investigates with
developer tools, forms a hypothesis, picks the fix, and proves it with a test. They are graded on **process**, not luck.

## 3. Confirmed decisions
| Area | Decision |
|---|---|
| Name | Codebound: The Programming Dungeon |
| Platform / engine | Windows PC, Unity, C# |
| Teaching language | **C#** |
| Audience | IT students in the Philippines |
| Goal | Fundamentals + industry application + developer thinking |
| Genre / view | 2D top-down pixel art; the grid is a **stage** that visualises code, not a maze |
| Story | The Legacy Keep + Root Cause Mystery; warm, funny tone (`STORY.md`) |
| Player identity | Player types their own name |
| Interaction (MVP) | Predict, investigate with tools, **choose** hypotheses and fixes from options (`MECHANICS.md`) |
| MVP content | Chapters 1–3, ~18 rooms (`LESSON_PLAN.md`) |
| Assets | Free/Kenney/itch.io pixel art; AI art for concept only |

## 4. Environment findings (Task 1)
- `F:\UnityGames\CODEBOUND` was **empty** at the start: no Unity project, assets, or git repo.
- Unity Hub has **2022.3.62f3** and **6000.5.7f1** installed.
- Nothing has been created in Unity. See `TECHNICAL_ARCHITECTURE.md` §2 for setup when approved.

## 5. Document map
| File | Purpose |
|---|---|
| `STORY.md` | Premise, characters, chapter beats, twist, ending |
| `MECHANICS.md` | Room loop, tools, scoring, mentor fading |
| `LESSON_PLAN.md` | 18 rooms for Chapters 1–3 |
| `GAME_DESIGN_DOCUMENT.md` | Complete design (v2) |
| `GAMEPLAY_SYSTEMS.md` | Room data format, trace events, flow, grading |
| `TECHNICAL_ARCHITECTURE.md` | Unity structure and module communication |
| `ASSET_REQUIREMENTS.md` | Art direction and asset list |
| `DEVELOPMENT_ROADMAP.md` | Phases and milestones |
| `OPEN_DECISIONS.md` | Questions awaiting approval |
| `archive/v1-grid-blocks/` | Superseded plan; kept for reference |

## 6. Concept evaluation (Task 2, updated for v2)

### Strengths
- A clear, real gap: fundamentals taught without industry context. The game teaches the *why* and the *where it bites*.
- Failure-first teaching: players see the bug happen before learning the concept.
- Process-graded learning (predict, hypothesis, minimal fix, test) trains habits employers want.
- The dungeon is a natural visualiser: references as threads, objects as chests, state changes as visible events.
- Deterministic, no real-time skill needed; easy to test.
- The story ties lessons together (small early shortcut → big later failure = technical debt).

### Weaknesses and risks
1. **Content cost per room is high** (snippet, trace, evidence, options, test, debrief). 18 rooms is realistic; 40+ is not.
2. **Authored traces are not real execution.** In the MVP "Run" replays a trace. Players cannot experiment freely. A
   mini C# interpreter could fix this later but is a large project (see `OPEN_DECISIONS.md`).
3. **Choosing from options can be gamed** by elimination. Mitigation: plausible wrong options that each demonstrate a
   different misconception, hypothesis step before the fix, process stars.
4. **Accuracy risk.** Every C# claim must be right; one wrong lesson damages credibility. A C# expert reviews content.
5. **Reading code is hard for beginners.** Snippets must be short (≤ ~12 lines), well formatted, and introduced gradually.
6. **Story vs. learning balance.** Narrative must stay light so the dungeon does not become decoration.
7. **Scope creep** from Chapters 4–7 and the interpreter.

### Assumptions challenged
- The old plan (blocks) taught sequence and loops, not industry skills. Retired.
- "Industry readiness" cannot be fully taught in 18 rooms; the MVP proves the method on Data & Memory, Logic & Flow and
  Functions & Errors. State this honestly in the presentation.
- Typing real code and a full C# interpreter are out of MVP.

### Features judged unnecessary or too expensive for the MVP
Full interpreter, free typing, combat, inventory, branching dialogue, procedural rooms, multiplayer, accounts or
cloud saves.
