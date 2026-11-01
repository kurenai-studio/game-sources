# Every edit phase 10b made to `CLAUDE.md`, and what motivated it

`CLAUDE.md` is read by every agent on every phase. The phase plan allows this phase to change it
**with a written justification for each edit**; this file is that condition being met. One row per
edit, in the order they landed.

A rule that is not motivated by something that happened does not belong in this file, and does not
belong in `CLAUDE.md` either.

## 1 — The branch regime replaces "merge back into `main`" · issue [#65](https://github.com/LuchoC-Dev/little-spaceship/issues/65)

**What changed.** The Commits section's branch paragraph became a four-level table: `main` ← `dev` ←
`phase/<phase>-<description>` ← `type/description`, with "an agent opens a pull request and merges
nothing" stated explicitly.

**What motivated it.** A decision by the project owner on 26/08/2026. Phases 01–09 merged their
branches directly into `main`, so `main` was the trunk, the integration branch and the branch
`deploy-pages.yml` publishes from, all at once — a half-finished phase was one merge away from the
live site. The regime also fixes a second thing the phase-09 measurement showed: work reached `main`
in nine separate merges with no point at which the phase was reviewable as one thing.

**Why in `CLAUDE.md` rather than only in `docs/plan/how-to-run-a-phase.md`.** An agent is launched
with a plan and this file; the branch it creates is the first thing it does, before it has read
anything else. The operational detail stays in `how-to-run-a-phase.md`, which is linked from here.

## 2 — `tools/pre-pr-check` before every pull request · issue [#66](https://github.com/LuchoC-Dev/little-spaceship/issues/66)

**What changed.** Two sentences added to the Commits section: run the check, paste its output, a red
check means no pull request.

**What motivated it.** A decision by the project owner on 26/08/2026, and phase 09's evidence behind
it: a worker's report and its `status.md` both claimed CI had never run on a runner while four real
runs sat in the API, and a script committed from Windows without the executable bit killed the first
two of those runs. Both are things a command notices and a paragraph of instructions did not.

**Why in `CLAUDE.md`.** It is a gate on an action every agent takes. A gate nobody reads before
acting is not a gate.

## 3 — The documentation convention: name the file, or say "Not built"

**What changed.** The Conventions section gained the rule decided in phase 10a: a passage in `docs/`
that describes behaviour either names, in backticks, the file that implements it, or says "Not
built".

**What motivated it.** Phase 10a's audit: nine of its thirty-five findings were prescriptive text in
the same present tense as text that was true, with nothing to tell them apart, and eight more were
dangling names. `docs/plan/10a-honest-documentation/mechanism.md` adopted the convention and recorded
that putting it into `CLAUDE.md`'s Conventions section — where every agent actually meets it —
belonged to this phase.

## 4 — `test-engineer` has no memory directory · finding F32 of the 10a audit

**What changed.** "Defined in `.claude/agents/`, each with persistent memory under
`.claude/agent-memory/`" now says what is true: five of the six have one, and a directory appears the
first time an agent writes to it.

**What motivated it.** F32. Six agent definitions, five memory directories. The sentence was read as
a guarantee, and `level-designer` had a directory without its definition ever declaring
`memory: project` — the inverse mistake, and the reason the sentence was worth getting right rather
than deleting.

## 5 — Agent memory lives in the main checkout · issue [#61](https://github.com/LuchoC-Dev/little-spaceship/issues/61)

**What changed.** The "Where state lives" section gained a paragraph: memory is written in the main
checkout, `tools/agent-memory-path <agent>` prints it, and a `pre-commit` hook refuses the commit if
it lands anywhere else.

**What motivated it.** `.claude/agent-memory/` is tracked, so a worktree gets its own copy and an
agent writes into whichever checkout it is standing in. Phase 09 corrected this by hand three times
in one phase — and the measurement in `measurement.md` shows the coordinator spending live turns on
it, including one `SendMessage` correcting the previous one a minute later. An instruction had
already been tried; a path that resolves the same way from every worktree, and a hook in the shared
git directory, do not depend on anyone remembering.

## 6 — A claim about a system cites an observation of that system · issue [#62](https://github.com/LuchoC-Dev/little-spaceship/issues/62)

**What changed.** The Conventions section gained the evidence rule, with "not checked" named as an
always-acceptable answer and the phase 09 CI case named as what it prevents.

**What motivated it.** In phase 09 a worker wrote, in three places at once, that `ci.yml` "has never
been run on an actual GitHub Actions runner". Four runs had already completed — two red, two green —
and `gh run list` would have shown them. The instruction it was following, "say what you verified",
was obeyed to the letter and produced a false statement, which is what makes it insufficient rather
than ignored. The full case is in [`evidence.md`](evidence.md).

**Why in `CLAUDE.md` as well as in the six agent definitions.** Five of phase 09's eight subagents
never opened `CLAUDE.md`; three did. Neither location covers everyone on its own, and this is a rule
about the sentence being written at the moment it is written.

## 7 — Who merges a phase into `dev` · issue [#65](https://github.com/LuchoC-Dev/little-spaceship/issues/65)

**What changed.** The `dev` row of the branch table now says the merge is a coordinator's to make
**only with the project owner's direct approval**, and the paragraph under it says the approval is per
pull request rather than standing.

**What motivated it.** The regime as first written said who merges into `main` and who merges
sub-branches, and said nothing about the phase into `dev` — a gap this phase's own closing report had
to raise as an open question. The project owner answered it on 26/08/2026: coordinators and leads may
do it, with direct approval each time.

## 8 — `main` is the project owner's merge, and an authorisation does not transfer it

**What changed.** The `main` row of the branch table now says "merged by the project owner and by
nobody else — an authorisation does not transfer this", and the paragraph under it says that being
told to do it anyway is a reason to stop and confirm.

**What motivated it.** It happened. On 26/08/2026, hours after this phase wrote the rule, the project
owner said "you can merge to main" and the coordinator merged `dev` into `main` (PR #79) instead of
stopping on the contradiction between the instruction and the rule both had just agreed. The rule as
first written said who *does* the merge and never said that permission cannot move it, and the
coordinator took the gap.

The merge was left in place — the content was the same the owner had already approved for `dev` and
touches no game code, so reverting would move history without fixing anything. What was defective was
the process, and that is what changed. `main` now also requires an approving review on GitHub, which
does not make the merge impossible for an admin token but does make it a deliberate override rather
than a reflex.
