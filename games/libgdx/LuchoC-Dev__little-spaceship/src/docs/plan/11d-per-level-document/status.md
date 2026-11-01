# Phase 11d — The per-level document · status

**State:** done — merged into `dev` in [#195](https://github.com/LuchoC-Dev/little-spaceship/pull/195), approved by the project owner on 31/08/2026
**Updated:** 31/08/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch. Read those for what each one did; this is what the phase amounts to.

## Done

**`assets/data/` is the only thing a person edits, and a document that cannot disagree with it is generated from it.** `tools/build-level-docs.js` writes `docs/levels/level-01.md` and `docs/levels/waves.md`, and `.github/workflows/ci.yml` regenerates them on every push and fails if the tree changes.

**The acceptance criterion was demonstrated, not argued.** One line of the generated document was edited by hand — `the boss enters at 302.0 s` to `180.0 s`, with nothing under `assets/data/` touched — and [run 33411807522](https://github.com/LuchoC-Dev/little-spaceship/actions/runs/33411807522) failed, printing the diff and the command that fixes it. Both commits, the break and the revert, are on `ci/level-document-drift` on purpose: the red run is the evidence, and deleting the commit that caused it would delete the claim.

Five tasks plus three defects, in nine pull requests: [#178](https://github.com/LuchoC-Dev/little-spaceship/pull/178), [#179](https://github.com/LuchoC-Dev/little-spaceship/pull/179), [#181](https://github.com/LuchoC-Dev/little-spaceship/pull/181), [#184](https://github.com/LuchoC-Dev/little-spaceship/pull/184), [#185](https://github.com/LuchoC-Dev/little-spaceship/pull/185), [#188](https://github.com/LuchoC-Dev/little-spaceship/pull/188), [#189](https://github.com/LuchoC-Dev/little-spaceship/pull/189), [#191](https://github.com/LuchoC-Dev/little-spaceship/pull/191) and [#193](https://github.com/LuchoC-Dev/little-spaceship/pull/193). Issues #177, #180, #182, #183, #186, #187, #190 and #192.

The document is fifteen sections — the fourteen [`document-contract.md`](document-contract.md) decided before the generator existed, plus the section 0 the read-back proved was missing. Two of the fragments, `180-` and `182-`, say "fourteen"; they are dated records of what was true when written and stay as written.

## The three defects, and each was found a different way

**[#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) was two failures, not one, and the second had never run.** `pr-check.yml` has two steps and the release died in the first, so the step that runs `tools/pre-pr-check` never executed — no output from it anywhere in [run 33280307470](https://github.com/LuchoC-Dev/little-spaceship/actions/runs/33280307470)'s log. Fixing only the workflow's rule 2, as the issue proposed, would have moved the red check one step to the right. **A red check that never ran hides the next one.**

**[#190](https://github.com/LuchoC-Dev/little-spaceship/issues/190) was found by using the document, and nothing else would have found it.** `level-designer` wrote a real `level-02.json` from `docs/levels/level-01.md` alone and it did not load: the document printed values and never keys, so the top-level key was guessed wrong against `JsonContentSource.requireOnlyKeys` (`game/adapter/content/JsonContentSource.java:349`). Ten of eleven other keys came out right — **from having written task 1 with `assets/data/` open**, which the fragment states as the confound rather than as the result. The same read-back found that `x extent` was a spawn-instant snapshot blind to every shape with a `vx`, and that one `cleared` wave switched the boss check off.

**[#192](https://github.com/LuchoC-Dev/little-spaceship/issues/192) survived all of it.** The boss section asserted every ray leaves through a side edge; two of six are steeper than 45° and reach the floor first, and the document printed a `y at the side edge` of `-199.4` for one of them — a place that projectile never gets to. **It passed a contract, a generator, a CI check and a read-back, because every one of them read the same sentence instead of the geometry.**

## What the phase learned

**A mechanism that regenerates cannot check what it quotes.** The `CODE` and `DROP_KINDS` tables at the top of `tools/build-level-docs.js`, section 0's key lists, and the boss's derived rows are all copied out of `core/` and `game/`. Regenerating produces identical text whether or not the Java still says it, so the phase's own mechanism is blind to exactly this class of rot — and #192 is what that blindness looks like when it fires. Every one of them names its file in backticks, which is the mitigation the contract chose and what [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) would enforce.

**Task 4 was the task most likely to be skipped and it found the most.** The plan's own Risks section named it: it produces no artefact of its own, and it produced two defects and seven corrections. It was `level-designer`'s deliberately — a judgement on the generator's output, which the generator's author is the wrong person to make.

**The `reviewer` pass did not run.** It died on the account's monthly spend limit, and the coordinator audited instead, per the precedent set on 20/08/2026 and recorded in `.claude/agent-memory/reviewer/`. That audit found #192 and confirmed the rest by running rather than reading: the generator's output is a pure function of the content; the eleven constants it quotes from `core/` are all still true in the files it names; fourteen derived figures reproduce from an independent traversal of `assets/data/`; `* text=auto eol=lf` in `.gitattributes` keeps the drift check honest on Windows, where `core.autocrlf` is `true`; and both `level-designer` branches stayed strictly inside `docs/plan/11d-per-level-document/`.

## Decisions taken while implementing

- **The generator is a Node script in `tools/`, not a Gradle task.** The project's only JSON parser is `JsonContentSource`, which drags libGDX in and belongs to `game-presentation`; `tools/` belongs to no agent. This is also the answer to 11c's warning that a plan saying "loaded from `assets/data/`" needs three agents — **this phase reads it from no Java at all.**
- **The document does not carry design intent, and says so in one line pointing at where intent lives.** JSON admits no comments; area G of [`../10c-architecture-review/assessment.md`](../10c-architecture-review/assessment.md) predicted this as the price of generating the document from the JSON. Inferring a beat from a wave id would have been confidently wrong about `l1-tank-solo` three times over.
- **The `"note"` string recommended to phase 12 belongs on the placement, not on the wave** — the wave is the reusable unit and a beat is a use of it, and `shape-catalogue.md`'s beat map is keyed by wave and therefore cannot express it.
- **[#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) stays open**, decided by measuring rather than estimating: 8,988 backticked spans, 271 unresolved with a naive extractor and 122 with a narrowed one, and about fifty of the remainder are libGDX and JDK names — the short allow-list #56 set as its bar. It is a phase of its own because roughly fifteen of the rest are **real rot in `docs/`**, and chasing those is 10a's kind of work. [`docs-refs-decision.md`](docs-refs-decision.md) holds the rules so nobody re-derives them.
- **The curve's bar is scaled per level, and `docs/levels/waves.md` is its own file**, so no level's document changes when another level does.

## Notes for whoever comes next

**[11e](../11e-level-one-redesigned/plan.md) is the first honest test of all of this.** Its `level-designer` writes real content against `docs/levels/level-01.md`, and it is the first reader who did not help build the document. **Nobody has yet written a level file from the corrected document and loaded it** — the key lists are verified against all ten of `JsonContentSource`'s `requireOnlyKeys` call sites, which is the strongest available substitute and is not the same thing.

**Two spawns in shipped content are flagged and were not fixed.** `l1-carrier-pair` and `l1-finale-a` each place `enemy-light` in `diagonal-mirror` on `swoop` far enough left that 53% and 63% of the swept width sits outside `0 .. 208`. They read in range at the spawn instant. `assets/data/` is `level-designer`'s and level 1's content is 11e's, so they are reported in the document's own Checks section and left there.

**#177's fix has not been observed passing on a real runner.** That needs a `dev` → `main` pull request, and none has been opened since it merged. The first release after this merges is the observation, and whoever opens it should record the run id in [`status/177-pr-check-release-exemption.md`](status/177-pr-check-release-exemption.md).
