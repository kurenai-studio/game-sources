# #202 — Regenerate the per-level document and check it describes the level built

**Task 6 of phase 11e.** The coordinator's. Branch `docs/regenerate-level-document`.

## What was done

**The mechanical half was already done and is confirmed, not repeated.** `node tools/build-level-docs.js`
on the phase branch reports `unchanged` for both `docs/levels/level-01.md` and `docs/levels/waves.md`.
[#198](https://github.com/LuchoC-Dev/little-spaceship/issues/198) and
[#199](https://github.com/LuchoC-Dev/little-spaceship/issues/199) each regenerated and committed as
they went, and `reviewer` re-ran the generator independently on both branches before either merged.
`.github/workflows/ci.yml` regenerates on every push and fails if the tree changes.

**The half that needed doing was the read-back**, which is what the issue actually asks for: whether
the document describes the level that was built.

## The acceptance criteria, one by one

- **The Checks section is clean, or every finding is explained.** Three findings remain, all
  deliberate, all explained in `docs/levels/level-01.md` and in
  [`198-fourteen-beat-level-one.md`](198-fourteen-beat-level-one.md): the two negative offsets
  (`l1-high-pressure` at `-2.0`, `l1-twin-carriers-attachment` at `-1.5`), which are how this format
  produces overlap pressure, and `boss.entersAt 139.5` landing over `l1-boss-approach`, which is beat
  14's design. **The two findings this phase inherited are gone** — `l1-carrier-pair` and
  `l1-finale-a` no longer exist as ids, and no remaining `enemy-light`/`swoop` spawn sweeps outside
  `0 .. 208`.
- **The pacing table and the curve show the fourteen beats, with the rest before the climax visible
  as a rest.** They do, and it is legible without being told: `l1-brief-rest` at 118.5 s reads
  `0.17/s` and three bars, against `l1-final-escalation`'s `2.13/s` and forty immediately after.
- **`docs/levels/waves.md` shows no `unplaced` wave.** It shows none. All fourteen are placed exactly
  once by `level-01`.
- **Whatever the document failed to say goes back into `document-contract.md`.** Done — see below.

## The finding, and it is C8

`docs/levels/level-01.md`'s section "The beat map" says, correctly, that beat intent cannot be
generated because `assets/data/` has no field for it, and sends the reader to
`docs/plan/11c-movement-shapes/shape-catalogue.md` → "What points at what".

**That table named fourteen wave ids and #198 destroyed all fourteen.** The table is corrected here
by hand and carries a dated note saying so.

The observation is not that a table went stale. It is that `docs/levels/level-01.md` is generated and
CI-enforced, so the generated half **cannot** rot — which makes the one hand-written thing it
delegates to the single place in the chain where a level document can be wrong. It went wrong at the
first opportunity, within a day, silently, with CI green the whole time. Recorded as **C8** in
`docs/plan/11d-per-level-document/document-contract.md`, against C7 of 31/08/2026, which had blessed
that pointer with the word "stays" and proposed nothing to keep it true.

Filed as its own issue rather than fixed here, because it is a `tools/` change and #202 puts that out
of scope: a check that fails when `shape-catalogue.md` names a wave id `assets/data/waves.json` does
not have.

## What is open

- The `"note"` string on a **placement**, recommended to phase 12 by section 14 and now by C8, is the
  only proposal that would move this mapping somewhere CI can see it. Not built.
- **Not checked:** whether any hand-written document outside `docs/plan/11b-*` and `docs/plan/11d-*`
  names a live wave id. Those two do name the old ids and were deliberately left: a status file is a
  dated record of what was true when it was written, and correcting one would falsify it.

## For whoever comes next

The phase's remaining work is [#201](https://github.com/LuchoC-Dev/little-spaceship/issues/201), the
play session, and it is the project owner's — no agent can supply it. The candidate is complete and
**must not be merged into `dev` as though the phase were done**.
