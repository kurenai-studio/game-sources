# 138 — The coordinator creates the branch and the worktree

**Task 4** · closes [#138](https://github.com/LuchoC-Dev/little-spaceship/issues/138) · branch `docs/coordinator-owns-worktrees`

## What was done

`docs/plan/how-to-run-a-phase.md` now says, in the **Branch** step, that the coordinator creates the branch and the worktree from the phase branch before launching anything, that the launch prompt names an absolute working directory that already exists, and that **an agent never runs `git worktree add`**. The command lives there, once.

The **Parallel work** section, which used to tell the reader to create their own worktree, now points at that step instead and says the coordinator hands over a path.

## Why, in the evidence's own terms

In phase 11b an agent worked directly in the main checkout, on the phase branch, leaving six modified files there. Nothing detected it: it was caught because a *different* agent noticed the dirty checkout and reported it rather than touching it, which is luck wearing the costume of process.

The instruction to create a worktree existed **only in that agent's launch prompt**. None of the six definitions under `.claude/agents/` mentions worktrees as an obligation — they mention them only to say where agent memory must not go. So the rule the agent broke was not a project rule; it was one line in one prompt, written by the coordinator, and the coordinator was the one who could have simply run the command instead.

## The one thing that does not move into the worktree

Agent memory. `.claude/agent-memory/` is tracked, so a commit made from a worktree writes it onto that branch where the next agent will not find it, and the `pre-commit` hook refuses it. That is why those commits land on the phase branch, appear in no sub-branch's diff, and are seen by no sub-branch's `pre-pr-check` — the reason [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) added a `commit-msg` hook. The parallel-work section now says this in one place rather than leaving it to be rediscovered.

## Deliberately not done

**The `Agent` tool's own `isolation: "worktree"` mode.** It may do this natively. It is also unmeasured here: which branch it forks from, and how it interacts with agent memory having to live in the main checkout, are both unknown. Creating the worktree with git is deterministic and branches from exactly where this project needs. Measuring the alternative is worth its own issue; guessing inside this one is not.

## Open

`docs/plan/agent-prompts.md`'s template still tells an agent to branch for itself. That file is rewritten wholesale by [#139](https://github.com/LuchoC-Dev/little-spaceship/issues/139), the next task, which is where the template's working-directory line lands — splitting the edit across two branches would have put both tasks in the same file for no benefit.
