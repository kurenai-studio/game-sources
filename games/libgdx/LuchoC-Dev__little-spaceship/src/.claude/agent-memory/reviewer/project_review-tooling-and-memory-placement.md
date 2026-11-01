---
name: review-tooling-and-memory-placement
description: gh CLI scope failures on this token, and why reviewer memory written on a feature branch diverges from main
metadata:
  type: project
---

Operational traps around delivering a review on this repository. Neither is visible from the code.

**Why:** the verdict has to land as a comment on the pull request so it lives in the repository, and the reviewer's own memory has to land in the worktree being audited. Both steps have failed here for reasons that look like bugs and are not.

**How to apply:**

- **`gh pr view --comments` and `gh pr edit` fail with GraphQL scope errors on the token in use.** They are not usable for reading a prior review or amending a PR body. The REST endpoints work: `gh api repos/:owner/:repo/issues/<n>/comments --jq '.[] | .body'` to read the review thread, `gh api repos/:owner/:repo/pulls/<n> --jq '.body'` to read the description, and `-X PATCH` to change one. `gh pr comment <n> --body-file <path>` works normally — that is the one to post the verdict with, writing the body into the scratchpad first.
- **`gh pr view --json <fields> --jq` works** for plain metadata (title, headRefName, baseRefName); it is only the comment/review fields that trip the scope error.
- **Heredocs with backticks can fail through the Bash tool even when quoted (`<<'EOF'`).** Writing a long markdown body failed with "unexpected EOF while looking for matching quote". Use the Write tool for the file, then `--body-file`. Faster than debugging the quoting.
- ~~**Reviewer memory on `main` is usually ahead of the copy on a feature branch.** … memory belongs in the worktree being audited … write the *superset*.~~ **Reversed on 26/08/2026 by phase 10b, issue #61.** This advice was the memory-path trap written down as guidance, and following it is what produced three hand corrections in phase 09 and a divergent copy on every phase branch. Memory now has exactly one home: run `tools/agent-memory-path reviewer`, which prints the main checkout's directory from any worktree, and write there. The `pre-commit` hook refuses a commit that stages `.claude/agent-memory/` from a linked worktree, so the old habit now fails loudly instead of quietly. The superset dance is no longer needed: there is only one revision.
- **Commit the memory file with subject `docs(memory): <what was learned>`, in `tools/agent-memory-path reviewer`'s directory, and nowhere else.** Leaving it uncommitted was tried and explicitly corrected on PR #171's review: the instruction is now to commit every time, not to leave it for the parent to decide. The reviewer still never merges anything and never commits outside this one directory.
- **A concurrent reviewer session editing the same memory file in the one shared main checkout can absorb your uncommitted edit into their own commit, under their own message.** Caught auditing PR #319: `Edit` wrote a PR #319 finding to `project_defect-patterns.md`, and by the time this session reached `git add`, the file had already been committed — whole, including the PR #319 addition — by a parallel session's `docs(memory): record PR #313's...` commit (confirmed with `git show HEAD -- <file>`: both additions are in that one diff). Nothing was lost and nothing needs re-doing — the content is on the branch — but `git status --short` coming back clean where a fresh, uncommitted edit was expected is the tell, not a sign the edit failed. Before assuming an edit needs committing, `git show HEAD -- <path>` and check whether your own text is already there; if it is, there is nothing to commit and attempting one would be an empty/duplicate commit. This is a consequence of "memory lives in exactly one home" (the point above) now colliding with several sessions auditing different PRs at the same time, all writing that one file with no lock between them — worth a heads-up to whoever coordinates parallel reviewer sessions, since the commit message attribution silently misattributes the note's origin.

Related: [[defect-patterns]], [[audit-techniques]].
