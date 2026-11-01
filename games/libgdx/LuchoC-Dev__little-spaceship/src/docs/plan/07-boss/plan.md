# Phase 07 — Boss

**Lane:** code · **Owner:** `core-domain` · **Depends on:** 05 · **Target:** day 6

## Before you start

**Read, in this order:**

1. `docs/planning/04-campaign-and-levels.md` — the level 1 sequence and where the boss sits.
2. `docs/planning/02-mvp-functional-spec.md` — victory and defeat conditions, and the boss HUD.

**Decide before implementing:** the boss was deliberately left undefined during planning, and so was the strong encounter that hands over the attachment. Both need a decision at the start of this phase, not while coding.

**Do not re-decide:** victory requires surviving with at least one life, the boss health bar shows only during the fight, and music changes on entry.

## Goal

The level's climax, and the only fight that has to feel different from everything before it.

## Preconditions

Phase 05 accepted. Boss sprite delivered by the art lane.

## Open design decision

The boss was deliberately left undefined during planning: "a simple boss, since it is the first level". It has to be decided at the start of this phase, not improvised while implementing. What must be settled:

- one phase or two;
- attack patterns, and whether it moves or holds position;
- what teaches the player to read it — a tell before each attack;
- whether it has destructible parts.

The recommendation, given the schedule: **one phase, two alternating patterns, a clear tell**. A simple, readable boss beats an ambitious one that ships broken.

## Tasks

1. **Boss entity** with its own health, and a health bar shown only during the fight.
2. **Pattern state machine.** Fixed order, deterministic, driven by data like every other pattern.
3. **Encounter flow.** Entrance, fight, defeat, victory transition.
4. **Music change** on entry, which is what the spec asks the boss to feel like.
5. **The strong encounter** before the rest, which is what hands over the attachment. Also undefined so far, and needed for phase 05's guaranteed drops.
6. **Victory and defeat screens** with their options.

## Acceptance criteria

- The boss can be defeated and can kill the player, and both paths lead to the right screen.
- Its health bar appears only during the fight.
- Music changes on entry and returns correctly if the player dies.
- The fight is deterministic: same seed and inputs, same outcome.
- A replay covers a full victory and a full defeat.
- Victory requires surviving with at least one life, as decided.

## Risks

**An undefined boss invites improvisation on the last day.** Decide its design before writing it.

**It is the least reusable content in the level**, so it is also the least valuable to over-build. If the week slips, this is the second thing cut down.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
