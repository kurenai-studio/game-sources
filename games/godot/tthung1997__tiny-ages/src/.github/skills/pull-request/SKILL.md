---
name: pull-request
description: The Tiny Ages way to open and land a pull request, including the release check. Use whenever asked to create, open, update or merge a PR ("create PR and merge"), or to commit and push work for review. Covers the branch, the check, the commit identity, the PR text, the release suggestion to give the user, and the squash merge.
---

# Pull requests in Tiny Ages

`main` is protected: no direct pushes, no force-pushes, and every change goes through a pull request.
The user's usual instruction is "create PR and merge"; work is only pushed or merged when they say so.

## Before the PR

1. **Branch from an up-to-date `main`.** One topic per branch.
2. **Validate.** `pwsh -File game/tools/check.ps1` for any change to code, content or scripts (about 4
   minutes). Docs-only changes need nothing. A clean check proves the game parses and the tests pass,
   not that it feels right: say what to look at, and never claim a timing, window or visual change is
   right (`copilot-instructions.md`).
3. **Commit with the right identity.** The email must be the GitHub noreply address
   (`19512458+tthung1997@users.noreply.github.com`); check `git config user.email` in a fresh clone.
   End the message with the `Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`
   trailer and the `Copilot-Session:` trailer when the session gives one.

## Open the PR

- Title in the imperative, without a trailing full stop. The body says what changed and why, what was
  verified (check result, what was and wasn't looked at), and anything the user must check by eye.
- A decision or rule worth keeping goes into `docs/` in the same PR, and a plan that changes goes into its
  GitHub issue (issues are the backlog; `docs/` holds what is decided).
- The **Release** workflow runs on the PR as a dry run (tests and a build). Wait for it if you are about to
  merge.

## Give the user a release suggestion

Every time a PR is opened or merged, run `pwsh -File game/tools/release_check.ps1` (on a fresh `git fetch
--tags`) and tell the user its verdict **in one line**: *Not yet*, *Good time for a release*
or *Release a patch soon*, with the number of player-facing changes since the last tag.

The script only counts files that ship and looks for fix words in titles, so add your own judgment on top
of it, briefly:

- Does the PR complete a plan in the backlog, or finish a theme (for example the gear icon plus the villager
  list)? That is a better reason to release than a count.
- Is `main` in a state the user would want people to download (nothing half-built, the check green)?
- Did anything in the saved world change (`game/scripts/sim/state/`)? Saves have no migration, so say so.
- Would players of the last release be surprised by the changes? A PR that only changes content is a
  smaller reason than one that changes how the game looks or plays.

If a release looks due, offer it; do not tag or publish without being asked. The steps are in the
`release` skill.

## Merge

When asked to merge: `gh pr merge <n> --squash --delete-branch`, then switch to `main`, pull, and make a
fresh branch for the next piece of work. Squash keeps one commit per PR on `main`, which is also what the
release check counts and the generated release notes list.
