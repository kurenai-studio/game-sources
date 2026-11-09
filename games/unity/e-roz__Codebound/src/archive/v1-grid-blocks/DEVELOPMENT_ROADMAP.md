# Codebound — Development Roadmap

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**.

**No calendar dates yet.** Durations are expressed as *relative effort* (S/M/L/XL) until the deadline and
weekly available hours are known (**OPEN D-05**). The first thing to do with a deadline is count backwards and
decide where the MVP cut line falls.

Effort key: S ≈ a few days · M ≈ 1–2 weeks · L ≈ 2–4 weeks · XL ≈ 4+ weeks (at ~10–15 hrs/week, student pace).

---

## Phase 1 — Pre-production (current) · effort S
**Objectives:** settle scope, tech choices, art direction.
**Deliverables:** these seven planning docs; answers to `OPEN_DECISIONS.md`; chosen Unity version; tile size;
asset pack shortlist; mock-up of the screen layout (paper/Figma).
**Dependencies:** your decisions.
**Risks:** over-planning; unclear deadline.
**Done when:** all P0 open decisions are answered and approved.

## Phase 2 — Core gameplay prototype · effort M
**Objectives:** prove the loop with *no art polish*: grid + hero that moves from a hard-coded list of actions.
**Deliverables:** Unity project + git; `Core` grid & `WorldState`; interpreter for Move/Turn/Interact; hero moves
on a placeholder map; edit-mode tests for the interpreter; one hard-coded room completes.
**Dependencies:** Phase 1 (Unity version).
**Risks:** wrong architecture early; mixing logic with visuals.
**Done when:** a test proves a known action list solves a test room, and the same list animates in play mode.

## Phase 3 — Programming instruction system · effort L–XL (highest risk)
**Objectives:** the block editor.
**Deliverables:** program tree model; uGUI toolbox and program area; drag-drop & click-to-append; delete/reorder;
nested containers (Repeat); Run/Step/Reset; live highlight; block budget; undo/redo.
**Dependencies:** Phase 2 interpreter.
**Risks:** layout bugs in nested containers; drag edge cases; scope creep (snapping, free-form).
**Mitigation:** slot-based model; build Sequence + Repeat first; defer If/functions to later phases.
**Done when:** a new user, unassisted, can build and run a 6-block program in under a minute.

*Suggested checkpoint after Phase 3: playtest with 2–3 classmates. If the editor frustrates them, fix it before
making more content.*

## Phase 4 — Puzzle mechanics · effort M
**Objectives:** the interactive world.
**Deliverables:** walls/pits, doors, switches, pressure plates, keys, exit; `GoalEvaluator`; failure reasons;
feedback panel with first message templates; `LevelDefinition` and level loader.
**Dependencies:** Phases 2–3.
**Risks:** too many object types; rule edge cases.
**Done when:** each object has at least one test and one demo room.

## Phase 5 — Educational progression · effort M
**Objectives:** turn mechanics into a curriculum.
**Deliverables:** final chapter order (D-02); concept-by-concept toolbox unlocks; hint system (3 tiers); star
rules; introduction text per chapter; Conditionals/Function blocks as the MVP scope dictates; room type templates
(guided/build/optimise/debug/predict/complete).
**Dependencies:** Phase 4.
**Risks:** pedagogically weak sequence; functions UI complexity.
**Done when:** a written level outline for the MVP chapters exists and each room maps to a specific skill.

## Phase 6 — Level production · effort L–XL
**Objectives:** build the rooms.
**Deliverables:** MVP set (~24 rooms) authored, each with reference solution, hints, and star thresholds; editor
validator passing all rooms; playtest feedback applied.
**Dependencies:** Phases 4–5.
**Risks:** this phase is where schedules slip; difficulty spikes; unsolvable rooms.
**Mitigation:** author in batches per chapter; validate automatically; cut rooms before cutting quality.
**Done when:** every MVP room is solvable, validated, and playtested by at least two people.

## Phase 7 — UI/UX implementation · effort M
**Objectives:** complete, consistent interface.
**Deliverables:** main menu, chapter map, HUD, result panel, settings, pause, tutorial overlays, final block
visuals, scaling tested at 1280×720 → 2560×1440.
**Dependencies:** Phase 3 stable; assets chosen.
**Risks:** late UI rework; resolution bugs.
**Done when:** a first-time player can finish a room without developer help.

## Phase 8 — Audio and visual polish · effort M
**Objectives:** make it feel finished.
**Deliverables:** final art swapped in, animations, particles, lighting, SFX, music, screen transitions, credits.
**Dependencies:** Phases 6–7.
**Risks:** time sink; asset inconsistency.
**Done when:** consistent visual language, no placeholder art, `CREDITS.md` complete.

## Phase 9 — Testing and optimisation · effort M
**Objectives:** stability.
**Deliverables:** full playthrough tests, bug list closed, performance check on a low-end machine, save/load
tests, regression tests for the interpreter, usability test with target-audience players.
**Dependencies:** all prior.
**Risks:** late severe bugs; save corruption.
**Done when:** no known crashers; two uninterrupted playthroughs by non-developers.

## Phase 10 — Final build and presentation · effort S
**Objectives:** deliver.
**Deliverables:** Windows build (zip), README/how to play, demo video/trailer, presentation slides, GDD/report,
source repository, credits.
**Dependencies:** Phase 9.
**Risks:** build-only bugs; presentation prep squeezed.
**Done when:** a clean machine runs the build; presentation rehearsed.

---

## Cross-cutting
- **Vertical slice early:** by the end of Phase 4, one complete room with blocks, feedback, and real art slice.
- **Feature freeze:** before Phase 9.
- **Cut line (if time is short, drop in this order):** Chapter V → Chapter IV → hint tiers → undo/redo →
  particles/lighting → music variety. Never cut: failure explanations, Step/highlight, playtesting.
- **Playtests:** after Phases 3, 6, and 8.
- **Weekly rhythm:** demoable build every week.
