# Phase 10c — Architecture review

**Lane:** process · **Owner:** a fresh coordinator session, with `core-domain` consulted · **Depends on:** 10a, 10b · **Last of the 10 group**

## Before you start

**Read, in this order:**

1. `CLAUDE.md` — the six invariants. They are the thing to argue against if anything changes.
2. `docs/planning/12-architecture.md` — the architecture as designed.
3. `docs/planning/11-technical-prototype-results.md` — what was measured rather than assumed.
4. `docs/plan/post-mvp-roadmap.md` — the 11 group, which is what this review is *for*.
5. The open technical issues: [#11](https://github.com/LuchoC-Dev/little-spaceship/issues/11), [#12](https://github.com/LuchoC-Dev/little-spaceship/issues/12), [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19), [#23](https://github.com/LuchoC-Dev/little-spaceship/issues/23), plus #3 and #4 as 10a left them.

## Goal

**A written decision on whether the architecture holds for what comes next, with reasons.**

Not a refactor. **This phase changes no code.** If it concludes something must change, that becomes issues for the 11 group.

## The question, concretely

The architecture was designed for, and validated against, one level with a fixed timeline. The 11 group intends to add:

- **Waves** as the unit of level design — a grouping above formations, possibly parameterised, possibly ending on world state rather than on a timestamp.
- **Movement as a described thing** — named shapes, varying by where in a level an enemy appears.
- **A per-level document** that is the interface an agent reads to build later levels.
- Four more levels on top of all of it.

The question is whether the current shape absorbs that, and where it strains.

Specific things worth examining, none of them prejudged:

- **The content contracts in `core.port`.** They define enemies, formations and a wave timeline today. Waves and movement descriptions are new content shapes; do they fit the existing contract, extend it, or break it?
- **`SpawnSystem` and `SpawnerSystem`.** A wave that ends when it is cleared reads world state rather than a clock. That does not break determinism — the core never reads the clock, and world state is reproducible — but it is a different control flow from a timeline, and system order is a game rule here.
- **Where a wave triggering off world state leaves the fixed system order**, which is invariant 5.
- **Whether the per-level document is content the game reads or a description of content**, which is a question with an architectural answer, not just a format one. It is also the one most likely to create two copies of one truth — see 10a.
- **Invariant 6**, no abstraction without a real case in the MVP. Four levels and agent-generated content may be exactly the real case that justifies abstractions previously refused. Or may not. This is the honest place to test that invariant against new evidence rather than treating it as settled forever.

## Tasks

1. **State what the 11 group needs from the architecture**, precisely enough to test against.
2. **Test the current architecture against it**, area by area, using the code rather than the design documents — 10a will have established which of those can be trusted.
3. **Triage the open technical issues** into: fixed in the 11 group, obsolete, or architectural. #23 in particular — a designed drop attaching to every slot of a formation — touches wave design directly, since "a difficult encounter delivers the attachment" depends on a designed drop being delivered once.
4. **Decide.** Holds as is; holds with named extensions; or needs a change, with what and why.
5. **Write it down**, including what was considered and rejected. `docs/planning/08-decisions-and-open-items.md` gets anything that changes a decision.

## Acceptance criteria

- What the 11 group needs is written down concretely.
- Each area is assessed against the code, with the evidence cited.
- Every open technical issue is triaged with a reason.
- There is a decision, with reasons, including rejected alternatives.
- If a change is needed, it exists as issues for the 11 group, sized and ordered.
- **No production code changed by this phase.**

## What is out of scope

- Implementing anything.
- Designing the wave format. This says whether the architecture can hold one; the 11 group designs it.
- Performance work. `beyond-mvp.md` already records the rule: a spatial grid and pooling wait for a profiler, not for a hunch.

## Risks

**Designing the 11 group by accident.** The line is: this phase says whether the house can take another floor, not what the floor looks like. Wave semantics are a design decision belonging to the phase that builds them.

**Treating the invariants as untouchable or as negotiable.** They were measured and breaking one invalidates earlier work — but they were measured against the MVP, and this phase has new evidence. Both errors are available; the defence against either is writing down the reasoning.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). This phase produces documents and issues, not code.
