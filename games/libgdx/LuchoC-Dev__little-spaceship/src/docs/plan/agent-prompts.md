# Writing prompts for agents

For launching an agent by hand. The main session normally does this on its own, but the prompt has to be built the same way either way.

## The principle

**The prompt points at the plan; it does not repeat it.**

Every phase has a `plan.md` written to be self-sufficient, with a "Before you start" section naming exactly what to read. If the prompt restates it, two things go wrong: the two copies drift, and the plan stops being tested. When an agent has to come back asking for something the plan should have said, that is a defect worth fixing in the plan — and a fat prompt hides it.

A good prompt is short. It says which work, where the boundaries are, how to deliver, and what to be careful about. Nothing else.

## Template

```
<One line: what to do and where the instructions are.>

Working directory: <absolute path>

**Your instructions are in `<path to plan.md>`.** Read it in full, follow its
"Before you start" section, and work from its task list and acceptance criteria.
It is written to be self-sufficient — if you find it is not, say so in your
report, because that is a defect worth fixing.

This closes GitHub issue #<n>.

## Scope
<Only if the task pushes past the agent's normal boundary. State the exception
and its limit explicitly, or omit this section.>

## Working method
- Your worktree is `<absolute path>`, already on branch `<type>/<description>`,
  branched from `phase/<phase>-<description>`. Work there and nowhere else. Do
  not create a worktree or a branch — the coordinator made both.
- Never commit on `main`, on `dev` or on the phase branch. Your own branch only.
- Commit through the `/git-commit` skill. Several small commits beat one large one.
  A scope takes only `a-z 0-9 . _ -` and never a space; the `commit-msg` hook
  refuses anything else as you write it.
- Record your task in its own file, `docs/plan/<phase>/status/<issue>-<slug>.md`,
  before review. Never the phase's shared `status.md` — that one is the
  coordinator's.
- Run `tools/pre-pr-check --base phase/<phase>-<description>` before you open
  anything and paste its output into the pull request. A red check means no
  pull request.
- Push and open a **draft** pull request **against the phase branch**, closing
  the issue. **You merge nothing** — the coordinator merges.
- Record in your agent memory what you learned that is not already in `docs/` —
  gotchas and constraints, not phase progress. It goes in the directory
  `tools/agent-memory-path <your name>` prints, which is the main checkout and
  not your worktree, and its subject is `docs(memory): <what you learned>`.

## Watch out for
<One or two real risks. Not a checklist — the things that would actually go
wrong, and why they are hard to notice.>

## Stop rule
If the same thing fails twice, stop and report instead of trying a third
variation. Two failures usually mean the problem is not where it looks.

## Report back
Keep it short: what you built, anything in the plan that was ambiguous or
missing, decisions you had to make that it did not cover, and which acceptance
criteria pass and which do not.
```

## What makes the difference

**"Watch out for" is where the value is.** Everything else is form. Use it for the failure that is invisible until much later — the `Rng` diverging between runtimes, an allocation per frame, a rule that was corrected mid-planning and whose old version is still the intuitive one. Naming two real risks beats listing ten generic ones.

**Ask for the plan's defects.** Agents will paper over a gap rather than report it unless told otherwise. That feedback is the only way the remaining plans improve.

**Draft pull requests, not ready ones.** The review happens before the PR is marked ready, so nothing merges on the author's own say-so.

**Hand over a path, not a command.** The working-method block above names a worktree that already exists, because in phase 11b an agent given the `git worktree add` command simply did not run it and worked in the main checkout instead — on the phase branch, where two other agents were committing their memory. A step the coordinator has already taken cannot be skipped.

**Say what not to do when the temptation is real.** "Do not over-build the ECS" worked because the pull towards archetypes and queries is genuine. Prohibitions nobody would have violated are noise.

## Choosing the agent

| Work | Agent |
|---|---|
| Game rules, ECS, systems | `core-domain` |
| Rendering, HUD, screens, audio, input | `game-presentation` |
| Palette, sprite sizes, HUD layout, legibility | `visual-designer` |
| Unit tests and replays | `test-engineer` |
| Auditing finished work | `reviewer` |

Boundaries come from the module architecture. If a task spans two agents, split it rather than granting an exception — the exception in phase 01 was for build scaffolding, which belongs to nobody, and it was worth stating its limit precisely.

## Which model

`core-domain`, `game-presentation`, `test-engineer` and `reviewer` are pinned to Sonnet in their definitions. Most of the work here is execution against a plan that already states the tasks and the acceptance criteria, and that does not need more.

`visual-designer` pins no model and inherits from whoever launches it, because it is launched by hand.

Where a heavier model earns its cost is judgement rather than execution: a phase that has to *decide* something the plan left open, and an audit of work that matters. The phase 01 review is the example — it found a dead accessor that opened a ghost-state path, and proved it by compiling a probe and running it. No grep finds that, and a shallow review is worse than none because it hands out false confidence.

When a task looks like that, the orchestrator says so rather than deciding alone, so it can be launched with the heavier model.

## Reviews are prompts too

A review prompt has one extra job: **say what has already been checked**. Re-running the greps and the build wastes the audit on the cheap half.

Point it at what a grep cannot see — leaked mutable references, iteration order, whether the tests assert real rules or just that a setter sets, over-engineering the plan warned against. Ask it to argue with the author's recorded decisions rather than merely flag them. And tell it that finding nothing is a valid result, or it will manufacture something.
