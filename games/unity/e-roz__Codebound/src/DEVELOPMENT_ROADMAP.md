# Codebound — Development Roadmap (v2.1, dated)

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**.

**Deadline: 10 December 2026 [CONFIRMED].** Start: 2 November 2026.
**Capacity [CONFIRMED]:** one developer/artist (the project lead) at ~4 h/day, ~6 days/week ≈ 24 h/week ≈ 130 h total.
Teammates handle documents, testing, brainstorming and drafting room text. Claude Code assists with code.
Estimates are rough; exams and holidays may reduce hours.

---

## Decided scope (MVP) [RECOMMENDED, replaces earlier 18-room plan]
**Chapter 1 (6 rooms, complete) + Chapter 2 (4 rooms) = 10 rooms.**
- Chapter 1 The Vaults: rooms 1.1–1.6 (`LESSON_PLAN.md`).
- Chapter 2 The Gates, no Breakpoint tool needed: 2.1 Gate Rules, 2.2 Last Guard, 2.4 Toll Boundary, 2.5 Split Treasure.
- Chapter 1 ends on the first Architect note as a "to be continued" hook. Chapters 3–7 are described as future work.
- Stretch (only if ahead of schedule): Breakpoint tool + rooms 2.3 and 2.6.
- Out of scope: Chapter 3 tools (Log Reader), interpreter, Chapters 4–7.
- A simplified Test Runner is included from the start, since "Prove" is part of every room.

## Calendar
| Week | Dates | Goal | Hours |
|---|---|---|---|
| 1 | 2–8 Nov | Unity project + git; vertical slice: room 1.1 end to end with placeholder art | ~24 |
| 2 | 9–15 Nov | Slice playtest (**go/no-go**); room state machine, Watch, Step, grading, hints, Test Runner | ~24 |
| 3 | 16–22 Nov | Room data format + validator; rooms 1.2–1.6; real art pack imported | ~24 |
| 4 | 23–29 Nov | Name entry, menu, chapter map, save; Chapter 2 rooms (4); **content freeze 29 Nov** | ~24 |
| 5 | 30 Nov–6 Dec | Audio, polish, bug fixing; full playtest with IT students; pre/post questions; **feature freeze 1 Dec** | ~24 |
| 6 | 7–9 Dec | Final build, fixes, presentation rehearsal. **Buffer. Submit/present 10 Dec.** | ~12 |

## Team tasks [RECOMMENDED]
- Draft room content in the room template: ticket text, debrief, "at work" example, wrong-fix explanations (project
  lead reviews C# accuracy).
- Run playtests with 5–10 IT students; collect pre/post questions on the concepts; record results for the report.
- Write the report, README, presentation.
- Brainstorm and vote on open story and design decisions.

## Phases (condensed)
1. **Pre-production** — done once D-decisions are signed off (this week).
2. **Vertical slice (room 1.1)** — proves the idea. Done when a classmate finishes it unassisted and can explain
   reference vs value.
3. **Framework + tools** — state machine, Watch/Step, grading, hints, Test Runner, dialogue, name entry, save,
   validator.
4. **Content** — Chapter 1, then Chapter 2 (4 rooms).
5. **UI/UX + audio/visual polish** — menu, map, results, music, SFX, effects.
6. **Testing** — playtests, bug fixing, accuracy re-review of every room.
7. **Build + presentation.**

## Risks
1. Visualiser clarity and code panel quality (mitigate in the slice).
2. Unity editor time (scenes, prefabs) — reduce with editor scripts and few prefabs.
3. Content correctness — project lead reviews every room.
4. Hours lost to exams/holidays — cut Chapter 2 rooms first (minimum 2) before cutting quality or playtests.

## Cut line (in order)
Stretch rooms → Chapter 2 rooms down to 2 → effects/lighting → music variety → audio extras. **Never cut:** failure
consequences, accuracy review, the playtest.

## Learning evidence for the report
Pre/post questions on reference vs value, off-by-one, and boundary values given to the playtesters; record the change.
