# Master plan — overview

Written on 19/08/2026, once planning closed and the platform was validated.

This is the summary. Each phase has its own folder with a `plan.md` (what to do) and a `status.md` (where it stands).

## Targets

| Milestone | Date | What it means |
|---|---|---|
| **MVP** | 26/08/2026 | Level 1 playable end to end in the browser, with near-final art for that level |
| **Finish** | 09/09/2026 | Polish, game feel, final audio, everything the portfolio is judged on |

One week for the MVP is tight. It only works because **art and code run in separate lanes** — producing sprites never requires reading code, so it does not queue behind it.

## The two lanes

```
        D1        D2        D3        D4        D5        D6        D7
CODE   [01]────▶[02]────▶[03]────▶[04]────▶[05]────▶[07]────▶[09]
                                                └────▶[06 integration]
ART    [visual direction]──▶[sprites]──▶[sprites]──▶[HUD]──▶[08 audio]
```

**Code lane.** Foundations, mechanics, first playable, content, systems, boss, release.

**Art lane.** Visual direction first — palette, sprite sizes, legibility rules — then sprite production. It starts on day one and never waits for the code.

### Synchronisation points

Only three, and they are the schedule's real risk:

1. **End of day 1** — the visual direction must fix sprite sizes and the palette. The art lane cannot start without it and the code lane needs the sizes for hitboxes.
2. **Phase 04** — content ids must be agreed, so sprites and archetypes line up by name.
3. **Phase 06** — the art produced so far gets integrated. If the art lane is late, this is where it hurts.

## Phases

| # | Phase | Lane | Owner | Depends on |
|---|---|---|---|---|
| 01 | [Foundations](01-foundations/plan.md) | code | `core-domain` | — |
| 02 | [Core mechanics](02-core-mechanics/plan.md) | code | `core-domain` | 01 |
| 03 | [First playable](03-first-playable/plan.md) | code | `game-presentation` | 02 |
| 04 | [Content pipeline](04-content-pipeline/plan.md) | code | `core-domain` | 02 |
| 05 | [Game systems](05-game-systems/plan.md) | code | `core-domain` | 04 |
| 06 | [Presentation](06-presentation/plan.md) | art + code | `visual-designer`, `game-presentation` | 03 |
| 07 | [Boss](07-boss/plan.md) | code | `core-domain` | 05 |
| 08 | [Audio and polish](08-audio-and-polish/plan.md) | art + code | `game-presentation` | 06 |
| 09 | [Web, CI and release](09-web-ci-release/plan.md) | code | `game-presentation` | 07 |

**The MVP shipped on 25/08/2026.** What comes after it is grouped in
[the post-MVP roadmap](post-mvp-roadmap.md): four groups of work, each of which becomes several
numbered phases. The first two groups are planned:

| # | Phase | Lane | Owner | Depends on |
|---|---|---|---|---|
| 10a | [Honest documentation](10a-honest-documentation/plan.md) | process | coordinator | 09 |
| 10b | [Agents and the way sessions are run](10b-agents-and-sessions/plan.md) | process | coordinator | 10a |
| 10c | [Architecture review](10c-architecture-review/plan.md) | process | coordinator | 10a, 10b |
| 11a | [Tests that assert rules](11a-rule-asserting-tests/plan.md) | code | `test-engineer` | 10c |
| 11b | [The wave system](11b-wave-system/plan.md) | code + content | `core-domain`, `level-designer` | 11a |
| 11c | [Movement as a described thing](11c-movement-shapes/plan.md) | code + content | `core-domain`, `level-designer` | 11a, 11b |
| 11d | [The per-level document](11d-per-level-document/plan.md) | process + code | coordinator | 11b, 11c |
| 11e | [Level 1 redesigned, balance and the boss](11e-level-one-redesigned/plan.md) | code + content | `level-designer` | 11a–11d |
| 11f | [The four web defects](11f-web-defects/plan.md) | presentation | `game-presentation` | — |

None of the 10 group changes production code: it decides, and the 11 group executes.

**The 11 group runs in two lanes**, the same way the MVP ran art beside code. 11a through 11e are one
sequence in `core/` and `assets/data/`, and **11a is not negotiable as the first of them**: everything
after it is a behaviour change under a suite that mostly proves a run reproduces itself. 11f touches
only `game/`, `desktop/` and `web/`, depends on nothing, and runs beside them from day one.

Phases 12 and 13 stay as the roadmap describes them; they are not planned yet.

Longer-range directions — progression, modes, more ships, the hangar — are sketched in
[beyond the MVP](beyond-mvp.md), which is a sketch rather than a plan and is not numbered as a phase.

## How work flows

The full cycle is in [how to run a phase](how-to-run-a-phase.md), and [writing prompts for agents](agent-prompts.md) covers launching one by hand. In short:

**One issue per task.** Each phase's `plan.md` lists its tasks; each becomes a GitHub issue in the `little-spaceship` repository.

**One branch per issue**, named `type/description`, merged through a pull request that closes it.

**`reviewer` accepts or rejects.** No phase is done because it looks done: `reviewer` audits it against the acceptance criteria in its `plan.md` and against the invariants in `CLAUDE.md`. A rejection is normal and comes back with what failed.

**Parallel sessions use worktrees.** The art lane and the code lane run at the same time, so each gets its own worktree and its own branch.

## What gets cut first, if the week slips

Decided in advance, so it is not improvised on day six. In order:

1. **Enemy archetype variety** — from six down to four. The level still teaches and combines.
2. **Boss phases** — a single-phase boss instead of a multi-phase one.
3. **Background parallax detail** — fewer layers, less ambient animation.
4. **The attachment** — it is the most isolated system, so it can be dropped without touching anything else.

What is **not** cut, because without it there is no MVP: the complete flow from menu to victory, the defensive priority chain, integer-scaled pixel art, the web build, and legibility of enemy bullets.

## Acceptance for the MVP as a whole

- A player opens a link and finishes level 1 without dev tools.
- The level can be won and lost, and both endings work.
- Pause, options and retry work.
- The boss reads as a climax, with its own music and HUD.
- Power-ups, score and the attachment are communicated on screen.
- Art is the level's own, not placeholders.
- The build is published and reproducible.
