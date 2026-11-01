# The claim that cost a phase, and what stops the next one

Task 4 of [`plan.md`](plan.md), decided 26/08/2026.

## What happened

Phase 09, issue #34. A `game-presentation` worker wrote CI on GitHub Actions and then wrote this —
in its report to the coordinator, in `docs/plan/09-web-ci-release/status.md`, and in its own memory
file, three times over:

> "`.github/workflows/ci.yml` only proves the build compiles and `core`'s tests pass. It has never
> been run on an actual GitHub Actions runner — that only happens once the PR is opened."

The workflow triggers on `push`. By the time that sentence was committed the workflow had run **four
times on real runners** — twice red with `./gradlew: Permission denied`, twice green after the
`chmod` fix — and `gh run list` would have shown all four. The reviewer of PR #35 reconstructed the
timeline from commit timestamps and rejected the pull request on it.

The worker was not careless. Its brief said to say what it had verified, and it did: it verified the
YAML, and it reported honestly on what it had looked at. **The failure is that reasoning about a
file was allowed to occupy the place of an observation of the system**, and nothing in the process
could tell the two apart, because both arrive as confident English prose.

Two details make this worth a rule rather than a note:

- The claim was **negative** — "it has never run". A negative claim about a system is the one shape
  that feels safe to make without checking, because there is nothing to look at. It is also the one
  that a single command refutes.
- It landed in **three places at once**. The report is transient; `status.md` and the memory file are
  not. Phase 10a found the memory copy still uncorrected days later.

## The rule

> **A claim about a system cites an observation of that system.**
>
> Naming what a system does, does not do, cannot do, or has never done means naming the command that
> was run and what it printed — or the run id, the URL, the file and line. If there is no
> observation, the claim is written as **"not checked"**, which is always an acceptable answer and
> is never treated as a failure.

"Not checked" is the load-bearing half. An agent that cannot say it will invent a verdict instead,
and phase 09 is what that looks like. The phase 09 status file already does this well in other
places — "Did **not** attempt headless-Chrome verification", "No load-time or in-browser framerate
measurement was taken" — which is why the rule is a codification of the project's own better habit
rather than an import.

## Where it lives, and why in more than one place

| Where | What it says |
|---|---|
| `CLAUDE.md`, Conventions | the rule itself, in two sentences, with "not checked" named as acceptable |
| `docs/planning/13-working-with-agents.md` | the rule plus this case, so the reason survives the sentence |
| every definition in `.claude/agents/` | one line, because a subagent does not always read `CLAUDE.md` — five of phase 09's eight subagents never opened it |
| `tools/pre-pr-check` | the mechanical half, below |
| `reviewer`'s definition | a named thing to audit, since the reviewer is what actually caught it |

## The mechanical half

The check that runs before every pull request now reads the **added** lines of changed markdown and
lists the sentences shaped like an unobserved claim about a system: *never run*, *has not been run*,
*cannot be verified*, *unverifiable*, *no way to verify*, *impossible to*. It prints them as notes
with file and line, and asks for the observation or for "not checked".

**It does not fail the check**, deliberately. Every one of those phrases is legitimate when it is
true — `CLAUDE.md` itself says headless Chrome cannot validate the web runtime, and that sentence is
correct and expensive to have learned. A check that failed on it would be turned off within a phase.
What it does is make the claim visible at the moment it is cheapest to check, to the person who can
still run one command.

**Checked against the real case rather than assumed.** Running the detector's pipeline over
`git diff 4e11d87^..4e11d87 -- docs/plan/09-web-ci-release/status.md` — the commit that carried the
false sentence — prints:

```
ild compiles and `core`'s tests pass. It has never   been run on an actual GitHub Actions runner — that
```

It did not, at first: the sentence wraps across two lines, so a line-by-line grep missed it, which is
presumably how it survived being read several times. The check joins a file's added lines before
matching, and tolerates the run of spaces the join leaves behind.

Its noisiest case is this document: quoting the phase 09 sentence trips the detector six times over.
That is the argument for a note rather than a failure, made by the first branch that ran it.

## What this does not fix

A claim can cite an observation and still be wrong — the observation can be of the wrong thing, which
is pattern 6 in the reviewer's own memory ("a quoted measurement whose benchmark has a different data
shape than the code citing it"). This rule closes the case where there was no observation at all.
That is the case that has actually cost this project a phase, twice.
