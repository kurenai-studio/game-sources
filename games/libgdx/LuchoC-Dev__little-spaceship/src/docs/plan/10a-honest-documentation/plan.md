# Phase 10a — Honest documentation

**Lane:** process · **Owner:** a fresh coordinator session · **Depends on:** 09 · **Runs first of the 10 group**

## Before you start

**Read, in this order:**

1. `docs/plan/post-mvp-roadmap.md` — what the four post-MVP groups are and why this one runs first.
2. `docs/STATUS.md` — where the project stands, and its record of what documents have already got wrong.
3. `.claude/agent-memory/reviewer/project_defect-patterns.md` — the catalogue. Several of its patterns are variants of exactly this phase's subject.
4. `CLAUDE.md` — in particular "Where state lives" and the comment conventions.

**Do not re-decide:** the invariants. This phase makes documents match reality; it does not change what the project decided.

## Goal

**No document in this repository asserts something that is not true, and there is a mechanism keeping it that way.**

The second half is the point. Correcting today's falsehoods without changing what produced them buys a few months.

## Why this runs first

Every other phase in the 10 group reads documentation to do its work. Reviewing agent definitions against a stale document, or deciding architecture from a description that does not match the code, is building on sand. Fix the ground first.

## The evidence

This is not a tidiness exercise. Documents drifting from the code has caused real, expensive failures here, repeatedly:

- **`docs/design/07-skin.md`** describes a reflective Skin integration — `Skin(FileHandle, TextureAtlas)` / `skin.load(...)` — that the code does not use and, as far as anyone has established, never did. `GameSkin` builds the whole skin in code. That stale document put a **false warning into `docs/STATUS.md`** telling phase 09 to prepare TeaVM reflection declarations for a call that does not exist. A reviewer had to read `GameSkin` to establish the truth.
- **Three times in one day**, art a phase called delivered existed only under `docs/design/`, with nothing in `assets/` and no code loading it — the sprites, then the fonts. A phase status saying the art is drawn did not mean the game could draw it.
- **Phase 09 produced two more**, both caught in review: a `status.md` claiming CI had never run on a real runner while four runs sat in the API, and a licence claim corrected in the README but left false in the status file next to it.
- **Good decisions get lost, not just falsified.** Level 1's thirteen waves were designed in `04-campaign-and-levels.md` and flattened into 92 anonymous rows. The criterion "if a new level is mostly JSON, the architecture worked" was written in `beyond-mvp.md` and had to be rediscovered. The campaign's five stages were planned and then nearly re-planned from scratch.

## Tasks

1. **Audit `docs/` against the code.** Every document that describes how something works, checked against what it does. `docs/design/07-skin.md` is the known case; find the rest. Where a document is right and the code is wrong, that is a finding for the 11 group, not something to fix here.
2. **Audit `docs/planning/` for decisions that have been lost** — things decided, still valid, and not visible from where the work happens. The four above are the known ones.
3. **Resolve [#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5).** `docs/plan/01-foundations/status.md` calls `spikes/web-viability/rngcheck/` a permanent re-runnable check; `docs/STATUS.md` says the spike can be deleted. Both cannot be true. Decide which, and make the documents agree.
4. **Decide what to do about [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3) and [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4)** — a test that forces `Rng.java` to describe forbidden APIs obliquely, and a test proving a narrower rule than the acceptance criterion it is cited for. Both are documentation defects with a code fix. **Decide here, execute in the 11 group** — no code changes in the 10 group.
5. **Decide the mechanism.** What keeps documents honest from now on. Options worth weighing rather than assuming: a check that fails when a document references code that no longer exists; a convention that a document describing behaviour must name the file it describes; making one side generated from the other; or the reviewer's checklist gaining an explicit step. **The choice must be justified against what actually failed**, not chosen for elegance.

## Acceptance criteria

- Every document in `docs/` that describes code behaviour has been checked against that code, and the check is recorded — which documents, what was found, including the ones that were fine.
- No document in `docs/` asserts something untrue at merge time.
- #5 is resolved; #3 and #4 have a written decision and an issue for the 11 group.
- A mechanism is chosen, written down, and justified against the failures listed above.
- Decisions found to be lost are surfaced where the work happens, not merely noted.

## What is out of scope

- **Any code change.** This group decides; the 11 group executes.
- Rewriting documents that are accurate but could be better written.
- `docs/sources/`, the verbatim transcript. It is evidence and stays in Spanish, untouched.
- Deciding anything about waves, movement or balance. That is the 11 group.

## Risks

**This phase can absorb anything anyone dislikes about the documentation.** The scope is *documents that assert false things* and *decisions that got lost*. A document that is merely verbose is not in scope.

**The mechanism can become heavier than the problem.** Whatever is chosen has to survive being used by a tired agent at the end of a long phase. Something nobody runs is worth less than a convention people actually follow.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, then update `status.md`.

**No `reviewer` pass on this group** — the player's decision, on the grounds that it changes documents rather than code. Recorded here because it is a departure from how 01–09 ran, and because phase 09's two rejections were both false claims *in documents*, one of them written by the coordinator. If a review step is ever added back, this is the phase that most needs it.
