---
name: github-pages-deploy-workflow
description: How to actually exercise a brand-new deploy-to-Pages workflow before it's merged to main, and what GitHub's own environment protection enforces independently of the workflow's own trigger
metadata:
  type: project
---

Built in phase 09 (issue #38, PR against `main`), worked from a dedicated worktree
(`little-spaceship-deploy`, branch `ci/pages-deploy`).

**`workflow_dispatch` cannot fire on a workflow file that only exists on a feature branch.**
GitHub only registers a workflow (and lets `gh workflow run` / the Actions UI dispatch it) once the
file is present on the default branch. `gh workflow run deploy-pages.yml --ref <branch>` on a
brand-new workflow returns `HTTP 404: workflow ... not found on the default branch` even though the
file is right there on the pushed branch. `gh workflow list --all` is the fast way to check whether
a workflow is registered yet — if it's missing, `workflow_dispatch` is not usable until merge.

**To get one real run before merging anyway**, temporarily widen the `push.branches` trigger to
include the working branch, push, let it run, then revert the widening in a follow-up commit before
opening the PR. This is legitimate — it is the only way to prove a *new* workflow's build steps
execute for real pre-merge — as long as the revert actually lands before the PR is opened, so the
merged history shows the intended trigger, not the temporary one.

**GitHub's `github-pages` environment enforces "main only" on its own, independent of the
workflow's `push.branches` filter.** Enabling Pages with `build_type: workflow` auto-creates an
environment named `github-pages` with `deployment_branch_policy.custom_branch_policies: true` and
exactly one allowed branch (the repo's default branch — `main` here, confirmed via
`gh api repos/.../environments/github-pages/deployment-branch-policies`). A `deploy-pages` job
attempted from any other branch fails with `Branch "X" is not allowed to deploy to github-pages due
to environment protection rules` — this is expected defence-in-depth, not a bug to route around.
Practical consequence: the `build` job (compile + `upload-pages-artifact`) can be verified from a
feature branch, but the `deploy` job genuinely cannot be exercised until the workflow runs on
`main` — there is no way to get a real deploy-job pass before merge, and that is fine; report the
build job's real success and the deploy job's expected protection-rule rejection separately rather
than treating the whole run as a failure.

**Verify a Pages artifact's real content by downloading it, not by reading the upload log.**
`gh api repos/.../actions/runs/<id>/artifacts` gives the artifact id and `size_in_bytes` (this is
the zip-of-a-tar the Pages upload action produces, not the raw dist folder size — don't quote it as
"the download size"). `gh api .../actions/artifacts/<id>/zip > artifact.zip`, `unzip`, then `tar -xf
artifact.tar` recovers the actual `webapp/` directory tree, which can then be checked file-by-file
(e.g. confirming `assets/startup-logo.png` really is in what got uploaded) and summed with `find
-printf '%s\n' | awk '{s+=$1} END{print s}'` for a real total-bytes figure — the same technique
`project_teavm-source-set-isolation-and-release-builds.md` already recommends over `du -sh`.
