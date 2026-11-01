# Phase 11d — The per-level document

**Lane:** process + code · **Owner:** a coordinator session, with `level-designer` on what the document must contain and on reading it back · **Depends on:** 11b, 11c

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "A document per level" and "How later levels get built". The second is the reason this is load-bearing rather than a convenience.
2. [`../10c-architecture-review/assessment.md`](../10c-architecture-review/assessment.md), **area G** — the architecture permits three arrangements and rules out only the fourth.
3. [`../10a-honest-documentation/mechanism.md`](../10a-honest-documentation/mechanism.md) and [`../10a-honest-documentation/audit.md`](../10a-honest-documentation/audit.md). This phase is 10a's problem with more surface area.
4. `docs/design/04-hud-layout.md` and `game/.../HudRenderer.java` — 10a's own example of a document and its code kept honest by naming each other.

## Goal

**One authored artefact per level, and a document that cannot disagree with it.**

## What was decided, and by whom

Decided by the project owner on 27/08/2026. Area G established that the architecture permits three
arrangements and prevents only two hand-maintained artefacts, so the choice was a design and process
decision rather than an architectural one. It is made:

> **The JSON is the source. The document is generated from it, and CI fails when they disagree.**

The two arrangements not taken, recorded because a future reader will ask:

- **The document authored and the JSON generated from it** is the better interface for an agent that
  designs in prose, and it is the more expensive one: it means parsing prose, and a formatting mistake
  becomes a level that does not build.
- **One artefact rendered as a document** has zero drift by construction, and it requires the authored
  format to be comfortable to read and edit by hand. JSON admits no comments, so the "document" half
  would have nowhere to put the sentence explaining why a beat exists.

**The precedent this follows already works here, twice.** `docs/design/atlas/build-atlas.js` generates
`assets/atlas/sprites.png`/`.atlas` from one source, and `docs/design/fonts/build-fnt.js` generates
`assets/fonts/*.fnt` from the hand-drawn sheets. Both were built precisely because art delivered to
`docs/design/` and never packaged into `assets/` was this project's most repeated failure — four times
in two days, per `docs/STATUS.md`.

## Tasks

1. **Decide what the document must contain**, with `level-designer`, and write that down before
   writing the generator. The bar is set by the roadmap and it is higher than a reference for a human
   who already knows the game: it is what an agent reads to design level 2 without reading the code.
   At minimum, per the roadmap's own words: for each enemy, projectile and appearance, its stats and
   what it actually does. The sequence of waves and the pacing are the other half.
2. **Build the generator**, in `tools/`, following the pattern of the two build scripts named above.
   It reads a level's JSON plus the content files it references and emits one markdown document per
   level under `docs/`.
3. **Make disagreement fail the build.** Regenerate in CI and fail if the working tree changes. This
   is the whole mechanism: without it the generator is a convenience that a tired agent skips at the
   end of a long phase, which is exactly the failure mode 10a's mechanism section warns about.
4. **Generate the document for level 1** and read it as if you were designing level 2 from it. What is
   missing from it is the finding, and it goes back into task 1 rather than into a "known gaps" list.
5. **Resolve [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) or say why it is
   separate.** `docs-refs` — fail the build when a document names code that does not exist — is 10a's
   other mechanism, still unbuilt, and it is the same class of check on the same documents. Doing both
   in one phase is cheaper than doing them twice; deciding they are different is fine, but decide it.

## The running order

Decided by the project owner on 31/08/2026, when the phase opened, and written here rather than in
`status.md` because it is a decision about how the phase is run, not a record of how far it has got.

**11c's plan named one agent too few, twice**, and `docs/plan/11c-movement-shapes/status.md` closed
with the warning that the next plan saying "loaded from `assets/data/`" would read the same way. This
is that plan, so the question was asked before any issue was opened rather than after an agent hit the
boundary: **who reads `assets/data/*.json` here?**

The answer is that this phase does not read it from Java at all. **The generator is a Node script in
`tools/`, following the precedent the plan's own decision section cites** —
`docs/design/atlas/build-atlas.js` and `docs/design/fonts/build-fnt.js`. `tools/` belongs to no agent,
Node is already on `ubuntu-latest`, and nothing in `core/` or `game/` is touched, so
`game/adapter/content/JsonContentSource.java` — the file 11c's correction was about — stays out of this
phase entirely. The alternative, a Gradle task, was refused for the opposite reason: the project's only
JSON parser is that adapter, it drags libGDX in, and it belongs to `game-presentation`.

| Round | Issues | Who | Why here |
|---|---|---|---|
| 1 | task 1 | `level-designer` | What the document must contain is set before the generator exists, or the generator's output decides it by accident — which is the "dump of every field" the Risks section refuses |
| 2 | tasks 2 and 3 | the coordinator, in `tools/` and `.github/workflows/` | The generator and the check that makes disagreement fail are one mechanism; splitting them ships a convenience nobody enforces |
| 3 | task 4 | `level-designer`, **not the coordinator** | Task 4 is a judgement on the generator's output, and the person who wrote the generator is the wrong person to make it. This is the task the Risks section names as most likely to be skipped |
| 3 | task 5 (#56) | the coordinator | A decision about a second CI check, made once the first one exists and its cost is known rather than guessed |
| — | [#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) | the coordinator | A defect found before the phase opened, not a task from the plan. `how-to-run-a-phase.md` provides for this: it gets its own issue, branch, fragment and pull request like any other |

`reviewer` audits at the close of the phase, as in 11c.

**Why #177 rides in this phase.** `pr-check` fails every `dev` → `main` release, and there is no
sanctioned branch to fix it on: rule 1 of that same workflow accepts only `phase/*` or `docs/*` against
`dev`. **Rule 1 is not weakened to let the fix through** — a phase branch is the sanctioned path and
this is one. Phases 10d and 11c both spent reviews documenting that failure mode.

## Acceptance criteria

- A generated document exists for level 1, in `docs/`, and it names the file it was generated from.
- **Editing the generated document by hand and pushing turns CI red.** Demonstrate it: the command, and
  the run that failed.
- The generator is a script, not a judgement call, and it costs no tokens to run.
- Nothing in the repository is a second hand-maintained copy of a level's content. If the phase ends
  with two artefacts a human edits, the phase failed regardless of what else it delivered.
- Every passage this phase writes into `docs/` names, in backticks, the file that implements it, or
  says "Not built" — the convention decided in 10a and stated in `how-to-run-a-phase.md`.
- #56 is closed or has a written reason for staying open.

## What is out of scope

- **Designing level 1's content.** This phase builds the format and the mechanism; the content is
  [11e](../11e-level-one-redesigned/plan.md), which then regenerates its document.
- **Generating levels.** The roadmap is explicit: none of this argues for building a generator now, it
  argues for deciding the format with agent-authored levels in view.
- Documents that are not per-level. `docs/planning/` and `docs/design/` were audited by 10a and are
  not reopened here.
- Rewriting `docs/` for style.

## Risks

**The generator becoming a report nobody designs from.** A dump of every field in the JSON satisfies
the CI check and fails the actual purpose. Task 4 is the defence, and it is the task most likely to be
skipped because it produces no artefact.

**The mechanism outweighing the problem.** 10a's own risk section says it: whatever is chosen has to
survive a tired agent at the end of a long phase. A script CI runs survives that; a convention does
not.

**Building this before the wave format is settled** would mean writing a generator for a format that
is about to change. That is why it depends on 11b and 11c, even though the roadmap asks for the
document to be settled early — the *decision* was settled early, on 27/08; the construction is here.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11d-per-level-document`, then `status.md` before review.
