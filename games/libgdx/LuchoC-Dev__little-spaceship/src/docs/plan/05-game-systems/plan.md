# Phase 05 — Game systems

**Lane:** code · **Owner:** `core-domain` · **Depends on:** 04 · **Target:** day 5

## Before you start

**Read, in this order:**

1. `docs/planning/03-game-systems.md` — power-ups, attachments and economy.
2. `docs/planning/02-mvp-functional-spec.md` — the MVP power-up and attachment lists.
3. `docs/planning/10-mvp-initial-values.md` — caps, scoring table and guaranteed drops.
4. `docs/planning/12-architecture.md`'s component table and JSON schema section — it already names
   `Health` (enemies and the boss) and shows it in the tank example (`"health": {"points": 40}`).
   This phase is the one that has to build it: phase 04 read the same document and modelled
   fragility as `Collider.fragile` instead, and an earlier draft of this plan did not list
   `12-architecture.md` among its required reading at all, so the component fell through the gap
   between the two phases rather than being deferred on purpose. Do not repeat that miss for
   `Weapon`, `Lifetime` or any other component this document already names.

**Do not re-decide:** one attachment slot, the attachment absorbing one hit and being destroyed, picking up at maximum granting points, and no combos or multipliers in the MVP.

**Design detail that matters:** attachment durability is data per attachment, not a constant. The decision exists so a future protective attachment can be tougher without a code change.

## Goal

The systems that turn a level into a game: weapons and their upgrades, power-ups, the attachment, the bomb and scoring.

## Preconditions

Phase 04 accepted, so these systems can be configured from data.

## Tasks

1. **`WeaponSystem`.** Rate of fire, patterns, projectile creation. The player's main weapon is sustained automatic fire.
2. **Weapon upgrade.** Four levels — base plus three. The level is readable from the shape and count of the shots, with no numeric indicator.
3. **Power-ups.** Weapon upgrade, shield, extra life, bomb recharge, temporary invulnerability. Each with its own consumption rule; they are not cleared by losing a life.
4. **Picking up at maximum.** Grants points instead of being wasted, so no drop is ever dead.
5. **Attachment.** One active slot. It absorbs one hit and is destroyed, which is what saves the life. Durability is **per-attachment data**, not a constant, so a future protective attachment can be tougher.
6. **`BombSystem`.** Clears most on-screen threats and deals heavy damage to resistant enemies. Two initial, cap of three.
7. **`ScoreSystem`.** Points per enemy destroyed, plus an end-of-level bonus for remaining lives and bombs. No combos or multipliers in the MVP.
8. **Guaranteed drops.** Weapon upgrade in the first third, shield before the strong encounter, the attachment from the strong encounter itself, bomb recharge before the boss.

## Acceptance criteria

- Every power-up is covered by a test for its own consumption rule.
- Picking up a maxed power-up increases the score.
- The attachment absorbs exactly one hit, disappears, and no life is lost.
- Attachment durability can be raised from data with no code change.
- The bomb clears projectiles and damages enemies in the same tick, deterministically.
- Score matches the table in `10-mvp-initial-values.md`.
- A full-level replay produces the same final score twice.

## Risks

**Power-up persistence across a death is the rule that was corrected mid-planning.** The first draft said everything was lost; the confirmed rule is that persistent power-ups survive and each is consumed by its own condition. Implementing the old version is an easy mistake — `08-decisions-and-open-items.md` records the correction.

**The bomb touches everything.** It interacts with collision, damage, scoring and audio in the same tick. Good candidate for a replay test rather than only unit tests.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
