# What keeps documents honest

Task 5 of [`plan.md`](plan.md), decided 26/08/2026.

Correcting the 35 findings in [`audit.md`](audit.md) without changing what produced them buys a few
months. This is the part that is supposed to last.

## What actually failed

Not "documents drift". That is too general to build against. Sorting the 35 findings by *shape* gives
four classes, and they need different answers.

| Class | What it is | Findings | Share |
|---|---|---|---|
| **A — a dangling name** | the document names a class, method, file or path that does not exist | F4, F10, F20, F21, F22, F23, F24, F25 | 8 |
| **B — a stale number** | the document names a value that changed | F1, F2, F17, F33, F34 | 5 |
| **C — a state that moved on** | a status, an open item or a caveat the project has since closed | F13, F15, F16, F18, F19, F29, F30, F31, F35 | 9 |
| **D — a rule stated as built** | prescriptive text in the present tense, indistinguishable from description | F3, F5, F6, F7, F8, F9, F11, F12, F14 | 9 |

Two things fall out of that table immediately.

**Class A is mechanical.** Every one of those eight is a *name* — `skin.load(...)`, `InputSystem`,
`Lifetime`, `patterns.json`, `Composition.java`, `game/screens/`, `core/src/test/resources/replays/`,
`WorldView.boss()`. A machine can look each one up. They are also the expensive ones: five of the six
findings in `12-architecture.md`, the document a new agent reads to learn the shape of the code, and
`07-skin.md`'s `skin.load(...)`, which is the single reference that cost this project a phase.

**Class C is not a documentation problem at all.** It is a process gap, and the audit found it
exactly: `how-to-run-a-phase.md` said to update `docs/STATUS.md` after a merge and never said to close
the phase's own `status.md`, so the last write to the status file happened *before* the merge. Four of
nine status files had drifted. No checker fixes that; a missing step in the cycle does.

## The mechanism

**One check, one convention, one step in the cycle.** They are not three ideas — the convention is
what gives the check teeth, and the step covers the class neither of them can see.

### 1. `docs-refs` — a check that fails on a dangling reference

A script over `docs/**/*.md` (excluding `docs/sources/`) that takes every backticked span and every
line inside a fenced block, extracts anything shaped like a repository reference —

- a path (`assets/data/patterns.json`, `game/screens/`, `core/src/test/resources/replays/`)
- a Java type (`InputSystem`, `Lifetime`, `BossSystem`)
- a member (`WorldView.boss()`, `Simulation.world()`)

— resolves it against the repository, and **fails, naming the file and line, on anything it cannot
find.** An allow-list file absorbs the false positives: prose words that look like types, libGDX and
JDK names, and deliberate references to things that do not exist (`07-skin.md` now names
`skin.load(...)` precisely in order to say the game does not call it).

**Run in CI, on every push, next to the tests.** This is the one piece that must not depend on anyone
remembering, and it is cheap: it reads text files.

**What it would have caught, of today's 35:** all eight of class A. Also F1 and F2 partially — the
boss table would still have said `-18`, but `core-keel` appearing in `BossSystem` and in no document
is the kind of asymmetry a later extension could report.

**What it will never catch:** class B. `patternCooldown 1.3` against a file that says `0.7`, `236
tests` against 289, `three formations` against eight. A number is not a name and there is nothing to
resolve. This is the mechanism's honest limit, and the convention below is what shortens the distance
to the real value rather than closing it.

### 2. The convention: name the file, or say "Not built"

**A passage in `docs/` that describes behaviour either names, in backticks, the file that implements
it — or says "Not built".**

Three words, and it does three things:

- it turns class D from invisible into visible. Every one of those nine findings was prescriptive
  text in the same present tense as text that was true, with no way for a reader to tell them apart.
  `05-legibility-rules.md`'s R11 and R13 sat among thirteen rules that *are* enforced;
- it converts future class A into a dangling reference the check can see. A paragraph that names
  `HudRenderer` breaks loudly when `HudRenderer` moves; a paragraph that describes the HUD in prose
  rots silently;
- it shortens class B. The reader who wants the real `patternCooldown` is one named file away from
  it, instead of guessing which of `balance.json` and `level-01.json` holds it.

It costs a backtick per paragraph, and `04-hud-layout.md` and `HudRenderer` already show what it looks
like when it is done: that pair is the most accurate document/code relationship in the repository, and
it is the pair where each side quotes the other by name.

### 3. Close the status file at the merge, not before

**Already landed**, in `how-to-run-a-phase.md`, as part of task 1. After a merge, two writes and both
of them or neither: the phase's `status.md` `State:` line, and the table in `docs/STATUS.md`. Then
read back over the status file and strike out anything in the future tense the merge has answered.

That is the whole of class C — nine findings, including phase 09's file telling its reader the play
link was a 404 three weeks after it went live.

## Why not the alternatives

The plan named four options. Two of them are above. These are the two that were not taken, and one
that was not on the list.

**Generate one side from the other.** The right answer where it applies, and it does not apply here:
a design document is an argument, and you cannot generate "the near layer is the plainest and it is
the darkest, and that inverts the instinct" from anything. Where it *does* apply is the per-level
document phase 11 has to build, and `post-mvp-roadmap.md` already says so in as many words — a
document describing the level and a JSON defining it are two copies of one truth, and generating one
from the other is the only option that cannot drift. That decision belongs to phase 11 and this does
not pre-empt it.

**The reviewer's checklist gains a step.** Rejected as *the* mechanism, kept as the backstop. Two
arguments against it. First, the reviewer is the most expensive instrument in the project — the cost
audit in `13-working-with-agents.md` is about little else — and spending it on something a text scan
does is the wrong trade. Second, it does not cover the case: the 10 group runs with **no reviewer
pass**, by the project owner's decision, and one of phase 09's two rejected false claims was written
by the coordinator. A mechanism that is absent from the phases most likely to need it is not a
mechanism.

That said, the reviewer *did* catch both of phase 09's, which is more than any script would have. It
stays as the backstop it already is; it is not asked to be the floor.

**A doc-comment convention pointing the other way** — code naming the document, rather than documents
naming code — was considered and is already the practice in the best-documented classes here
(`HudRenderer`, `BossSystem` and `WorldRenderer` all cite the design document by filename). It is
worth keeping and it is not the mechanism, because it protects the code from drifting away from the
document and the failures went the other way: the document drifted away from the code, four times out
of five.

## The test this had to pass

> Whatever is chosen has to survive being used by a tired agent at the end of a long phase. Something
> nobody runs is worth less than a convention people actually follow.

- **The check** does not need the agent at all. It runs in CI and fails the build.
- **The convention** is one backtick, applied while writing the sentence, not a step remembered
  afterwards — and the check punishes forgetting it in exactly the way that teaches it.
- **The step** sits inside a cycle that is already followed seven times per phase, immediately after
  a write that was already being done.

Nothing here asks anyone to re-read `docs/` looking for lies. That is what this phase was for, and
doing it again is the outcome the mechanism exists to prevent.

## Handover

`docs-refs` is a script, and the 10 group does not change production code.
[#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) hands it to the 11 group, with the
audit's class A findings as its acceptance test: **the check, pointed at this repository as it stood
on 26/08/2026, must have failed on all eight.**

The convention is adopted now — it is a documentation convention, and this phase edits documentation.
It is written into `how-to-run-a-phase.md`. Putting it into `CLAUDE.md`'s "Conventions" section, where
every agent reads it, belongs to **10b**, which owns that file.
