# The six agent definitions, after nine phases

Task 2 of [`plan.md`](plan.md), run on 26/08/2026. The definitions in `.claude/agents/` were written
on 19–22/08/2026 and never revised. This reads each one against what the nine phases actually did,
and the rule for changing anything is the plan's: **justified by something that happened, not by
preference.**

Where a finding is a change, it says what changed. Where it is a finding and nothing more, it says
why nothing changed — because "every rule added is read by every agent on every phase" is the finding
that produced this whole regime, and a definition is not a place to be thorough in.

## What each definition is

| Agent | Model | Memory | Verdict |
|---|---|---|---|
| `core-domain` | Sonnet | yes | **Accurate.** Its five invariants match `CLAUDE.md` and the code. Unchanged beyond the phase-wide additions |
| `game-presentation` | Sonnet | yes | **Accurate**, and the only one carrying the web pitfalls in full. Unchanged beyond the phase-wide additions |
| `level-designer` | Opus | **was missing** | **Two changes** — A1, A5 |
| `reviewer` | Sonnet | yes | **One contradiction, corrected** — A2 |
| `test-engineer` | Sonnet | yes | **Accurate**, with one shape worth naming — A6 |
| `visual-designer` | inherits | yes | **Accurate.** The unpinned model is deliberate and the definition says so in a comment |

Three things were added to all six by other tasks of this phase and are not repeated as findings
here: the branch regime and `tools/pre-pr-check` (task 7 and 8), where agent memory is written
(task 3), and the evidence rule (task 4).

## The findings

### A1 — `level-designer` had no `memory: project`, and has been writing memory nobody loads

Its frontmatter declared `name`, `description`, `tools` and `model`, and no memory. The harness loads
`MEMORY.md` for an agent that declares `memory: project`; this one does not declare it, so its three
files — 141 lines, including where a formation actually lands and `offsetY` being a head start in
pixels rather than seconds — have never been read by any instance. Its own prompt tells it to keep
writing them.

**Changed:** `memory: project` added. This is the other half of finding M3 of
[`memory-audit.md`](memory-audit.md), and the mirror image of F32 — one agent with a directory and no
declaration, one with a declaration and no directory.

### A2 — `reviewer` said "You change nothing", and then had to write and commit its memory

The definition opened with "**You change nothing**: you report", and its declared tools are
`Read, Glob, Grep, Bash, Skill`. Both are contradicted in practice: the harness grants an agent with
memory the ability to write it, and phase 09's reviewers spent their closing turns doing exactly
that. The reviewer of PR #33 finished not with a verdict but with this:

> "Committed on `chore/reviewer-memory-teavm-du` at `.../little-spaceship-reviewer-memory`. Not
> pushed, not merged, per instructions."

Two of the four phase 09 reviews ended in memory logistics — creating a worktree, cutting a branch,
diffing against `main` to build a "superset" — rather than in the audit. The instruction was
*ambiguous*, not ignored, and the agents resolved it by inventing a procedure.

**Changed:** the opening now reads "You change nothing **in what you audit**", followed by the one
exception stated plainly — its own memory, in the directory `tools/agent-memory-path reviewer`
prints, and nothing else committed. Issue #61 removed the reason the procedure existed.

### A3 — the roster in `13-working-with-agents.md` was missing an agent and denied it existed

Finding F27 of the 10a audit, left to this phase. The table listed five agents plus the boss;
`.claude/agents/` holds six. Below it, a section titled "Why there is no content agent" explained
that one had been considered and discarded — while `level-designer` existed and had written level 1.

**Changed:** the table now lists all six and gains a model column, since which model an agent runs on
turned out to be 83 % of what a phase costs (see [`measurement.md`](measurement.md)). The section is
rewritten as what it is — a decision that was reversed, with the reason it was reversed: a level is
not "content" in the sense the original decision assumed, it is a curve, and that is a design job
with its own reading list.

### A4 — nothing in any definition said how to verify a claim

The instruction the phase 09 worker followed — "say what you verified" — lived in a hand-written
prompt and in no durable document. `git grep -in verif 85b699c -- .claude/agents docs/plan/how-to-run-a-phase.md docs/plan/agent-prompts.md`,
run against the tip of `main` before this phase, returns three lines: `game-presentation`'s "always
verify with a real GPU", `level-designer`'s "verify what you can", and `reviewer`'s section heading.
Three agents are told to verify *something specific*; none is told what verifying means, and neither
the phase workflow nor the prompt template mentions it at all.

**Changed** by task 4, in all six definitions plus `CLAUDE.md`. Recorded here because the shape
matters: the rule that failed was never written down anywhere it could be improved, which is why the
failure looked like carelessness rather than a gap.

### A5 — `level-designer` is the only agent pinned to Opus, and the reason was nowhere

`model: opus`, with no explanation. Phase 09's measurement prices an Opus call at roughly five times
a Sonnet one for identical traffic, so an unexplained pin is a standing cost nobody can evaluate.

**Changed:** the reason is now a comment in the definition, the same way `visual-designer` already
documents its deliberately unpinned model — pacing is judgement rather than execution, and this agent
is launched rarely. With the note that it should be reconsidered if the 11 group ends up rebalancing
levels in a loop, where the launches stop being rare.

### A6 — `test-engineer` carries a list, and lists are the shape that rots

Its definition enumerates eight specific cases the tests must cover — the defensive priority,
invulnerability after any damage, the attachment absorbing one hit, the life and upgrade caps. Every
one is currently correct, checked against `DamageSystem` and the phase 10a audit.

**Not changed, deliberately.** But it is the same shape as the one file that rotted in nine phases of
agent memory (M1): an inventory maintained by nobody. It is defensible here because those eight cases
are *decided rules* rather than implementation state, and a rule changing is a decision that would
update the definition anyway. Naming it so that the next person who finds it stale knows it was seen.

## Considered and not added

**"A spend-limit message stops you."** The regime says any limit stops the flow, and the audited
period hit fourteen across nine contexts. It is not in any definition, and it stays out: a subagent
that hits a limit stops whether or not it was told to, and the failure the rule prevents — treating a
limit as "nothing was lost, continue" — is a *coordinator's* decision to relaunch. The coordinator is
the one who reads `13-working-with-agents.md`, where the rule already is.

**Deleting the duplicated Commits block.** Four definitions repeat `CLAUDE.md`'s commit rules almost
verbatim, which looks like waste. It is not: of phase 09's eight subagents, **five never opened
`CLAUDE.md` at all** — the four reviewers and one worker — and three did. Neither location covers
everyone, and the duplication is what makes the rule reach a reviewer. Kept, with the evidence written
down so it is not "cleaned up" later.
