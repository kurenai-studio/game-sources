# 154 — One rule for a commit subject, not two copies of it

**Found by `reviewer`, auditing the phase** · closes [#154](https://github.com/LuchoC-Dev/little-spaceship/issues/154) · branch `fix/one-subject-rule`

## The defect

`tools/hooks/commit-msg` exempted five subject shapes; `tools/pre-pr-check` exempted one. So `git revert`, which writes `Revert "<original subject>"` by itself, produced a commit the hook **welcomed** at write time and the gate **rejected**:

```
not a conventional subject: 020c06e Revert "fix(ci): repair pr-check.yml and check that workflows parse"
pre-pr-check: FAIL — 1 check(s) failed. Fix them; do not open the pull request.
```

Reproduced here on a scratch branch before fixing it, because a defect nobody has watched happen is a defect nobody has confirmed.

Nothing in the five documents an agent reads mentions this, and the failure message gives no hint the two checks disagree. An agent doing a legitimate revert — the **only** way to undo something here, since `CLAUDE.md` forbids rebasing and force-pushing — would hit a red gate it could not explain, and a red gate means no pull request.

## The fix: one source of truth

`tools/commit-subject-ok` takes a subject and exits 0 or 1, with the reason on stdout. Both callers ask it. **The lists cannot drift again because there is one list.**

That is the point, and it is worth being explicit: the bug was not that a list was wrong. Both lists were reasonable. The bug was that there were **two**, and a copied rule drifts — which is the same failure as [#150](https://github.com/LuchoC-Dev/little-spaceship/issues/150) at a different level, where a tool wrote a file nothing else read.

## The exemption set, decided rather than inherited

- **`Merge `** and **`Revert "`** — git's own wording in both cases. Reverting is the sanctioned way to undo in this repository, so an agent should not have to rewrite git's subject to be allowed to do it.
- **`fixup!` / `squash!`** — **removed**. They exist for interactive rebase, which `CLAUDE.md` forbids and this environment does not support, so exempting them only widened a hole nothing can legitimately come through. The hook used to accept them; it no longer does.
- **empty or `#`-prefixed** — an aborted commit, which never reaches history. It stays in `commit-msg` alone and is not in the shared rule at all, because it is the hook's business and no gate's.

## Verified by running it

| Subject | Shared rule | Hook, live |
|---|---|---|
| `Merge pull request #1 from x/y` | accepts | accepts |
| `Revert "fix(ci): something"` | accepts | accepts |
| `docs(memory): a thing` | accepts | accepts |
| `docs(core-domain memory): a thing` | rejects | rejects, naming `docs(memory):` |
| `fixup! docs: x` | rejects | rejects |

And the gate, against the real revert commit that failed before the fix: it passes now.

## The document that claimed the parity

`status/137-issue-contract.md` said the hook checks "against the same rule `tools/pre-pr-check` applies", listing all five exemptions. **False for four of them.** It was written by testing the hook and never the gate — the same shape phase 09 was caught by, and the reason this project has an evidence rule at all. Corrected in place, with a dated note rather than a silent edit.

## A sixth gap, found by trying to land this one

The fragment check counted **any** fragment the diff touched, so correcting `137-issue-contract.md` — which is part of closing this issue, since that document carries the false claim — registered as writing a second fragment:

```
FAIL 2 status fragments in one branch; a task writes exactly one
```

It now counts only **added** files (`--diff-filter=A`). Correcting an older fragment is not writing a new one, and the rule as written made it impossible to fix a past fragment and record the fix in the same branch.

Same family as the four before it, and the same cause: the author had never modified an existing fragment, so the check was written as if that never happens. It is fixed here rather than in its own issue because **#154 cannot be closed without it** — the correction it demands is the thing the check forbade.

## And then it happened again, in this pull request

`pre-pr-check` was taught to count only added fragments. **`pr-check.yml` was not**, so it failed this very pull request:

```
FAIL 2 status fragments; a task writes exactly one
```

One rule, two implementations, drifting — **inside the pull request whose entire subject is that one rule in two implementations drifts.** It is the plainest possible demonstration that the fix for #154 had to be a shared script rather than two lists kept in agreement by care.

So the fragment rule got the same treatment: `tools/status-fragments` prints the fragments a branch adds, and both `pre-pr-check` and `pr-check.yml` ask it. Two shared scripts now, `commit-subject-ok` and `status-fragments`, and the rule behind both: **if two things must agree, do not write it twice.**

## Open

[#155](https://github.com/LuchoC-Dev/little-spaceship/issues/155) is the other gap the same audit found: neither check verifies that a status fragment sits in the phase directory its base branch names, so one phase's work can be recorded in another's status. Same family — one rule, two implementations that must agree.
