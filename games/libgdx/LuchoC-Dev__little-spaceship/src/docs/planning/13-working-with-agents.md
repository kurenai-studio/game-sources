# Working with agents

Defined on 19/08/2026, before writing the first line of code of the real project.

## The model

A **boss** who does not carry out the fine-grained work, but decides, plans and distributes it. Below, specialised agents doing the work within a clear boundary.

The boss is the main Claude session, not a subagent. It holds the context of the whole planning stage —the measurements, the traps found, why each alternative was discarded— and that context would be lost by delegating it to an agent that starts cold.

## Memory: how context is preserved

We distinguish two things:

**Live memory.** A launched agent keeps its context while the session stays open, and work can keep being sent to it without repeating anything.

**Persistent memory.** Each agent has its own directory in `.claude/agent-memory/<agent>/`, declared with `memory: project` in its definition. When any new instance starts, the harness automatically loads its `MEMORY.md`. That way an instance launched tomorrow knows what today's learned.

That memory is **not loaded into the main conversation**: it is exclusive to the agent, and that is why it does not inflate the boss's context.

Since it lives under `.claude/agent-memory/` and not in `agent-memory-local/`, it goes into git: the accumulated knowledge is part of the repository.

### What is saved and what is not

A rule that avoids the most common problem: **an agent's memory does not repeat what is already in `docs/`**.

It saves only what that agent discovered and is not written anywhere else: where certain code lives, which trap cost it an hour, what decision of its own it made and why. If we duplicate the specification across six memories, in two weeks there are six sources of truth contradicting each other.

It is written **when a task finishes**, not continuously.

### Where it is written, which is not obvious

`.claude/agent-memory/` is a path inside the repository, and every git worktree gets its own copy of
every tracked path. An agent working from a worktree therefore writes its memory into *that*
checkout, on *that* branch — invisible to the next agent, and merged only if somebody notices. It was
corrected by hand **three times during phase 09 alone**, in the middle of the phase, by a coordinator
sending follow-up messages to live agents.

Two things close it, and neither one is an instruction to be careful:

- **`tools/agent-memory-path <agent>`** prints the one canonical directory. It resolves through
  `git rev-parse --git-common-dir`, which is shared by every worktree of a repository, so the answer
  is identical from all of them.
- **The `pre-commit` hook in `tools/hooks/`** refuses a commit that stages `.claude/agent-memory/`
  from a linked worktree, and names the directory to use instead. `core.hooksPath` lives in the
  repository's shared config, so `tools/install-hooks`, run once per clone, covers every worktree —
  including the ones created afterwards. That is what makes it survive being forgotten, which was
  the requirement.

`tools/pre-pr-check` reports the same condition, so an agent that somehow got past the hook still
sees it before its pull request.

## Roster

| Agent | Role | Writes in | Model |
|---|---|---|---|
| boss (main session) | decides, plans, delegates, reviews | everything | whatever it was started with |
| `core-domain` | rules, ECS, systems | `core/` | Sonnet |
| `game-presentation` | rendering, HUD, screens, audio, input | `game/`, `desktop/`, `web/` | Sonnet |
| `visual-designer` | visual direction and specs | documents | inherits the launcher |
| `level-designer` | the wave timeline, pacing, the intensity curve | `assets/data/level-*.json` | Opus |
| `test-engineer` | unit tests and replays | tests | Sonnet |
| `reviewer` | auditing | its own memory directory, nothing else | Sonnet |

**Corrected on 26/08/2026.** This table listed five agents while `.claude/agents/` held six — finding
F27 of the phase 10a audit. `level-designer` was created in phase 08 and wrote level 1; the roster was
never updated, and neither was the section below it.

### Why these boundaries

They are not arbitrary: **they come from the architecture**. Since the modules already have dependencies in a single direction, file ownership splits itself and two agents cannot step on each other.

`core-domain` and `game-presentation` are the back/front separation the hexagonal architecture already imposes, applied to who works on each side.

The boundaries are enforced by instruction, not by tooling, and it is worth being exact about that. `reviewer` is told to read and report, but its definition grants `Bash`, which can write, delete and run Git like any other shell. An earlier version of this document claimed it had no write tools and therefore could not modify anything; that was never true. What actually keeps a reviewer honest is the prompt and the fact that its work is reviewed in turn.

### The content agent that was discarded and then built anyway

The original decision, written on 19/08/2026, was that content — balance JSON, the odd sprite — is
touched rarely and in small changes, so an agent for it would be bureaucracy: it would be done by
whoever was working at the time.

**That was reversed in phase 08**, and the reversal was right. A level turned out not to be "content"
in the sense the decision assumed. It is a fourteen-beat timeline where the deliverable is the
*curve* — calm that makes the escalation land, an archetype taught before it arrives mixed with
others — and that is a design job with its own reading list, not an edit to a JSON file. It is also
the one job in the project whose boundary is content rather than a module, so it collides with
nobody.

The part of the original reasoning that survived: it is launched rarely, and it is the only agent
pinned to Opus, for the same reason — it decides rather than executes.

## What a session costs, and when to stop

Added on 22/08/2026 after an audit of five days of agent use. The architecture held; the way it was
run did not. Roughly 3,300 model calls processed 665 million cached input tokens, and the run hit a
spend limit **fourteen times** across nine contexts. Two thirds of the equivalent cost was re-reading
conversation history, not new work.

The lesson is not "use fewer agents". It is that a long-lived coordinator is the most expensive thing
in the system, because every turn re-reads a prefix that only grows. A late call in a days-old session
cost four times what an identical early one did.

**One coordinator per phase, or per a few hours of work.** Close it with the state in Git and start a
new one. `docs/STATUS.md` plus each phase's `status.md` is what a fresh session reads to catch up —
that is what they are for, and they work.

**Sonnet coordinates; Opus decides.** Git, launching agents, checking builds and relaying reports do
not need the heavier model. Bring Opus in for architecture, real ambiguity, and audits that turn on
judgement — then leave.

**`reviewer` defaults to Sonnet**, as its definition already says. Escalating to Opus needs a reason
written into the prompt. Nine reviews ran on Opus here on the strength of one approval given for one
specific audit; that is not what was authorised.

**A worker is one issue.** Past roughly 60–80 model calls, split it. One phase-05 agent reached 312
calls and 104 million processed tokens in a single run — most of it because correction rounds were
sent back to the same agent instead of closing it and reopening against the state already in Git.

**Any spend-limit message stops the flow.** Report it and ask before relaunching. Treating a limit as
"nothing was lost, continue" is how this project hit fourteen of them.

**Keep image inspection short and separate.** A screenshot's tokens stay in context for every turn
that follows. Look, write the conclusion down, and close the context.

## Where a correction goes

Written on 26/08/2026, after phase 09 handled two rejections without a rule and got it right by
instinct. The question is what happens when a review rejects work: back to the worker, or the
coordinator fixes it.

**While the worker is still open, and the fix is inside what it just did, send it back.** It has the
context loaded and pays nothing to reload it. Phase 09 did this once, on the web launcher — the
worker stayed open across its own review — and that worker also reached 103 model calls, the largest
in the phase. The exception is real but it is not free.

**Once the worker is closed, it is closed.** Reopening it makes it re-read everything: phase 09's
workers each pulled between 1.8 M and 6.6 M cached tokens getting started. Phase 05 is the warning —
correction rounds sent back to a closed agent produced a single run of 312 calls and 104 M processed
tokens. The alternative is not "the coordinator does everything": it is a **new issue and a fresh
agent against the state already in Git**, which is what `status.md` and the pull request exist for.

**The coordinator takes it when all of these hold**, which is the common case:

- the fix is prose — a status file, a document, a memory note, a pull request body;
- it is one or two files, and the reviewer already said exactly where;
- it needs nothing the coordinator would otherwise have to learn about the module.

Both of phase 09's rejections were exactly this shape — a false claim in `status.md` and a stale
caveat in the README — and both were fixed in minutes. That is the default.

**It goes back as a new issue when any of these hold:**

- it touches production code in a module the coordinator does not own;
- it spans more than a couple of files, or the fix requires a decision rather than an edit;
- the fix would itself need a review. A coordinator fix that needs auditing is not a coordinator fix.

**And wherever the fix lands, it lands everywhere the wrong claim did.** Phase 09's false CI sentence
was written into `status.md` *and* the agent's memory file; the status file was corrected and the
memory file was not, and phase 10a found it still wrong days later.

**The limit.** If a coordinator is taking a third correction in one phase, the plan or the brief is
what is defective, not the work. Stop and say so instead of absorbing it.

## How a task is distributed

1. The boss decides what has to be done and against which documents it is validated.
2. It writes a concrete plan for the corresponding agent, with the objective, the boundary and the invariants at play.
3. The agent consults its memory, executes and saves what it learned.
4. The boss reviews the result and, if the work justifies it, passes it through `reviewer`.

The boss **does not launch agents by default**. Delegating costs: each agent starts cold and re-reads context the boss already has. Delegation happens when the task is large and isolated, or when it is convenient for its output not to occupy the main context.

## Branches

**Changed on 26/08/2026 by the project owner.** Until then work happened on `type/description`
branches that merged back into `main`, which made `main` the trunk, the integration branch and the
branch the Pages deploy publishes, all at once.

Now there are four levels, and each one only receives a pull request from the level below:

| Branch | Who commits on it | How work leaves it |
|---|---|---|
| `main` | nobody | a pull request from `dev`, **merged by the project owner and by nobody else — an authorisation does not transfer this** |
| `dev` | nobody | a pull request from a phase branch, merged by a coordinator **only with the project owner's direct approval** |
| `phase/<phase>-<description>` | the coordinator, by merging sub-branches | a pull request against `dev` |
| `type/description` | the agent doing one task | a pull request against the phase branch |

Branching from `dev` happens only to open a phase. Every agent branches from the phase branch and
opens its pull request against it. **A subagent merges nothing** — not even its own branch. The
coordinator merges sub-branches; the phase reaches `dev` as one reviewable pull request; `dev`
reaches `main` only when the project owner decides.

**`main` is never a coordinator's merge, and permission does not change that.** Being told "you can
merge to main" is the case to stop on, not the case to act on — it happened on 26/08/2026, hours
after the rule was written, and the coordinator that wrote the rule is the one that broke it. The
branch now requires an approving review on GitHub. That is not a wall: the project's own token is an
admin token and can override it. What it does is make the merge an explicit act instead of a reflex,
which is the same reason the memory-path hook exists.

**The one merge a coordinator needs permission for is the phase into `dev`.** It is allowed, and it
is not the coordinator's call: the project owner approves that pull request directly, per pull
request. Approval of one phase says nothing about the next. Sub-branches into the phase branch need
no approval — that is the coordinator's own job — and `main` is never a coordinator's merge at all.

`docs/plan/how-to-run-a-phase.md` holds the operational version of this, next to the rest of the
cycle.

## Evidence: a claim about a system cites an observation of it

Added on 26/08/2026, after phase 09. A worker wrote — in its report, in `status.md` and in its own
memory file — that `ci.yml` "has never been run on an actual GitHub Actions runner". It had run four
times by then, twice red and twice green, and `gh run list` would have shown all four. The reviewer
caught it and rejected the pull request.

The worker was not careless: it was told to say what it had verified, and it did. What failed is that
**reasoning about a file was allowed to stand in for an observation of the system**, and both arrive
as the same confident prose.

> Naming what a system does, does not do, cannot do or has never done means naming the command that
> was run and what it printed — or the run id, the URL, the file and line. With no observation, the
> claim is written as **"not checked"**, which is always acceptable and never a failure.

"Not checked" is the half that does the work: an agent that cannot say it invents a verdict instead.
`tools/pre-pr-check` lists sentences shaped like an unobserved claim — *never run*, *cannot be
verified*, *unverifiable* — without failing on them, because each of those is legitimate when it is
true. The full case is in `docs/plan/10b-agents-and-sessions/evidence.md`.

## The check before the pull request

Also decided on 26/08/2026. An implementing agent runs **`tools/pre-pr-check`** before opening its
pull request and pastes the output into it. A red check means no pull request.

It is deliberately a script rather than an instruction: it costs no tokens, it does not vary with
how tired the agent is, and it is the only kind of verification this project has not seen produce a
false claim. It checks the branch name, commit hygiene, a clean tree, build output in the diff,
markdown links, the executable bit on scripts, whether agent memory was written from the wrong
checkout, and `./gradlew build` when the diff touches code.

On its first run it caught a script committed as mode `100644` — the same defect that made phase
09's first two CI runs die in fifteen seconds with `./gradlew: Permission denied`.

## Parallel work

Two different situations, two mechanisms.

**Several Claude sessions at once.** Each session gets its own **git worktree**. They share the repository and its history but not the working tree, so two sessions cannot overwrite each other's files. Each works on its own branch.

**Subagents launched from one session.** No agent definition carries an isolation field, and the one attempt to use the harness's `isolation: worktree` option failed here: this repository resolves the created worktree outside the intended directory, so the harness refused it. What works is the plain thing — create the worktree by hand with `git worktree add ../little-spaceship-<task> -b <type>/<description>` and give the agent that absolute path as its working directory. Return the main worktree to `main` afterwards: an agent branches from wherever it finds HEAD, and leaving a feature branch checked out there is what once made a phase branch off the art lane by mistake.

Either way, the first line of defence remains the module boundary: two agents that own different modules rarely collide even sharing a working tree.

## Language

The agent definitions are **in English**, like everything that lives in the repository, and the same applies to what they produce: code, comments and logs.

The planning documentation in `docs/planning/` has now been translated to English as well, so agents read and write in English throughout. The only Spanish that remains is the conversation with the user, plus the verbatim transcript in `docs/sources/`, which is kept untouched because it is the record of a real conversation.
