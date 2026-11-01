# 135 — One status file per task

**Task 1** · closes [#135](https://github.com/LuchoC-Dev/little-spaceship/issues/135) · branch `docs/status-fragments`

## What was done

`docs/plan/how-to-run-a-phase.md`'s **Status** step now tells whoever does a task to write `docs/plan/<phase>/status/<issue>-<slug>.md` on their branch, before review, instead of editing the phase's shared `status.md`. The phase `status.md` is named as the coordinator's, holding the `State:` line, the date and the narrative, written when the phase opens and when it closes.

**This file is the first one written under the convention it introduces.** There was no cleaner way to start: the plan's own risk section predicted this and asked that it be said in the commit rather than papered over.

## What it keeps, deliberately

The rewritten step keeps the reason the old one gave — the status *"travels with the code, and it lets the reviewer check whether the status tells the truth"*. That sentence is why the project owner rejected the coordinator's first proposal, which was to take `status.md` away from agents entirely and have the coordinator write it from their reports. The property is worth protecting; the shared file was never what protected it.

## What it fixes, in the words of the evidence

Both of phase 11b's failure modes came from one file:

- **The conflict.** An agent hit one in `docs/plan/11b-wave-system/status.md` after the coordinator merged a sibling pull request, and force-pushed to escape it — forbidden in as many words by its own definition. Two paths that are never the same path cannot conflict.
- **The silence.** #124 and #127 never touched that file, so the negative-offset defect and its fix were absent from the phase record until the coordinator wrote them in at close.

`reviewer` also observed that #118 and #119 auto-merged without markers *only because the two insertions landed at different offsets by the time the second merge ran*. That is luck, and luck does not survive a third parallel branch.

## Open

Nothing in this task. **Issue [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) makes the fragment mandatory** — until it lands, a branch that changes code and writes no fragment still passes `pre-pr-check`, exactly as #124 and #127 did.

## For whoever comes next

The fragment's name carries the issue number so a reader can reach the discussion behind the work — in this project decisions live in issue comments as often as in commits, and the carrier-children rule of phase 11b lives in a comment on #85 and nowhere else. `pre-pr-check` cannot check that name, because it runs before the pull request exists and cannot know which issue it will close; verifying the name against the issue is [#140](https://github.com/LuchoC-Dev/little-spaceship/issues/140)'s job.
