# 139 — agent-prompts.md brought in line with the regime

**Task 5** · closes [#139](https://github.com/LuchoC-Dev/little-spaceship/issues/139) · branch `docs/fix-agent-prompts`

## What was wrong

`docs/plan/agent-prompts.md` is the template a coordinator copies into a launch prompt. Its **Working method** block said:

```
- Branch from `main`: `<type>/<description>`. Never commit to `main`.
- Push and open a **draft** pull request against `main` closing the issue.
```

That is the regime **10b replaced on 26/08/2026**, three phases earlier. All six definitions under `.claude/agents/` said the right thing, so an agent read two documents that contradicted each other — and the wrong one was the document written specifically to be copied.

**Nothing broke because of it.** Every launch prompt in phase 11b named the phase branch explicitly, so the template's error was overwritten by hand each time. That is luck, not a safeguard.

## What the template says now

- The worktree is named as an **absolute path that already exists**, on a branch the coordinator created from the phase branch. The agent creates neither — task 4's decision, and the reason is in the file: in 11b an agent given the `git worktree add` command did not run it and worked in the main checkout instead, on the phase branch, where two other agents were committing their memory. A step the coordinator has already taken cannot be skipped.
- Never commit on `main`, on `dev` or on the phase branch.
- The commit scope takes only `a-z 0-9 . _ -` and never a space, with the `commit-msg` hook named as what refuses the rest.
- The task records itself in `docs/plan/<phase>/status/<issue>-<slug>.md`, not in the shared `status.md`.
- `tools/pre-pr-check --base phase/<phase>-<description>` before opening anything, output pasted in, and a red check means no pull request.
- The pull request is a **draft against the phase branch**, and **the agent merges nothing**.
- Agent memory goes where `tools/agent-memory-path <name>` prints — the main checkout, not the worktree — with the subject `docs(memory): <what you learned>`.

## Verified

`grep -n "main" docs/plan/agent-prompts.md` returns seven lines, and **none instructs an agent to branch from or target `main`**: "the main session", "never commit on `main`", "the main checkout", and three in prose about other subjects.

## Open

Nothing. This was the last of the five documentation corrections; what remains in the phase is [#140](https://github.com/LuchoC-Dev/little-spaceship/issues/140), the CI check.
