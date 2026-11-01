# Phase 10b — Agents and the way sessions are run

**Lane:** process · **Owner:** a fresh coordinator session · **Depends on:** 10a · **Second of the 10 group**

## Before you start

**This phase may change `CLAUDE.md`**, which governs every agent in the project. That is allowed, by the player's decision, **with a written justification for each edit** — the file is where the invariants, conventions and commit rules live, so a rule wrongly placed there propagates everywhere.

**Read, in this order:**

1. `docs/planning/13-working-with-agents.md` — the whole document, especially "What a session costs, and when to stop". It is the regime this phase audits.
2. `docs/plan/how-to-run-a-phase.md` and `docs/plan/agent-prompts.md`.
3. `.claude/agents/` — all six definitions.
4. `.claude/agent-memory/` — all of it. Nine phases of accumulation with no pass over it.
5. `docs/plan/09-web-ci-release/status.md` — the most recent phase run under the current regime.

**Depends on 10a** because reviewing agent definitions against documentation known to be stale is work that has to be redone.

## Goal

**The regime and the agent definitions say what nine phases actually taught, and the known structural traps are closed.**

## The evidence

The current regime was written after an audit that found **~3,300 model calls, 665 million cached input tokens, and fourteen spend limits across nine contexts**, with two thirds of the equivalent cost spent re-reading conversation history rather than doing new work.

That regime — one coordinator per phase, `reviewer` on Sonnet, one issue per worker, any limit stops the flow — was followed through phase 09 and held. This phase checks it against what phase 09 actually cost and tightens what did not work.

Three things phase 09 surfaced that belong here rather than to any single agent:

- **A worker reported CI as unverifiable while four real runs sat in the API.** The workflow triggers on push; it had already run twice red and twice green before the report was written. Reasoning about a YAML file was submitted in place of evidence that was one command away. The instruction "say what you verified" was followed to the letter and produced a false statement, which means the instruction is not enough on its own.
- **Agent memory keeps being written into the wrong working copy.** `.claude/agent-memory/` is a tracked path, so an agent working from a worktree writes to whichever checkout it is standing in. This had to be corrected by hand **three times in one phase**. It is structural, and no amount of care in a prompt has fixed it.
- **Correction rounds.** Phase 09's two rejections were fixed by the coordinator rather than sent back to a closed worker, which the regime recommends. Whether that is the right default, and where its limit is, is worth writing down rather than leaving to judgement each time.

## Tasks

1. **Measure phase 09.** What it actually cost — calls, tokens, how many agents, how many correction rounds — against what the regime predicted. Numbers, not impressions.
2. **Audit the six agent definitions** in `.claude/agents/`. Nine phases of use, no revision. What each one gets wrong, asks for that nobody needs, or fails to ask for that turned out to matter.
3. **Close the memory-path trap.** `.claude/agent-memory/` being tracked means the worktree an agent stands in decides where its memory lands. Fix it structurally — a convention that survives being forgotten, not another line in a prompt.
4. **Address the "verified" problem.** An agent following its instructions produced a false claim about CI. Whatever the fix is — a rule that a claim about a system must cite an observation of that system, a checklist, a reviewer step — it must make that specific failure hard to repeat.
5. **Audit agent memory.** Nine phases of files. What has rotted, what duplicates `docs/`, what turned out to be genuinely useful. `CLAUDE.md` forbids memory holding phase progress; check whether it does.
6. **Write down when a correction goes back to the worker and when the coordinator takes it.**
7. **Adopt the branch regime** the project owner decided on 26/08/2026: `main` ← `dev` ← one phase
   branch ← one sub-branch per agent, nothing merged into `main` except by the owner, and no agent
   merging anything. *(Added after the phase started; see "What is out of scope".)*
8. **A single mandatory pre-PR check**, run by command rather than by judgement, that an implementing
   agent runs before opening its pull request. *(Added at the same time.)*

## Acceptance criteria

- Phase 09's real cost is measured and recorded next to what the regime expected.
- Every agent definition has been reviewed, and the changes are justified by something that happened, not by preference.
- The memory-path trap is closed structurally, and the fix is tested by an agent actually working from a worktree.
- The "verified" failure has a countermeasure, and it names the phase 09 case as the thing it prevents.
- Agent memory has been audited: what stays, what goes, why.
- `docs/planning/13-working-with-agents.md` reflects all of it.
- **`CLAUDE.md` is updated where the regime changed**, and every edit to it cites what motivated it.
- The branch regime is written into `CLAUDE.md`, `how-to-run-a-phase.md`, `13-working-with-agents.md`
  and the agent definitions, and this phase is run under it.
- The pre-PR check exists as a script, runs on this machine, and catches at least one class of defect
  this project has already hit.

## What is out of scope

- **Any change to game code.** This group decides and adjusts process; the 11 group touches code.
- Adding new agents. If the audit concludes one is missing, that is a finding, not a task.
- Changing module ownership boundaries — that depends on 10c.
- ~~**The git and worktree workflow.** Creating, merging and cleaning up worktrees by hand is repetitive and error-prone — one session did about ten — but the player has ruled it out of scope for this group, to stop 10b widening indefinitely.~~ **Reversed by the project owner on 26/08/2026, after the phase started**: the branch regime and the pre-PR check became tasks 7 and 8. What stays out of scope is the *ergonomics* of worktrees — creating, moving and cleaning them up by hand is still done by hand. The one part that was in scope from the beginning is task 3, because the memory path is a correctness trap rather than a convenience.

## Risks

**Optimising a regime against one phase.** Phase 09 was short, web-focused and ran mostly on documentation and CI. What worked there may not hold for a phase that rebalances a game by playing it.

**Rules that cost more than what they prevent.** Every rule added is read by every agent on every phase, and that is not free — which is the original finding that produced this regime.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md).
