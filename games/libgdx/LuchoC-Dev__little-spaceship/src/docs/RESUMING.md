# Picking this project back up

Written on 06/09/2026, when the project went into standby after phase 11k.

**Read this first, then `docs/STATUS.md`.** This file says what a returning reader needs that a status
document does not: what state the tree was left in, which of the open issues are real, what is
half-built on purpose, and which traps have already cost hours. `docs/STATUS.md` says where the work
stands; `CLAUDE.md` says how to work here; `docs/plan/how-to-run-a-phase.md` says how a phase runs.

## The state it was left in, verified on 06/09/2026

Every line below is a command that was run, not a recollection.

| | |
|---|---|
| `dev` at | `b213bed` |
| `./gradlew build` | green, all five modules |
| `node tools/build-level-docs.js` | `unchanged` for both documents |
| `git status --porcelain` | empty |
| `git worktree list` | only the main checkout |
| CI on `dev` | green — runs `34064869522` and `34065020721` |
| `core` tests | 370 |
| `game` tests | 50 |
| `dev` ahead of `main` by | 362 commits |

**`main` is three phases behind `dev`.** Everything from 11h onwards — the test mode, the path
vocabulary, absolute paths, and all of 11k — is on `dev` and not published. The live site at
<https://luchoc-dev.github.io/little-spaceship/> is built from `main`, so **it does not have any of
it**. A pull request from `dev` to `main` is open; merging it is the project owner's and nobody
else's.

## The first thing to know: most open issues are already done

**GitHub says 47 issues are open. About half are finished work.**

`Closes #N` only fires when a pull request merges into the **default branch**, and in this project
every working pull request targets its phase branch instead. The keyword sits in the pull request
body, not in a commit message, so **merging `dev` into `main` will not close them either.** They have
to be closed by hand, or they will sit there looking like a backlog forever.

**Already done, closeable on sight** — each was delivered and merged, and the phase status naming it
says so:

- From 11i: **#252**.
- From 11j: **#287, #291, #293, #296, #297, #301, #305**.
- From 11k: **#300, #310, #311, #314, #318, #320, #322, #324, #325, #328, #329, #330, #333, #334, #337**.

That is 23 of the 47. **Check one before trusting the list** — `gh issue view 310` and the pull
request it names — and then close them as a batch.

## What is genuinely open, ranked by what it would cost to be wrong

### Things that are half-built on purpose

Both were deliberate. Neither is broken, and both will look broken to someone who finds them cold.

- **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255) — a pickup content can place.**
  `core` can create a pickup with no enemy dying, scheduled on a wave's own clock, with tests. **The
  loader half was never built**, on the project owner's instruction, so `assets/data/` still cannot
  ask for one. Finishing it is one branch in `game/adapter/content/JsonContentSource.java`.
- **The single-file column.** A formation slot can carry a delay, and the follower traces the
  leader's path exactly — verified end to end, through the loader and a real engine run.
  **No content uses it.** The owner deferred the formation work to future levels after deciding
  level 1's gameplay was already right. It is a finished capability waiting for a level to want it.

### Real defects, none urgent

- **[#317](https://github.com/LuchoC-Dev/little-spaceship/issues/317)** — the `atX` check validates a
  formation's anchor, not each slot, so an absolute path on a multi-slot formation is unchecked. Two
  agents reached this limit independently from opposite directions. It bites the first time content
  pairs the two.
- **[#289](https://github.com/LuchoC-Dev/little-spaceship/issues/289)** — the playfield's size is
  written in five places across two modules, and `TICK_SECONDS` in the loader is now a sixth instance
  of the same pattern.
- **[#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280)** — a loop is always a path's
  tail, so "circle three times and then dive" is unsayable. No drawn shape has needed it across three
  phases of trying.
- **[#216](https://github.com/LuchoC-Dev/little-spaceship/issues/216)** — level 1 has no timer and
  nothing tells the player how far through a level they are.
- **[#218](https://github.com/LuchoC-Dev/little-spaceship/issues/218), [#219](https://github.com/LuchoC-Dev/little-spaceship/issues/219),
  [#225](https://github.com/LuchoC-Dev/little-spaceship/issues/225)** — audio glitching under
  sustained fire, a 2.5 MB web download of which 1.3 MB is two uncompressed WAVs, and a denied
  pointer lock leaving the player stuck. All three are things a stranger meets in a browser, and
  **`main` does not have them fixed because `main` does not have anything since 11g.**
- **[#223](https://github.com/LuchoC-Dev/little-spaceship/issues/223)** — `pre-pr-check` treats
  `CLAUDE.md` as code, so a coordinator documentation pull request that edits it cannot pass. Worked
  around every time so far.

### Documentation and test debt

**[#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56)** (fail the build when a document
names code that does not exist), **[#208](https://github.com/LuchoC-Dev/little-spaceship/issues/208)**
(nothing fails when `shape-catalogue.md` names a wave that no longer exists),
**[#205](https://github.com/LuchoC-Dev/little-spaceship/issues/205)**,
**[#206](https://github.com/LuchoC-Dev/little-spaceship/issues/206)**,
**[#238](https://github.com/LuchoC-Dev/little-spaceship/issues/238)**,
**[#128](https://github.com/LuchoC-Dev/little-spaceship/issues/128)**,
**[#129](https://github.com/LuchoC-Dev/little-spaceship/issues/129)**,
**[#117](https://github.com/LuchoC-Dev/little-spaceship/issues/117)**,
**[#123](https://github.com/LuchoC-Dev/little-spaceship/issues/123)**,
**[#108](https://github.com/LuchoC-Dev/little-spaceship/issues/108)**,
**[#104](https://github.com/LuchoC-Dev/little-spaceship/issues/104)**,
**[#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44)**,
**[#12](https://github.com/LuchoC-Dev/little-spaceship/issues/12)**,
**[#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19)**,
**[#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88)** (`BossSystem` is level 1's boss,
not a boss engine — reaffirmed as out of scope twice in 11k), and
**`JsonBalanceValues`'s other twenty fields**, unverified against a parsed fixture since 11i.

### Two open questions nobody has answered

- **Whether `tools/pre-pr-check` should run `node tools/build-level-docs.js`.** Carried since 11i,
  where four consecutive CI runs went red on exactly this gap. It did not bite in 11k only because
  every content task regenerated by hand.
- **Whether anything should test a property across the `core`/`game` seam routinely.** See the
  next section — this is the most valuable open question in the repository.

## What phase 11k learned, and why it matters more than what it built

**Five times in one phase the code was right and the prose was wrong, and no automated check found
any of them.** A javadoc naming a guard that never fires; five removal times short by exactly one
collider radius; an `atX` window rounded the wrong way; the boss's cycle order documented backwards
by generalising the first cycle onto every cycle; a loader javadoc explaining a crossing mechanism
that had just been deleted.

Every one was found the same way: **someone re-derived the numbers instead of reading them** — from
the JSON, with a reflection probe against the compiled classes, or by integrating by hand. The
instruction that makes it possible was introduced in 11j and kept in 11k: **a task that authors
content must write down what it should look like, with the numbers derived from the real files.** It
has now produced a finding in three consecutive phases. Keep it.

**Once, a test asserted nothing.** It bounded a delta from one side — `deltaSeconds > MOVE_DURATION`
— while the failure it claimed to catch makes the delta *larger*. It passed in both worlds. A
one-sided bound is not an assertion when the bug moves the value the allowed way.

**And one defect hid between two well-tested modules.**
[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337): a delayed formation slot activated
one tick early, because `MotionSystem` reached its crossing by repeated addition of `1f/60f` while
the delay itself was formed by a single multiplication, and those do not agree in float. `core`'s
test measured N = 1 and N = 12 — **both outside the failing bands, by luck.** The loader's tests
stopped at parsing. The guarantee the feature exists for is an end-to-end one and nothing crossed the
seam. It is fixed, with an integer countdown and a sweep of 1..300, but **the class of gap is not
closed**: that end-to-end test exists because a defect forced it, and it is still the only one.

## Traps that have already cost hours

Most are in `CLAUDE.md` and this file does not repeat them. These three are the ones a returning
reader is most likely to hit first:

- **The generated documents are generated.** `docs/levels/level-01.md` and `docs/levels/waves.md` come
  from `assets/data/` through `tools/build-level-docs.js`, and CI regenerates and fails on a diff.
  Never edit them by hand. **After any content change, run the generator and commit its output** —
  `pre-pr-check` does not run it and neither does `./gradlew build`, and phase 11i sat red for four
  consecutive runs on exactly that.
- **An issue's `Closes` does not fire from a phase branch.** See the first section. It is why the
  issue list lies.
- **Agent memory lives in the main checkout, never in a worktree.** `tools/agent-memory-path <agent>`
  prints the one correct directory. A `pre-commit` hook refuses the commit if you forget; install the
  hooks once per clone with `tools/install-hooks`.

## Where the decisions are, so they are not reinvented

- **Game rules that are settled versus still open** — `docs/planning/08-decisions-and-open-items.md`.
  Read it before inventing a rule; most of them are already decided.
- **What each enemy archetype is for** — `docs/planning/02-mvp-functional-spec.md:183-189`. It is what
  phase 11k's vocabulary was derived from, and it settles arguments about what a ship should do.
- **Level 1's beats** — `docs/planning/04-campaign-and-levels.md`, "Level 1 design". Provisional by
  its own words.
- **Which beat each wave carries** — `docs/plan/11c-movement-shapes/shape-catalogue.md`, "What points
  at what". **This is the only hand-written link in a chain that is otherwise generated and
  CI-checked**, it has needed a dated correction twice, and
  [#208](https://github.com/LuchoC-Dev/little-spaceship/issues/208) exists because nothing fails when
  it goes stale.
- **Why a movement shape is shaped the way it is** — each phase's `status/` fragments, especially
  `docs/plan/11k-level-one-rebuilt/status/320-level-one-vocabulary.md`, which describes every
  trajectory in the game and the `atX` window it needs.

## What comes next, if anything

**Phase 12 — levels 2 and 3.** The roadmap calls it the first honest measurement of whether the 11
group made level-building cheap. It is not planned. It inherits a vocabulary written per archetype, a
single-file column nothing uses yet, a placeable pickup missing its loader, and a generated document
that can now read everything the content can say.

**Before that, two things are worth doing whatever happens next**: close the 23 finished issues, and
merge `dev` into `main` so the live site stops being three phases old.
