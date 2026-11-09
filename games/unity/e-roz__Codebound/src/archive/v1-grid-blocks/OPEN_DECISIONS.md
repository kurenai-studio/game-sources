# Codebound — Open Decisions

Please answer these before any implementation starts. Priority: **P0** blocks the project setup, **P1** blocks
design/content, **P2** can wait.

Each item lists options and my recommendation. I will not proceed on any of these without your approval.

---

## P0 — Must decide before creating the project

### D-01 · Unity version
- **A. 2022.3.62f3 (LTS)** — stable, widest tutorial/asset compatibility. **[Recommended]**
- **B. 6000.5.7f1 (Unity 6 line)** — newest; check on Unity Hub whether it is a supported/LTS release.
- Does your instructor require a specific version? Any need for the newest features (none identified)?

### D-05 · Deadline and available hours
- Final submission/presentation date?
- Team size and who does what (coding, art, level design, writing)? Is anyone else coding?
- Hours per week per person?
This sets the MVP cut line and converts the roadmap into dates.

### D-04 · MVP scope
- **A. 3 chapters, ~24 rooms, polished** **[Recommended]**
- B. 2 chapters (~16 rooms), extra polish and extra features (text view, Step tools)
- C. All 5 chapters (~40–50 rooms), thinner polish — only if you have ample time and a team

### D-02 · Chapter order
- **A. Sequence → Loops → Functions → Conditionals → Variables/Counters** **[Recommended]** (common
  beginner curriculum; conditionals land after loops, where they are most useful)
- B. Your original: Sequence → Conditionals → Loops → Variables → Functions
- C. Sequence → Loops → Conditionals → Variables → Functions (compromise: keeps your Functions-at-the-end finale)
Related: should Variables be a full chapter, or merged into a smaller counter-based chapter (recommended)?

## P1 — Decide during design

### D-03 · Target audience
Age and level (senior-high? first-year university? general public?). Affects tone, reading level, and difficulty
curve. Is the game evaluated by programmers or by educators/non-programmers?

### D-06 · Tile size and pack
- **16×16** (recommended, e.g., Kenney Tiny Dungeon style) vs **32×32**. Pick before shopping for assets.

### D-07 · Block editor feel
- **A. Slot-based nesting + click-to-append + drag-drop** **[Recommended]**
- B. Free-form Scratch-style snapping (more complex, more bug risk)
- C. Click-only (fast to build, less engaging; fallback if time is short)

### D-08 · AI-generated art policy
Does your course allow it, and must it be disclosed? Recommended use: concept/promo art only.

### D-10 · Real-code view
Should the game show a text-code mirror of the block program (pseudo-code/Python)? Recommended: **not in the MVP**,
a stretch goal that has high teaching value.

## P2 — Can wait

### D-09 · Save profiles
Single save slot (recommended) vs multiple profiles for classroom/shared PC use.

### D-11 · Input System
New Input System package vs legacy Input Manager. Gameplay uses only the mouse; legacy is simpler, but the new
one is the current standard. Recommended: **new Input System** only if you want that experience; otherwise
legacy keeps things simple.

### D-12 · Narrative depth
Minimal (a few lines per chapter, recommended) vs lightweight story scenes vs none.

### D-13 · Language
English only (recommended) or localisation-ready from the start (adds string table overhead).

### D-14 · Analytics / assessment
Local-only progress tracking (recommended) or exported reports (e.g., for a teacher demo)?

### D-15 · Source control
Git + GitHub (recommended); confirm hosting and whether to use Git LFS for art/audio.

---

## Suggested order of answering
D-05 → D-04 → D-01 → D-02 → D-03 → D-06 → D-07, then the rest.
