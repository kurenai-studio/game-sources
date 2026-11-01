# Phase 10d — Rules the tools enforce

**Lane:** process · **Owner:** the coordinator, working alone · **Depends on:** 11b, which produced the evidence · **Runs before:** [11c](../11c-movement-shapes/plan.md)

## Before you start

**Read, in this order:**

1. [`../10b-agents-and-sessions/plan.md`](../10b-agents-and-sessions/plan.md). This phase is its successor: 10b decided how work reaches `main`, and 10d makes the parts that were left to memory mechanical.
2. [`../how-to-run-a-phase.md`](../how-to-run-a-phase.md) in full. Every change here edits it.
3. [`../11b-wave-system/status.md`](../11b-wave-system/status.md), which is where the evidence below comes from.
4. `CLAUDE.md` — the "Commits" section and "Where state lives".

## Goal

**A rule this project cares about is checked by a tool, not remembered by whoever is working.**

Phase 11b ran seven tasks across five agents and broke three written rules. None of the breaks was carelessness in the ordinary sense: each one happened where the rule existed only as a sentence someone had to recall at the right moment. This phase moves those rules into the hook, the script and CI.

It changes no production code.

## The evidence

All of it from phase 11b, on 28/08/2026.

- **An agent force-pushed** to resolve a conflict in `docs/plan/11b-wave-system/status.md`, which its own definition forbids in as many words ("Never force-push"). The conflict existed because **every parallel agent edits that one file**. We gave agents a task that guarantees collisions and then forbade the obvious way out.
- **An agent worked in the main checkout instead of a worktree**, on the phase branch, leaving six modified files there. The instruction to create a worktree existed **only in the launch prompt** — no agent definition mentions worktrees as an obligation.
- **Three agents wrote three different malformed commit scopes** — `docs(core-domain memory):`, `docs(level-designer memory):` — because nothing says which scope a memory commit takes, and nothing says `tools/pre-pr-check` requires `[a-z0-9._-]` with no spaces. Fixing them at the end cost a history rewrite, an explicit exception from the project owner, and corrections to three closed issues whose cited hashes the rewrite destroyed. See [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132).
- **Two merged pull requests recorded nothing in the phase status.** #124 and #127 never touched `status.md`, so the negative-offset defect and its fix were invisible in the phase record until the coordinator wrote them in at close. The same file that produces conflicts also produces silent gaps.
- **`agent-prompts.md` still tells agents to branch from `main`** and open pull requests against `main` — the regime 10b replaced on 26/08/2026. The six agent definitions say the opposite, correctly. Two documents an agent reads disagree.

## What was decided, and by whom

Decided by the project owner on 28/08/2026, in the conversation that followed 11b's merge.

- **The coordinator creates the branch and the worktree, and launches the agent inside it.** The agent never runs `git worktree add`. A step that cannot be skipped is better than an instruction that can.
- **One status file per task, not one per phase.** `docs/plan/<phase>/status/<issue>-<slug>.md`, written by the agent doing that task, on its branch. The phase's own `status.md` keeps the `State:` line and the narrative, and the coordinator writes it at open and at close.

  This was **not** the coordinator's first proposal, which was to take `status.md` away from agents entirely. The project owner rejected it for a reason already written in `how-to-run-a-phase.md`: the status is updated on the branch *"before the PR is reviewed"* precisely because *"it travels with the code, and it lets the reviewer check whether the status tells the truth."* Removing agent authorship would have broken that. The problem was never who writes — it is that everyone writes **the same file**.
- **`pre-pr-check` requires the fragment** when the diff touches `core/`, `game/`, `desktop/`, `web/` or `assets/`. A docs-only branch is exempt, which is what the coordinator's own bookkeeping branches are.
- **Every pull request against a phase branch closes exactly one issue** — including defects found mid-phase, which today's wording ("one per task in the plan") does not cover. The coordinator's documentation pull requests are the one named exception, and they carry no fragment.
- **A second check, `pr-check`, verifies the pull request as an object**, in CI. It exists because the things it checks *cannot* be known before the pull request exists — that is not a flaw in `pre-pr-check`, which runs early on purpose.
- **`pr-check` runs `pre-pr-check` itself.** Today "the agent ran the check" is a claim we believe because text was pasted into a description. In 11b a pull request's description described behaviour that a later round had deleted, and a human caught it, not a script. Running it in CI turns a claim into a fact.

### The limit on `pr-check`, stated by the project owner

**`pr-check` verifies only facts checkable without reading prose.** Base branch, issue link, draft status, file names, a reproducible script's exit code. It never judges whether a description is well written or faithful — that is `reviewer`'s work, and a script that pretends to do it would hand out false confidence.

## Tasks

One issue each. The coordinator does all of them, alone, and the branch regime applies unchanged: a `type/description` sub-branch per issue, a pull request against `phase/10d-enforced-workflow`, nothing committed on `dev` or on the phase branch except by merging.

1. **One status file per task.** Create `docs/plan/<phase>/status/` as the shape, document it in `how-to-run-a-phase.md`, and state what a fragment contains. The phase `status.md` keeps `State:`, `Updated:` and the narrative.
2. **`pre-pr-check` requires a status fragment** when the diff touches `core/`, `game/`, `desktop/`, `web/` or `assets/`. Mechanical: it reads the diff, not GitHub. Exactly one new file under a phase's `status/`.
3. **The issue contract.** `how-to-run-a-phase.md` and `CLAUDE.md` say that every pull request against a phase branch closes exactly one issue, naming the coordinator's documentation pull requests as the exception.
4. **The coordinator owns branches and worktrees.** Write it into `how-to-run-a-phase.md` and `agent-prompts.md`: the coordinator runs `git worktree add`, and the launch prompt names an absolute working directory that already exists. Remove the instruction that told agents to create their own.
5. **Fix `agent-prompts.md`.** It still says branch from `main` and open against `main`. Bring its template in line with the regime 10b decided, including the working-directory change from task 4.
6. **`pr-check` in CI.** A workflow triggered by `pull_request` against any branch — today `ci.yml` triggers `pull_request` only for `main`, so no phase pull request has ever run one. It asserts: base is a phase branch (or `dev`, for a phase pull request), the body closes exactly one issue or the branch is docs-only, a status fragment exists and is named for that issue, the pull request is a draft when opened, and `tools/pre-pr-check` passes when run by CI rather than quoted.

Also close [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132) as part of task 1 or 3, whichever ends up naming the memory-commit subject: the `pre-commit` hook in `tools/hooks/` should reject a malformed subject on an agent-memory commit at the moment it is written, and the exact form — `docs(memory): <what was learned>` — belongs in `CLAUDE.md` and in the six agent definitions.

## Acceptance criteria

- **A parallel-agent conflict on the phase status is impossible by construction**, because no two tasks write the same file. Demonstrated, not asserted: this phase uses the new fragments for its own tasks from task 1 onward.
- `tools/pre-pr-check` fails a branch that changes code and adds no fragment, and passes a docs-only branch that adds none. **Both directions tested.**
- `.github/workflows/` carries a `pull_request`-triggered check that runs on a pull request against a phase branch, and there is a **run id** proving it ran — not a green badge inferred from configuration.
- `docs/plan/agent-prompts.md` contains no instruction to branch from `main` or to open a pull request against `main`.
- No document tells an agent to create its own worktree, and `how-to-run-a-phase.md` says the coordinator does it.
- The `pre-commit` hook rejects `docs(core-domain memory): x` and accepts `docs(memory): x`. **Tested by running it, with the output recorded.**
- `#132` is closed.
- Nothing under `core/`, `game/`, `desktop/`, `web/` or `assets/` changes. This phase touches process, not the game.

## What is out of scope

- **Judging prose.** The limit above is the project owner's and it is not negotiable inside this phase.
- **Changing the branch regime.** Four levels, who merges what, and the owner's exclusive merge into `main` all stand as 10b decided them.
- **Rewriting any history.** The three malformed subjects from 11b are already fixed and their cost is recorded; nothing else is touched.
- **The debts 11b opened** — [#117](https://github.com/LuchoC-Dev/little-spaceship/issues/117), [#123](https://github.com/LuchoC-Dev/little-spaceship/issues/123), [#128](https://github.com/LuchoC-Dev/little-spaceship/issues/128), [#129](https://github.com/LuchoC-Dev/little-spaceship/issues/129). They are real and they are not this phase.
- **`game`'s missing test suite**, [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19), which #117 and #128 both land on. Not process; it is code.

## Risks

**Enforcing a rule that turns out to be wrong.** A check that fails a legitimate pull request costs more than the rule buys, and the first instinct will be to add an escape hatch — which is how a check becomes decorative. Any exemption must be a named category, like the coordinator's documentation branches, not a flag anyone can pass.

**`pr-check` growing past its limit.** Every future annoyance will look like something the script could catch. The line is prose: if verifying it requires reading English and forming a view, it is `reviewer`'s.

**Opening the `pull_request` trigger.** `ci.yml` currently runs on every push to every branch and on pull requests to `main` only. Adding a trigger changes what runs and when, and a workflow that runs twice on the same commit wastes minutes on every push. Check what the new trigger duplicates before adding it.

**Bootstrapping.** Task 1 creates the fragment convention that tasks 2–6 are supposed to follow. Task 1 itself has no fragment to write against a convention that does not exist yet, and its own `status.md` entry is the last one written the old way. Say so in the commit rather than pretending the phase was consistent from its first line.

**Doing it alone.** The coordinator wrote the prompts these rules are meant to fix, so the coordinator is the least likely person to notice a rule that only makes sense to someone who already knows the context. A `reviewer` pass at the end of the phase is worth more here than usual, and its brief should be "would an agent who has read only these documents do the right thing".

## Workflow

See [how to run a phase](../how-to-run-a-phase.md) — the version this phase is editing. One issue per task, one branch per issue, a pull request against `phase/10d-enforced-workflow`, then the status fragment before review.
