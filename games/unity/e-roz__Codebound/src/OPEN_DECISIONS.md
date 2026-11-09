# Codebound — Open Decisions (v2)

Priority: **P0** blocks project setup · **P1** blocks content/design · **P2** can wait.
Recommended option is first. I will not proceed on any of these without your approval.

## Already decided
Purpose (fundamentals + industry + developer thinking) · target IT students in PH · teaching language **C#** · story
premise A+C and warm tone · player enters own name · MVP interaction = predict / investigate / **choose** hypothesis and
fix · lesson plan draft for Chapters 1–3 · v1 docs archived.

**Decided on 2026-11-02:**
- **D-05 Deadline:** 10 December 2026. One developer/artist (project lead), ~4 h/day. Team handles documents,
  testing, brainstorming, and drafting room text.
- **D-04 MVP scope:** Chapter 1 (6 rooms) + Chapter 2 (4 rooms) = 10 rooms. Chapter 3 and later are future work.
- **D-01 Unity version:** no requirement from the instructor; **2022.3.62f3 (LTS)** chosen (veto allowed).
- **D-07 Interpreter:** not for this deadline; authored traces only.
Details and dates: `DEVELOPMENT_ROADMAP.md`. The P0 sections below are kept for history.

---

## P0

### D-05 · Deadline and hours
Final submission/presentation date? Team size and roles? Hours per week? This turns the roadmap into dates and sets
the cut line.

### D-04 · MVP scope
- **A. Chapters 1–3, 18 rooms** (recommended; shrink to 4 rooms per chapter if the schedule is tight)
- B. Chapters 1–2 only, more polish
- C. Add Chapter 4 (only with slack)

### D-01 · Unity version
- **A. 2022.3.62f3 (LTS)** (recommended)
- B. 6000.5.7f1 (Unity 6 line; verify support status first)
Does your instructor require a version?

### D-07 · Interpreter
- **A. Authored traces for the MVP; optional interpreter spike after the vertical slice** (recommended)
- B. Build the interpreter first (higher risk, enables code editing)
- C. Never build it; keep the choose-the-fix model

## P1

### D-03 · Prerequisite level
Assume the student already knows basic syntax (variables, loops, methods)? Recommended: yes, and the first room has a
short refresher tooltip.

### D-06 · Tile size and core pack
16×16 (recommended) vs 32×32. Shortlist one core pack.

### D-08 · AI-generated art policy
Allowed for concept/story art only (recommended). Confirm university policy and disclosure.

### D-12 · Text language
English only (recommended) vs English with light Taglish in dialogue. Hints and explanations stay in clear English.

### D-13 · Content accuracy process
Who reviews each room's C#? Recommended: project lead reviews every room; a second person (instructor or classmate)
spot-checks.

### D-14 · Playtesters
Can you recruit 5–10 IT students for the checkpoints and pre/post questions?

### D-15 · Story details
Philippine flavour beyond Bato's name, player sprite options, the "I never wrote the tests" ending, chapter wing names
(see `STORY.md` open questions).

## P2

### D-09 · Save profiles — single slot (recommended) vs multiple (shared lab PCs).
### D-10 · Instructor reporting — none in MVP (recommended) vs exported progress file.
### D-11 · Input System — legacy Input Manager (simpler, recommended) vs new Input System.
### D-16 · Chapters 4–7 — plan after MVP validation (recommended) vs plan now.
### D-17 · Source control — Git + GitHub (recommended); Git LFS for art/audio?

---
**Suggested order:** D-05 → D-04 → D-01 → D-07 → D-03 → D-06 → D-14 → rest.
