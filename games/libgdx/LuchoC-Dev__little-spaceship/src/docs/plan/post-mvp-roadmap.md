# Post-MVP roadmap

Written on 25/08/2026, the day the MVP shipped, from the player's direction after playing the
deployed build, and expanded the same day.

Phases 01–09 are done. They were planned as a numbered sequence, and everything past them sat in that
plan as a single lump called post-MVP. This document breaks that lump into **four groups of work**, in
order.

**Each group here becomes several numbered phases when it is picked up** — 11a, 11b, 11c and so on —
each with its own folder under `docs/plan/`, its own `plan.md` with acceptance criteria and its own
`status.md`, exactly as 01–09 had. So a group being large is not a problem to solve here: that is what
the subdivision is for. What matters at this level is **what belongs to which group, and in what
order**, because the order is what cannot be fixed later.

Nothing here is scheduled.

Read `docs/STATUS.md` first for where the project actually stands.

## Scope: stage 1 only

`docs/planning/04-campaign-and-levels.md` defines a campaign of **five stages**, each aiming for 3–5
levels — an indicative 15–25 levels — plus a possible second campaign that is explicitly out of scope.

**Everything in this roadmap is stage 1, "Invasion of Earth".** Levels 2 through 5 are that stage's
levels; the story completed in phase 13 is that stage's story. Stages 2–5 already have their narrative
function, setting and escalation sketched in that document and are not touched here.

The reason for that concentration is the point of the whole plan: build the system on one stage, and
the later stages become far cheaper — see "How later levels get built" at the end.

## Where this came from

The MVP is live and playable. Playing it produced four defects and a longer list of things that are
not defects but decisions the MVP deferred. Rather than fixing them one at a time, the player asked
for the remaining work to be split into four phases, with the reordering done **first** so that
everything after it is built on a base that holds.

That ordering is the point. It is cheaper to fix the process and the foundations now, with one level
in the repository, than after five.

## What playing the web build found

| Issue | What |
|---|---|
| [#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40) | QUIT does nothing on the web target |
| [#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41) | Losing pointer lock breaks mouse control until the page is refocused |
| [#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) | No in-game options: volume cannot be changed while playing |
| [#43](https://github.com/LuchoC-Dev/little-spaceship/issues/43) | The shield and the attachment are invisible — no sprite, no animation |

All four are assigned to **phase 11**, by the player's decision: they are code work and they travel
with the code reordering rather than being handled separately.

**#41 is worth singling out.** Phase 09's task 4 was "verify pointer capture", it was never actually
verified, and the defect it would have caught is the one the player hit. Everything else about that
phase was checked against reality; that one criterion was assumed, and assuming it was wrong.

Other than these, the player's verdict on the web build was that it works.

---

## Phase 10 — Reordering the development system

**Not code.** This group is about how the project is built: agents, documentation, and whether the
architecture needs to change. **No phase in this group changes production code** — it decides, and the
11 group executes.

It is now split into three planned phases, in this order:

| # | Phase | Why it sits there |
|---|---|---|
| [10a](10a-honest-documentation/plan.md) | Honest documentation | Everything else in the group reads documentation to do its work |
| [10b](10b-agents-and-sessions/plan.md) | Agents and sessions | Reviewing agent definitions against stale documents is work done twice |
| [10c](10c-architecture-review/plan.md) | Architecture review | Needs both: trustworthy documents, and the agents that will act on the outcome |

The sections below are what those three plans were written from.

**How the group is run**, decided on 25/08: a **fresh coordinator session** owns all three — none of the
six agents owns `docs/` or the working system, and 10b auditing agent definitions is awkward work to
hand to an agent. **No `reviewer` pass**, on the grounds that the group changes documents rather than
code. 10b may change `CLAUDE.md`, with a written justification for each edit. The git and worktree
workflow is explicitly out of scope.

### Agents and the way sessions are run

`docs/planning/13-working-with-agents.md` records the audit that produced the current regime: ~3,300
model calls, 665 million cached input tokens, and **fourteen spend limits across nine contexts**, two
thirds of it re-reading conversation history rather than doing new work.

That regime — one coordinator per phase, `reviewer` on Sonnet, one issue per worker, any limit stops
the flow — was followed in phase 09 and held. This phase checks it against phase 09's real numbers
and tightens what did not work. Also in scope: the six agent definitions, their prompts, and their
memory files, which have accumulated across nine phases without a pass.

Two process defects phase 09 surfaced that belong here rather than to any one agent:

- **A worker reported CI as unverifiable while four real runs sat in the API.** The workflow triggers
  on push; it had already run twice red and twice green. Reasoning about a YAML file was submitted in
  place of evidence that was one command away.
- **Agent memory keeps being written into the main working copy.** `.claude/agent-memory/` is a
  tracked path, so an agent working from a worktree writes to whichever checkout it happens to be in.
  This had to be corrected by hand three times in one phase. It is structural, not carelessness.

### Documentation

`docs/` has drifted from the code, and the drift causes real damage rather than just being untidy:

- `docs/design/07-skin.md` still describes a reflective Skin integration the code does not use. That
  stale document is what put a false warning into `docs/STATUS.md` for a future phase to trip over,
  and it took a reviewer reading `GameSkin` to establish it was never true.
- Phase 09 caught two more of the same shape: a `status.md` claiming CI had never run, and a licence
  claim corrected in the README but left false in the status file.
- Three times in one day, art a phase called delivered existed only under `docs/design/` with nothing
  in `assets/`.

The reviewer's memory now catalogues this as a recurring pattern with several variants, which makes it
a process defect rather than bad luck. This phase audits `docs/` against the code and decides what
keeps documents honest going forward.

### Architecture

**A discussion, not a rewrite.** Whether the current architecture holds for four more levels, the
wave system and the movement system — and if not, what changes. The eight open technical issues from
earlier phases (#3, #4, #5, #11, #12, #17, #19, #23) are the concrete input.

The invariants in `CLAUDE.md` are the thing to argue *against* if anything is to change: they were
measured, and breaking one invalidates earlier work.

### Risk

**This group's scope is the thing most likely to go wrong.** "Reordering" attracts every complaint
anyone has. Each of the three plans carries an explicit "What is out of scope" section for that
reason.

---

## Phase 11 — Reordering the code

The goal is a base the `level-designer` agent can build levels on **easily**, which today it cannot.

**Split into six planned phases on 27/08/2026**, after a planning conversation with the project owner
that closed every question this section leaves open. The answers are recorded in
`docs/planning/08-decisions-and-open-items.md`, "The 11 group, 27/08/2026", and each plan repeats the
ones it needs rather than restating this section:

| # | Phase | Why it sits there |
|---|---|---|
| [11a](11a-rule-asserting-tests/plan.md) | Tests that assert rules | Everything after it is a behaviour change; this is the net |
| [11b](11b-wave-system/plan.md) | The wave system | The unit of level design, and what balance and movement are expressed inside |
| [11c](11c-movement-shapes/plan.md) | Movement as a described thing | The one real gap 10c found; needs waves to place a shape in |
| [11d](11d-per-level-document/plan.md) | The per-level document | The format is settled once waves and shapes exist |
| [11e](11e-level-one-redesigned/plan.md) | Level 1 redesigned, balance and the boss | Needs all four, and it is where playing decides |
| [11f](11f-web-defects/plan.md) | The four web defects | Touches only `game`/`desktop`/`web`; runs in parallel from day one |

### Waves, first — everything else depends on it

Today `level-01.json` is **92 spawn events**, each an absolute time, an archetype, a formation and an
x position. It is a transcript, not a design.

**The design it is a transcript of already exists.** `docs/planning/04-campaign-and-levels.md`, under
"Level 1 design → Provisional sequence", lists level 1 as **fourteen** beats:

> audiovisual introduction · initial calm · first isolated basics · light/fast · combined formations ·
> tanks and shifts in priority · super-fast · one or two heavy carriers · evolved basics/shooters ·
> high-pressure combinations · **a difficult encounter that delivers the attachment** · brief rest ·
> final escalation · boss

*(This said thirteen and dropped the introduction until 26/08/2026. The count matters: it is the list
the waves get rebuilt from, and `08-decisions-and-open-items.md` and `08-background.md` both say
fourteen.)*

Those are waves. Progression, a deliberate rest before the climax, and a reward tied to a specific
encounter. **The structure was designed and then flattened away in translation to JSON.** The player's
proposal — group spawns into waves as the unit of level design, reusable across a level and between
levels — is recovering it, not inventing it.

**Open, and each of these changes what a wave is:**

- **What ends a wave.** A fixed duration, or "the wave is cleared"? Clearing is the better design —
  pacing follows the player rather than the clock — but then level length depends on how the player
  performs, and "the boss arrives at minute 3" stops meaning anything exact. It does **not** break
  determinism: the core reads world state, not the clock, so a cleared-based trigger stays
  reproducible.
- **How a wave is placed.** Absolute time, or relative to the previous wave ending? Reuse pushes hard
  towards relative.
- **Whether a wave takes parameters.** The same wave harder, mirrored, or entering from another side
  is the difference between reuse and copy-paste — and between a simple format and a small language.
  Invariant 6 says no abstraction without a real case.
- **Where waves live.** Formations already exist as a grouping below this one; waves sit above them
  and the two should not blur.

### Movement as a described thing

An enemy's behaviour should vary by where it appears in the level. The player's example: a fast enemy
enters from one direction with one movement early, from another direction with a different movement at
the midpoint, and does something else again at the end.

That needs movement to be describable — shapes like a U-shaped attack run, a straight 30° diagonal, or
a curve following something like an inverted logarithmic function. Today there are four trajectories
in `assets/data/`.

### A document per level

For each enemy, projectile and appearance: its stats and what it actually does, so that changing
something means reading that document rather than reading the code. In the player's words: so we do
not forget, and do not have to look at the code every time.

**This is now load-bearing**, because it is what an agent reads to build later levels (see the end of
this document). It is not a convenience any more.

**The player's intent, stated on 25/08:** the level's design lives in one place — a JSON or a
document — so it can be seen and changed easily. The exact form is still to be worked out, but "one
place" is the part that matters, and it is what the paragraph below is about.

**And it inherits this project's worst failure mode.** Documents here drift from the code — three
times with art, twice in phase 09 with status files. A document that describes the level *and* a JSON
that defines it are two copies of one truth, and one of them will rot. The options are not equal:
generating the JSON from the document, or the document from the JSON, cannot drift; maintaining both
by hand will. **This must be decided before anything is built.**

### Balance, the boss, and level length

- **Stats need a real pass.** Enemy, ship, projectile and drop values are still largely placeholder —
  a heavy carrier dies in about 1.2 s against the 32 s its stretch reserves. The player's verdict
  after playing the web build is that the game is **too easy**. This is a redesign of the numbers.
- **The boss changes.** `docs/STATUS.md` records the player's diagnosis, which is better than the fix
  that was tried: the spread always points outward and the sweep inward, so a player parked in the
  centre is never threatened. It is a positioning problem solved once, not a dodge. Suggested: five
  rays aimed at the player rather than at fixed outward angles — weighed against keeping the tell
  honest, which is what makes the fight fair.
- **Level 1 gets shorter.** The boss currently enters at **302 s (5.03 minutes)**. Five minutes is too
  long; the figure discussed was around 2.5–3 minutes. **The number is deliberately not fixed here** —
  it is decided in this phase, once waves exist and pacing can be felt rather than arithmetic'd.

**Decided, and it stays decided: balance is tuned by playing, not by arithmetic.**

### Tests that assert rules, not only reproducibility

Raised by the player on 25/08: more tests, especially integration tests — *the ship destroys the
boss's module 1* — to save on manual verification and keep the code maintainable.
[#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44).

The structure already exists: `core/src/test/.../application/` holds cross-system tests, 289 tests in
35 files. Some already assert behaviour, and several replays carry an explicit anti-vacuity companion.
**But the bulk asserts that a run reproduces itself, not that a rule holds.** `BossReplayTest` — the
player's own example — has two tests, both determinism, and asserts nothing about the boss's modules:
break the module rule and it stays green, because it breaks identically both times.

The reason this belongs here rather than in a tidy-up later: **this project pays for the gap in manual
verification, every phase.** Phase 09 had a reviewer reproduce gzip sizes by hand, unpack a Pages
artifact and count test XML files. #23 — a designed drop delivered once per formation slot instead of
once — is a live rules bug that no test caught, and it is precisely the kind of thing waves will
depend on.

It also makes the rest of this group safe. **Rebalancing without rule-asserting tests is changing
numbers with no net underneath**, and the balance pass is a redesign of the numbers, not a tweak.

Determinism replays stay — they guard invariant 2, which fails silently. This adds beside them.

`game` still has no tests at all ([#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19)).

### The four web defects

#40, #41, #42 and #43 are fixed in this phase.

### The order inside this group is not arbitrary

This group becomes several numbered phases, as every group here does. What must survive the
subdivision is the sequence:

**Waves come first.** Balance and movement are expressed *inside* waves. Rebalancing 92 flat rows and
then regrouping them into waves is doing the work twice, and redesigning the boss before the level's
new length is known means tuning a fight against a pacing that no longer exists.

**Rule-asserting tests come early too**, because they are what makes everything after them safe to
change. Rebalancing and restructuring waves without them is changing behaviour with nothing to catch a
regression — and the existing replays will not catch it, since a broken rule breaks identically on
both runs.

The per-level document should be settled early too, since it is the format everything after it is
written in.

Also open from before: the intensity-curve tooling, carried as non-blocking since the level's length
and climax were decided.

---

## Phase 12 — Levels 2 and 3, and the story of stage 1

Build levels 2 and 3 of "Invasion of Earth" on the base phase 11 produces, and plan the stage's story
across its five levels.

The story planned here is a working outline: it covers five levels while only three exist. Phase 13
completes it.

This is also the **first real test of whether the code reordering worked**, and it is worth treating as
an acceptance criterion rather than a hope.

The waves, the movement system and the per-level document exist to make building levels easy. While
only level 1 exists there is no way to know whether they did: level 1 was built with the old system
and is already finished. The first honest measurement is someone building level 2 with the new one.
If that costs as much as level 1 did, the base did not deliver what it was built for.

Finding that out at level 2 means correcting with one level built on top. Finding it out at level 5
means correcting with four.

---

## Phase 13 — Levels 4 and 5, and stage 1 finished

- **Levels 4 and 5**, with level 5 closing the stage by destroying the mothership, per
  `04-campaign-and-levels.md`.
- **The stage's story, complete** rather than outlined.
- **Animations.**
- **Backgrounds per level.**
- **Progression**, and whatever else the game needs by then to be a whole rather than a sequence of
  levels.

After this, stage 1 is a finished game with five levels, and stages 2–5 are the same shape of work on
a system that has been proven.

---

## How later levels get built

The player's intent, and the reason phases 10 and 11 come first:

> the later stages get generated by one or more agents, after a technical and informative conversation
> with an agent before building the implementation.

So the target is **not** a procedural generator and **not** just "easy to hand-author". It is that
`level-designer` — possibly with others — can produce a level by reading the stage's design and the
per-level documents, preceded by a design conversation rather than a prompt.

Three things follow, and they are constraints on phase 11 rather than nice-to-haves:

1. **The per-level document is the interface.** It is what the agent reads. It must be complete and
   readable enough to design from, which is a higher bar than being a reference for a human who
   already knows the game.
2. **Waves and movements must be nameable and composable.** An agent reusing "the opening of level 1,
   harder" needs that to be a thing with a name, not a range of rows.
3. **The drift problem becomes critical.** An agent generating a level from a stale document produces
   a level that is wrong in a way nobody notices — the same failure as art delivered to `docs/design/`,
   with more surface area.

None of that argues for building a generator now. It argues for deciding the format with this use in
view, because retrofitting it later is the expensive path.

## What this document is not

It is not a schedule, and it is not a plan. Each phase needs its own `plan.md` with acceptance
criteria before work starts, written the way phases 01–09 were. Several things above are marked open
on purpose: deciding them here would be exactly the kind of guess
`docs/planning/08-decisions-and-open-items.md` exists to prevent.
