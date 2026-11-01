---
name: amend-targets-head-not-the-commit-you-mean
description: git commit --amend always rewrites HEAD; fixing an earlier commit's subject needs the commit checked out first, not just "the one I just wrote"
metadata:
  type: project
---

`git commit --amend -m "..."` rewrites whatever commit is currently `HEAD`, not "the commit whose
message was wrong". Made two commits (code, then a docs one), `pre-pr-check` flagged the *first*
commit's subject as too long, and running `git commit --amend` at that point amended the *second*
(docs) commit instead — HEAD had moved on. The fix that actually worked: `git reset --hard` to the
commit needing the new message, `git commit --amend` there, then `git cherry-pick` the commit(s) that
came after it back on top.

**Why:** `GIT_SEQUENCE_EDITOR="sed -i '1s/pick/reword/'" git rebase -i <base>` does not work
non-interactively either — `reword` still needs an editor to supply the new text, and without one it
silently keeps the old message. Don't reach for scripted `reword` as a shortcut.

**How to apply:** when `pre-pr-check` (or any check) flags a commit that isn't the tip, check that
commit out directly (`git reset --hard <that-commit>`, amend, then cherry-pick whatever came after)
rather than trying to `--amend` or script a `reword` from the current HEAD.
