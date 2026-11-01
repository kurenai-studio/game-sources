# 186 — Read the generated level 1 document back as if designing level 2

**Task 4 of phase 11d.** `level-designer`. Branch `docs/level-document-readback`.
**Issue:** [#186](https://github.com/LuchoC-Dev/little-spaceship/issues/186).

## What was done

The three checks the contract set for this task, run rather than reasoned about.

**1. A `level-02.json` was written from the three documents alone.** `docs/levels/level-01.md`,
`docs/planning/04-campaign-and-levels.md` and `docs/plan/11c-movement-shapes/shape-catalogue.md`, with
`assets/data/` unopened until the file was finished. Eleven placements, nine new waves, one wave
reused from level 1, and every one of `strike-run`, `veer-left` and `veer-right` used as a spawn-level
`trajectory` override — the shapes 11c built and nothing in `assets/data/` points at yet. Scratch
files only; level 2 is phase 12 and no content is committed by this branch.

**2. Level 1 was broken twice in the worktree and regenerated.** Not repeating the four faults the
generator's author already tested — a fault it does **not** catch was the target, and two were found.
`assets/data/` restored afterwards: `node tools/build-level-docs.js --check` prints
`unchanged  docs/levels/level-01.md` and exits 0, and `git status --short` is empty.

**3. Section 14's absence was judged with the document in hand**, and the answer changed from the
prediction: less painful for the curve, more painful for the format's idioms.

## What was decided

**Seven corrections, appended to `docs/plan/11d-per-level-document/document-contract.md`** as a dated
"Corrections from the task-4 read-back" section, with a pointer to it under the title. Not a separate
gaps file — the plan refused that, and the contract is what the phase leaves behind. They amend
sections 5, 11, 13 and 14 and add a section 0.

| | Finding | Disposition |
|---|---|---|
| C1 | **The document names no JSON key.** `grep -n dropSlot docs/levels/level-01.md` returns nothing, and so do `"waves"`, `"spawn"`, `"offset"`, `"at"`, `"end"`. The scratch `level-02.json` opened with `"id": "level-02"` and `JsonContentSource.requireOnlyKeys(root, "level file", "boss", "events", "waves")` (`game/adapter/content/JsonContentSource.java:349`) rejects it — the level would not have loaded on the first run, which is the exact bar this contract set. Negative offsets and overlap are not mentioned in the document at all | Add a section 0, "The format". **Generator change, not made here** |
| C2 | **The Checks section teaches nothing when clean.** It prints `**No issues found.**` and never the list of what was checked, so a designer cannot calibrate what still needs verifying by hand | Always print the checks performed. **Generator change, not made here** |
| C3 | **`x extent` is a t = 0 snapshot.** A `swoop` `vee-5` at `atX 0.20` drifts 69 units left over its 6.9 s of screen time; a `veer-right` at `atX 0.85` leaves the right edge at t ≈ 0.83 s and spends its whole arc off screen. Both were added to `l1-rest-basic`, regenerated, printed as in-range, and Checks said `**No issues found.**`. `l1-finale-a` at 2.0 s is already a real instance | Swept extent plus a check, including the veer-side rule. **Generator change, not made here** |
| C4 | **One `cleared` wave switches the boss check off.** With `l1-carrier-intro` set to `{"type": "cleared"}`, "At a glance" drops the `gap between them` row entirely and Checks stays silent, because the check is guarded by `exact`. The contract calls this the most dangerous interaction in the format. The pacing table's `>=` degradation, by contrast, works exactly as specified | Keep the row, warn against the lower bound. **Generator change, not made here** |
| C5 | **No artefact lists which wave ids exist.** `waves.json` is shared and its ids are global; each document lists only its own level's waves, so cross-level reuse — 11b's whole reason for splitting waves from placements — is undiscoverable and id collisions are unguarded | A generated `docs/levels/waves.md`. **A new artefact: a decision for whoever picks it up** |
| C6 | **A level file alone is not playable.** `game/LittleSpaceshipGame.java:42` holds `LEVEL_ID = "level-01"` | One line in the header. **Generator change, not made here** |
| C7 | **Section 14's gap is felt on idioms, not on the curve.** `l1-tank-solo` is a 1.0 s wave holding one tank whose screen time is 31 s, placed three times; read cold it looks like a mistake rather than punctuation. And the pointer to `shape-catalogue.md` cannot close it, because that map is keyed by wave and one wave serves three beats | Section 14's decision stands; its recommendation to phase 12 is amended — the `"note"` belongs on the **placement**, not the wave |

**What already works, recorded so it is not re-litigated.** The footprint arithmetic chose every `atX`
in level 2 without a calculation; `shots to kill`, `screen time` and `shots per pass` chose the
archetypes; the curve made the rest and the finale legible at a glance; and `l1-tank-solo` was reused
from the document alone, because its end condition, its spawn list and all three placement times are
printed. That last one is what 11b's split exists for and it survived contact.

## What is open

- **Six generator changes are named and none is made.** `tools/build-level-docs.js` is the
  coordinator's and the issue's instruction is to name and stop. C1 and C3 are the two that decide
  whether the document meets its own bar; C2, C4 and C6 are cheap; C5 is a new artefact and a
  decision, not a fix.
- **The read-back was confounded and the confound is in the contract.** Every JSON key except the one
  that broke came from having written task 1 with `assets/data/` open, not from the document. A fresh
  agent has no such memory, which is why C1 is graded the largest finding rather than a detail.
- **Whether level 2 plays as designed is not checked and cannot be here.** Nothing was run:
  `LEVEL_ID` is fixed to `level-01`, and phase 12 is where the honest measurement happens.
