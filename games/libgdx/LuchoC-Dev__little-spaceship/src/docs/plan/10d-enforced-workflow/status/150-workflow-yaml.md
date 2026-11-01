# 150 — pr-check.yml was invalid YAML, and nothing checked

**Found while closing the phase** · closes [#150](https://github.com/LuchoC-Dev/little-spaceship/issues/150) · branch `fix/pr-check-yaml`

## What happened

[#149](https://github.com/LuchoC-Dev/little-spaceship/pull/149) shipped `.github/workflows/pr-check.yml` with a **literal newline inside a shell string**, in two `printf '%s\n'` calls. The workflow stopped parsing, so it stopped running — and this was three minutes after merging the change that was supposed to make the phase's own rules enforceable.

GitHub reported it, in the only way it can:

```
X fix/phase-branch-fragments  PR check  #149 · 33214992579
X This run likely failed because of a workflow file issue.
```

Zero seconds, and attributed to `push` — an event `pr-check.yml` does not trigger on. That combination is the signature of a workflow that fails to **parse**, not one that fails a check.

## Why it is worth an issue rather than a quiet fix

**A workflow that does not parse does not run, and its absence is silent.** GitHub reports a failed run, not a missing one, and only to whoever looks at the Actions tab. Every pull request merged in that window would have been unchecked, and nothing in the pull request itself would have said so — the check would simply not have appeared.

That is the exact failure shape this repository keeps paying for, and the reason `docs/STATUS.md` opens by warning that a phase saying something is done does not mean it is.

## The cause, named honestly

A scripted edit whose escaping collapsed one level too far: `\n` intended as two characters reached the file as one. The author was the coordinator, editing a file with a Python one-liner rather than by hand, and **nothing between that edit and GitHub looked at the result**.

## The fix, in two halves

- The two `printf` calls repaired. `python -c "yaml.safe_load(...)"` now parses the file, and all eight `printf '%s\n'` calls in it sit on one line each.
- **`tools/pre-pr-check` check 9: every workflow file in the diff must parse as YAML.** If `python3` with PyYAML is unavailable it says so — `pass workflow YAML not checked: python3 with PyYAML is not available here` — rather than passing silently, which would reintroduce the same class of lie at one remove.

## The pattern this closes the phase on

Four things in phase 10d broke on contact with reality:

| | What was wrong |
|---|---|
| [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) | the specification tied the rule to the wrong condition |
| [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) / [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132) | the specification named a hook that receives no message |
| [#148](https://github.com/LuchoC-Dev/little-spaceship/issues/148) | the specification assumed every branch is a sub-branch |
| this one | the specification was right; **the tool that wrote the file was wrong, and nothing checked it** |

The first three were caught by running the thing. So was this one — just later than the others, by GitHub rather than by the author, after a merge rather than before one. Check 9 moves it back before the commit.

## Open

Nothing. This is the last change of the phase.
