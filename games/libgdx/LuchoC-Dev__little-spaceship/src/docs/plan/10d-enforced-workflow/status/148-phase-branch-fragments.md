# 148 — The fragment rules rejected a phase branch

**Found while closing the phase** · closes [#148](https://github.com/LuchoC-Dev/little-spaceship/issues/148) · branch `fix/phase-branch-fragments`

## How it was found

By running `tools/pre-pr-check --base dev` on `phase/10d-enforced-workflow` — the phase that introduced the rules — before opening its own pull request:

```
FAIL 6 status fragments in one branch; a task writes exactly one
```

The phase could not open its own pull request. Worse, `pr-check` would have rejected it too: a phase branch against `dev` closes no issue of its own and changes files outside `docs/`, so its issue assertion failed as well. **No phase pull request could have been opened at all** once these rules were on `dev`.

## The defect

Both checks were written from the point of view of a **sub-branch doing one task** — the common case, and not the only one. A phase branch aggregates a whole phase: it carries one fragment per task, and closes none of its tasks' issues itself, because each is closed as its sub-branch merges.

## The fix

`phase/*` is a **named category**, exactly like the coordinator's documentation branches — not a flag anyone can pass, which is the failure mode `docs/plan/10d-enforced-workflow/plan.md` names in its risks:

> A check that fails a legitimate pull request costs more than the rule buys, and the first instinct will be to add an escape hatch — which is how a check becomes decorative. Any exemption must be a named category […] not a flag anyone can pass.

- `tools/pre-pr-check` — for `phase/*`, **at least one** fragment; for anything else, exactly one. The two arms are now separate branches of a `case`, after a first attempt that set a counter and fell through into the sub-branch arm, reporting `pass 6 status fragment(s)` and `FAIL 1 status fragments` in the same run.
- `.github/workflows/pr-check.yml` — a `phase/*` head skips the one-issue rule and the fragment-name rule, and requires at least one fragment instead.

Both had to change, and they must keep agreeing: a rule stated twice in two languages is a rule that can drift, and a branch that passes one and fails the other is worse than one that fails both.

## The pattern this makes three of

Three of this phase's rules changed shape when they met reality, and every time the **specification** was wrong rather than the work:

- [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) tied the fragment rule to the Gradle-build condition, which would have exempted four of this phase's own tasks.
- [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) and [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132) asked for a subject check in `pre-commit`, a hook that receives no message.
- This one assumed every branch is a sub-branch.

The common cause is worth naming for whoever writes the next set of rules: **each was written from inside the case the author had just lived through.** What caught all three was running the thing, on itself, before trusting it.

## Open

Nothing. This was the last change of the phase.
