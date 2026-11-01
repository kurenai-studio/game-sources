# Phase 10a — Honest documentation · status

**State:** done — [#50](https://github.com/LuchoC-Dev/little-spaceship/pull/50),
[#51](https://github.com/LuchoC-Dev/little-spaceship/pull/51),
[#55](https://github.com/LuchoC-Dev/little-spaceship/pull/55),
[#57](https://github.com/LuchoC-Dev/little-spaceship/pull/57),
[#58](https://github.com/LuchoC-Dev/little-spaceship/pull/58)
**Updated:** 26/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

Run by a fresh coordinator session, no `reviewer` pass, per `post-mvp-roadmap.md`. No production code
changed.

## Done

All five tasks. Three documents were produced next to this one:

| Document | What it is |
|---|---|
| [`audit.md`](audit.md) | tasks 1 and 2 — every document in `docs/` checked against the code, and what was found |
| [`decisions.md`](decisions.md) | tasks 3 and 4 — D1 resolves #5, D2 and D3 decide #3 and #4 |
| [`mechanism.md`](mechanism.md) | task 5 — what keeps documents honest, chosen against the audit's own numbers |

**Task 1 — audit `docs/` against the code.** Every markdown file under `docs/` was read, plus
`README.md`. `docs/sources/` is out of scope by the plan. **35 findings**, and the documents that were
fine are recorded too, which is what the acceptance criterion asks for. `./gradlew core:test` was run
to confirm the one measurement several documents assert: 289 tests, 0 failures.

The four that would have cost someone real work:

- **F20.** `12-architecture.md` printed ten systems in the wrong order against `SystemOrder`'s
  fourteen. Invariant 5 says the execution order *is* a game rule, so the document that teaches the
  architecture was handing out a wrong one.
- **F29.** Four of nine phase `status.md` files claimed a state that was not the state. Phase 09
  still said `in progress` and told its reader the play link was a 404.
- **F10.** `07-skin.md` was worse than `docs/STATUS.md` recorded: not only the `skin.load(...)` that
  put a false TeaVM warning into `STATUS.md`, but none of its fourteen drawables, five named colours
  or focus nine-patch is in the game either.
- **F1/F2.** The boss is six colliders with the arms at −22. Both design documents still had five and
  −18, and `02-sprite-sizes.md` calls itself the frozen footprint art is drawn against.

**Second half of task 1 — no document asserts something untrue.** 33 of the 35 corrected in
[#51](https://github.com/LuchoC-Dev/little-spaceship/pull/51). F27 and F32 are handed to 10b, which
owns the agent definitions and `CLAUDE.md`.

**Task 2 — lost decisions.** Five, of which two (`beyond-mvp.md`'s "if a new level is mostly JSON,
the architecture worked", and the campaign's five stages) turned out to have been recovered already
by `post-mvp-roadmap.md`, and are recorded as resolved rather than as findings. Level 1's fourteen
designed beats are surfaced by correcting the roadmap's count; the durable fix is phase 11's wave
format, which is the task the decision was lost from. The intensity curve is carried correctly
already. The fifth is new — see below.

**Task 3 — #5, resolved.** `rngcheck` holds its own copy of `Rng.java`; the copy is currently
identical (diffed, not assumed) and nothing enforces it. The check moves onto the real class
([#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52)); until it does, the spike is not
deletable, and `STATUS.md` now carries that as an explicit expiring exception instead of a blanket
offer to delete. Both documents agree.

**Task 4 — #3 and #4 decided**, D2 and D3, with
[#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) and
[#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) for the 11 group. No code changed.

**Task 5 — the mechanism.** One check ([#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56),
built by the 11 group), one convention (adopted now, in `how-to-run-a-phase.md`), one step in the
cycle (landed with the corrections).

## In progress

Nothing.

## Blocked

Nothing.

## Decisions taken while implementing

None of these changes a game rule, so none belongs in
`docs/planning/08-decisions-and-open-items.md`.

- **Three kinds of statement, and only one can be false.** The audit had to separate *descriptive*
  text from *prescriptive* text and from *dated records*, or a status file from August becomes a
  finding every time the code moves and the audit produces noise instead of defects. The one
  exception, and it is the one that produced #5: a dated record making a **forward-looking** claim —
  "can be re-run whenever", "remains to be done" — is read as current by the next person, so it is
  audited as descriptive.

- **`how-to-run-a-phase.md` gained a step.** The cycle said: after the merge, update
  `docs/STATUS.md`. It never said to close the phase's own `status.md`, so the last write to a status
  file happened *before* the merge and the two stores were guaranteed to diverge. That is not a slip
  in any one phase — it is the process producing F29. Editing the process document was not in the
  plan's task list; it is the direct cause of nine findings and fixing the symptom without it would
  have been exactly what the plan's goal warns against.

- **Status files are corrected, not rewritten.** Phase 09's and phase 07's stale sections are struck
  through with a dated note beside them rather than deleted. They are the record of what a session
  knew; deleting them would lose the evidence and gain a tidier file.

- **The mechanism is decided here and built by the 11 group.** `docs-refs` is a script, and the
  plan's "What is out of scope" says any code change. The acceptance criterion asks for a mechanism
  "chosen, written down, and justified", not built. The convention half is adopted immediately,
  because it is a documentation convention and this phase edits documentation.

- **Two findings deferred to 10b rather than fixed.** F27 (`13-working-with-agents.md`'s roster is
  missing `level-designer`, and the same document explains why no content agent was created) and F32
  (`CLAUDE.md` says every agent has a memory directory; `test-engineer` has none). Both are true
  today and both would be fixed wrongly here — the right correction depends on what 10b decides
  about the roster.

## Notes for whoever comes next

- **L5, a lost decision nobody had noticed.** `02-sprite-sizes.md` says, in bold, "If phase 07 needs
  different parts it should change them here first, because the art is drawn against this map."
  Phase 07 needed different parts, changed them in the code, and left the map behind. A process
  contract, written in prose, in a document nobody had to open to do the work — which is the whole
  argument for the mechanism.

- **The mechanism's limit is written down and should stay written down.** `docs-refs` cannot see a
  stale *number*: `patternCooldown 1.3` against a file saying `0.7`, `236 tests` against 289, "three
  formations" against eight. Five of the 35 findings. Nothing mechanical resolves it; the convention
  only shortens the distance to the real value.

- **For 10b.** F27 and F32 above. Also worth knowing: putting the naming convention into
  `CLAUDE.md`'s "Conventions" section is where every agent would actually meet it, and 10b is the
  phase allowed to edit that file.

- **For 10c.** The audit is the trustworthy ground 10c was sequenced to wait for, and two of its
  findings are architectural input rather than documentation: `WorldView` grew from three methods to
  five and `ContentSource` from three to eight across phases 04 and 07 (F25), and the replay format
  `12-architecture.md` described was never built, with #44 now saying most replays assert
  reproducibility rather than a rule (F24).

- **For the 11 group.** Four issues came out of this phase: #52, #53, #54, #56. Three code findings
  are recorded in `audit.md` under "Findings for the 11 group" and did not get issues, because each
  is a design call that phase makes with the game in hand — the HUD's unused `icon-*` sprites, a
  stale javadoc in `WorldRenderer`, and whether R11 and R13 get built or demoted.

- **The count that matters for phase 11.** Level 1's provisional sequence is **fourteen** beats, not
  thirteen. `post-mvp-roadmap.md` said thirteen, having dropped "Audiovisual introduction", and it is
  the list the waves get rebuilt from.
