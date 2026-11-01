---
name: art-production-needs-a-shell
description: Do not author pixel grids when build.py, check.js and a look at 1x are unavailable — cut to what can be settled by reading and say so
metadata:
  type: feedback
---

If the shell is unavailable, **do not bulk-author sprite grids anyway**. Cut to the work whose
correctness can be established by reading — palette rules, footprint arithmetic, structure and
tell design, document corrections — and report the blocker instead of shipping volume.

**Why:** the sprite loop is *add, regenerate, look at it at 1x next to the rest*, and the failure
this phase produces is a silhouette that reads alone and disappears in a crowd. That failure is
invisible in the source. Hand-assembling a 23-wide row is also measurably error-prone: it went
wrong twice in a row during the 21/08/2026 attempt, with no validator to catch it. A branch full of
unseen, unvalidated grids costs the next session more than an empty one.

**How to apply:** on an art task, check for `Bash` before planning scope. With a shell, run
`python docs/design/mockups/build.py && node docs/design/mockups/check.js` after every sprite. With
no shell, expect to deliver documents and at most one or two sprites as evidence for a specific
claim, and expect not to commit at all — `/git-commit`, push and `gh pr create` all need it.

Two things that reduce the risk when grids must be typed regardless:

- author wide symmetric sprites as **half rows through `sym()`** in `mockups/src/01-sprites.js`;
  half the characters to count and the mirror cannot drift;
- prefer **splitting a large sprite into its collider parts** over one wide image. The boss is five
  sprites for four reasons, and "47x87 is countable, 119x87 is not" is one of them.

Related: [[alien-ramp-has-one-chromatic-step]]
