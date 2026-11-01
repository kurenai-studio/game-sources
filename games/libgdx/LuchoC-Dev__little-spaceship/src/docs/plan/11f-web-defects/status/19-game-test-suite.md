# #19 — `game` has no test suite: task 5 of phase 11f

**Task 5 of phase 11f.** The coordinator's. Branch `docs/quit-decision-and-task-5`.

The plan words this task carefully: *"Decide #19, or execute the decision 11a made about it. 11a owns the decision of where it goes; if it landed here, this is where it gets done."*

## It did not land here, and that was decided before this phase opened

**11a decided it on 27/08/2026**, as D5 in `docs/plan/11a-rule-asserting-tests/status.md`, and the decision is recorded as a comment on [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) itself — checked, `gh issue view 19`, comment dated 2026-08-27T18:13:43Z. **No code is owed by this phase.**

The reasoning, which this phase did not re-derive:

**Not 11f.** #19 names the loader's error paths as what a suite would cover — malformed content must fail naming the file and the offending id, never a `NullPointerException`. Those paths are in `JsonContentSource`, and **11b rewrote it**: [#87](https://github.com/LuchoC-Dev/little-spaceship/issues/87) loads a level by id, and another task read `waves.json` and a level's wave references. Tests written in 11f would have been written against a file format with a known expiry date.

**Not left open either.** It had been open since phase 03, and "open" is what let phase 03's coordinate bug — `Transform.x` is playfield-local `[0,208]`, not logical `[0,480]` — survive a whole phase.

**The 12 group**, because levels 2 and 3 are what first exercise a loader keyed by level id, and the format has stopped moving by then.

## The split, which is the part worth carrying forward

D5 was **amended after `reviewer` was asked to argue with it and did**. #19 bundles two questions and only one of them was ever blocked:

| Question | Status |
|---|---|
| What to assert about `JsonContentSource`'s error messages | **Goes to the 12 group.** Depends on the format, which 11b was rewriting. |
| How to unit-test anything depending on `FileHandle` without dragging LWJGL into the suite | **Not blocked, and never was.** A harness design question, indifferent to which JSON shape 11b landed on. |

#19's own text calls the second one *"the question to answer first"*. Phase 03's two throwaway verification programs used JDK dynamic proxies for `Gdx.input`/`Gdx.graphics`, and `docs/plan/03-first-playable/status.md` transcribes their output — **the programs were never committed**, so the evidence exists and is not reproducible by anyone.

Answering the harness question early is what makes the 12 group's half cheap. It is `test-engineer`'s and `game-presentation`'s jointly, and **not built**.

## What this phase owes it

Nothing in code, and that is the whole finding. #19 stays open with the decision recorded on it.

**One loop is genuinely open, and it is not this phase's to close.** D5 ends with *"Put to the project owner, because it adds scope to a group that is not planned yet."* The 12 group is not planned yet, so the split above — one half scheduled into it, one half unscheduled and available — has not been accepted by anyone with the authority to add scope to it. Raised with the project owner at this phase's close.

## Also recorded on this branch

Two coordinator writes the phase owed, both flagged by `reviewer` when it audited [#227](https://github.com/LuchoC-Dev/little-spaceship/pull/227) and [#228](https://github.com/LuchoC-Dev/little-spaceship/pull/228):

- **The #40 decision reaches `docs/planning/08-decisions-and-open-items.md`**, as "Menu and screens, 01/09/2026". The plan's acceptance criterion is *"#40's outcome includes the decision and its reason, not only the code"*, and until now it was satisfied by a status fragment and not by the decisions file. `#228`'s agent deliberately did not write it, to avoid colliding with `#227`'s agent in the same file — the coordination worked and this is the other end of it.
- **`docs/planning/02-mvp-functional-spec.md` is corrected for both changes**, struck through and dated rather than silently rewritten: "Quit" now says its meaning depends on the target, and "No full pause menu" is marked superseded. The spec was written for a desktop game and both sentences stopped being true today.
